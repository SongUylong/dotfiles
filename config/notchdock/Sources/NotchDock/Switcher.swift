import Carbon.HIToolbox
import ScreenCaptureKit
import SwiftUI

/// Cmd+Tab window switcher: live previews of every window on every space, most recently
/// used first. Keep holding Cmd and press Tab (Shift+Tab goes back), release Cmd to jump
/// there. Esc cancels; clicking a card jumps too. Windows and spaces come from yabai.

struct SwitchWindow: Identifiable, Equatable {
    let id: Int
    let app: String
    let title: String
    let space: Int
    let pid: Int32
    let minimized: Bool
    static func == (a: Self, b: Self) -> Bool { a.id == b.id }
}

final class SwitcherModel: ObservableObject {
    @Published var windows: [SwitchWindow] = []
    @Published var selected = 0
    @Published var previews: [Int: NSImage] = [:]
    @Published var shown = false
    var icons: [Int32: NSImage] = [:]
}

final class SwitcherController {
    let model = SwitcherModel()
    private let panel: FloatingPanel
    private var hotKeys: [EventHotKeyRef?] = []
    private var mru: [Int] = []           // window ids, most recent first
    private var poll: Timer?
    private var keyMonitor: Any?
    private var previewCache: [Int: NSImage] = [:]

    init() {
        panel = FloatingPanel(rect: NSRect(x: 0, y: 0, width: 1000, height: 420), level: .modalPanel)
        panel.contentView = FirstClickHostingView(rootView: SwitcherView(model: model) { [weak self] i in self?.commit(i) })
        registerHotKeys()
        // Track the most recently used windows (yabai doesn't keep an order).
        let nc = NSWorkspace.shared.notificationCenter
        for n in [NSWorkspace.didActivateApplicationNotification, NSWorkspace.activeSpaceDidChangeNotification] {
            nc.addObserver(forName: n, object: nil, queue: .main) { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self?.noteFocused() }
            }
        }
        noteFocused()
    }

    private func noteFocused() {
        bg {
            let out = sh("yabai -m query --windows --window 2>/dev/null")
            guard let d = out.data(using: .utf8),
                  let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                  let id = j["id"] as? Int else { return }
            main { self.mru.removeAll { $0 == id }; self.mru.insert(id, at: 0); if self.mru.count > 200 { self.mru.removeLast() } }
        }
    }

    // MARK: hotkeys

    /// macOS 15 ignores RegisterEventHotKey for Option-only shortcuts, so Option+Tab is caught
    /// with a keyboard event tap (uses NotchDock's Accessibility permission). The tap swallows
    /// Option+Tab, and Esc/arrows while the switcher is open.
    private var tap: CFMachPort?
    private var signalSources: [DispatchSourceSignal] = []
    private func registerHotKeys() {
        AppleSwitcher.set(enabled: false)
        // Give Apple's switcher back when NotchDock quits or is stopped (launchctl sends SIGTERM).
        for sig in [SIGTERM, SIGINT, SIGHUP] {
            signal(sig, SIG_IGN)
            let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            src.setEventHandler { AppleSwitcher.set(enabled: true); exit(0) }
            src.resume()
            signalSources.append(src)
        }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            AppleSwitcher.set(enabled: true)
        }
        installTap()
    }

    private func installTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let me = Unmanaged.passUnretained(self).toOpaque()
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                eventsOfInterest: mask, callback: { _, type, event, ctx in
            guard let ctx else { return Unmanaged.passUnretained(event) }
            let c = Unmanaged<SwitcherController>.fromOpaque(ctx).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let t = c.tap { CGEvent.tapEnable(tap: t, enable: true) }
                return Unmanaged.passUnretained(event)
            }
            let code = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let f = event.flags
            let cmdOnly = f.contains(.maskCommand) && !f.contains(.maskAlternate) && !f.contains(.maskControl)
            if code == kVK_Tab && cmdOnly {
                let back = f.contains(.maskShift)
                DispatchQueue.main.async { c.step(back ? -1 : 1) }
                return nil
            }
            if c.isOpen {
                switch code {
                case kVK_Escape: DispatchQueue.main.async { c.close() }; return nil
                case kVK_LeftArrow: DispatchQueue.main.async { c.step(-1) }; return nil
                case kVK_RightArrow: DispatchQueue.main.async { c.step(1) }; return nil
                case kVK_Return: DispatchQueue.main.async { c.commit(c.model.selected) }; return nil
                default: break
                }
            }
            return Unmanaged.passUnretained(event)
        }, userInfo: me)
        guard let tap else {
            wlog("switcher: event tap failed (Accessibility not granted?) — retrying in 10 s")
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in self?.installTap() }
            return
        }
        let src = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private(set) var isOpen = false

    // MARK: flow

    func step(_ d: Int) {
        if !panel.isVisible { if !opening { open(back: d < 0) }; return }
        guard !model.windows.isEmpty else { return }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.9)) {
            model.selected = (model.selected + d + model.windows.count) % model.windows.count
        }
    }

    private var opening = false
    private func open(back: Bool) {
        guard !opening else { return }
        opening = true
        bg {
            let list = self.loadWindows()
            main { self.opening = false; self.show(list, back: back) }
        }
    }

    private func show(_ list: [SwitchWindow], back: Bool) {
        guard !list.isEmpty, NSEvent.modifierFlags.contains(.command) else { return }
        model.windows = list
        model.previews = previewCache.filter { id, _ in list.contains { $0.id == id } }
        model.selected = list.count > 1 ? (back ? list.count - 1 : 1) : 0
        for w in list where model.icons[w.pid] == nil {
            model.icons[w.pid] = NSRunningApplication(processIdentifier: w.pid)?.icon
        }
        layoutPanel()
        model.shown = false
        panel.orderFrontRegardless()
        DispatchQueue.main.async { withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) { self.model.shown = true } }
        capturePreviews(list)

        // Release Cmd → go. Polling the hardware modifier state is the most reliable way to
        // catch the release while another app is frontmost.
        poll?.invalidate()
        poll = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            if !NSEvent.modifierFlags.contains(.command) { self.commit(self.model.selected) }
        }
        RunLoop.main.add(poll!, forMode: .common)
        isOpen = true
    }

    private func loadWindows() -> [SwitchWindow] {
        var out = ""
        for _ in 0..<4 {   // yabai can briefly return nothing while focus is changing
            out = sh("yabai -m query --windows 2>/dev/null")
            if !out.isEmpty { break }
            usleep(60_000)
        }
        guard let d = out.data(using: .utf8), let arr = try? JSONSerialization.jsonObject(with: d) as? [[String: Any]] else {
            wlog("switcher: yabai output \(out.count) chars, not parsed: \(out.prefix(120))"); return []
        }
        let skip: Set<String> = ["NotchDock", "borders", "PortKiller"]
        var list = arr.compactMap { w -> SwitchWindow? in
            guard let id = w["id"] as? Int, let app = w["app"] as? String, !skip.contains(app),
                  (w["role"] as? String) == "AXWindow", (w["subrole"] as? String) == "AXStandardWindow",
                  (w["is-hidden"] as? Bool) != true else { return nil }
            return SwitchWindow(id: id, app: app, title: (w["title"] as? String) ?? "", space: (w["space"] as? Int) ?? 0,
                                pid: Int32((w["pid"] as? Int) ?? 0), minimized: (w["is-minimized"] as? Bool) ?? false)
        }
        if let f = arr.first(where: { ($0["has-focus"] as? Bool) == true })?["id"] as? Int {
            mru.removeAll { $0 == f }; mru.insert(f, at: 0)
        }
        let rank = Dictionary(uniqueKeysWithValues: mru.enumerated().map { ($1, $0) })
        list.sort { (rank[$0.id] ?? Int.max, $0.space, $0.app) < (rank[$1.id] ?? Int.max, $1.space, $1.app) }
        return list
    }

    private func layoutPanel() {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main!
        let n = model.windows.count
        let cols = min(n, 5), rows = min(Int(ceil(Double(n) / 5)), 3)
        let w = CGFloat(cols) * SwitcherView.cardW + CGFloat(cols - 1) * 14 + 40
        let h = CGFloat(rows) * SwitcherView.cardH + CGFloat(rows - 1) * 14 + 40 + 30
        let f = screen.frame
        panel.setFrame(NSRect(x: f.midX - w / 2 - 20, y: f.midY - h / 2 - 20, width: w + 40, height: h + 40), display: true)
    }

    func commit(_ i: Int) {
        guard panel.isVisible else { return }
        let target = model.windows.indices.contains(i) ? model.windows[i] : nil
        close()
        guard let w = target else { return }
        mru.removeAll { $0 == w.id }; mru.insert(w.id, at: 0)
        bg {
            if w.minimized { sh("yabai -m window \(w.id) --deminimize") }
            let r = sh("yabai -m window --focus \(w.id) 2>&1")
            if !r.isEmpty {   // fallback: at least bring the app forward
                main { NSRunningApplication(processIdentifier: w.pid)?.activate() }
            }
        }
    }

    func close() {
        isOpen = false
        poll?.invalidate(); poll = nil
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        withAnimation(.easeIn(duration: 0.1)) { model.shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) { if !self.model.shown { self.panel.orderOut(nil) } }
    }

    // MARK: previews (ScreenCaptureKit; needs Screen Recording permission once)

    private func capturePreviews(_ list: [SwitchWindow]) {
        guard #available(macOS 14.0, *) else { return }
        Task {
            guard let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false) else { return }
            let byID = Dictionary(content.windows.map { (Int($0.windowID), $0) }, uniquingKeysWith: { a, _ in a })
            // Selected and next ones first so what you're looking at fills in fastest.
            let order = list.indices.sorted { abs($0 - model.selected) < abs($1 - model.selected) }
            for i in order {
                let w = list[i]
                guard let scw = byID[w.id], scw.frame.width > 1 else { continue }
                let filter = SCContentFilter(desktopIndependentWindow: scw)
                let cfg = SCStreamConfiguration()
                let scale = min(1, 520 / max(scw.frame.width, 1))
                cfg.width = Int(scw.frame.width * scale * 2); cfg.height = Int(scw.frame.height * scale * 2)
                cfg.showsCursor = false
                guard let cg = try? await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg) else { continue }
                let img = NSImage(cgImage: cg, size: NSSize(width: cg.width / 2, height: cg.height / 2))
                await MainActor.run {
                    self.previewCache[w.id] = img
                    if self.panel.isVisible { self.model.previews[w.id] = img }
                }
            }
        }
    }
}

// MARK: view

struct SwitcherView: View {
    @ObservedObject var model: SwitcherModel
    var pick: (Int) -> Void
    static let cardW: CGFloat = 200, cardH: CGFloat = 150

    var body: some View {
        let cols = Array(repeating: GridItem(.fixed(Self.cardW), spacing: 14), count: max(1, min(model.windows.count, 5)))
        VStack(spacing: 10) {
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(Array(model.windows.enumerated()), id: \.element.id) { i, w in
                    card(w, selected: i == model.selected)
                        .onTapGesture { pick(i) }
                        .onHover { if $0 { model.selected = i } }
                }
            }
            if model.windows.indices.contains(model.selected) {
                let w = model.windows[model.selected]
                Text(w.title.isEmpty ? w.app : "\(w.app)  ·  \(w.title)")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Mocha.text).lineLimit(1)
                    .frame(maxWidth: 700).frame(height: 20)
            }
        }
        .padding(20)
        .background(BarBackground(radius: 22))
        .scaleEffect(model.shown ? 1 : 0.96)
        .opacity(model.shown ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.colorScheme, .dark)
    }

    private func card(_ w: SwitchWindow, selected: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Mocha.surface0.opacity(0.6))
                if let p = model.previews[w.id] {
                    Image(nsImage: p).resizable().aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(6)
                        .transition(.opacity)
                } else if let icon = model.icons[w.pid] {
                    Image(nsImage: icon).resizable().frame(width: 54, height: 54).opacity(0.85)
                }
                // app icon + space badge
                VStack {
                    HStack {
                        Spacer()
                        Text("\(w.space)").font(.system(size: 10, weight: .heavy)).foregroundStyle(Mocha.base)
                            .frame(width: 18, height: 18).background(Circle().fill(selected ? Mocha.mauve : Mocha.overlay0))
                    }
                    Spacer()
                    HStack {
                        if let icon = model.icons[w.pid] { Image(nsImage: icon).resizable().frame(width: 30, height: 30).shadow(radius: 3) }
                        Spacer()
                        if w.minimized { Image(systemName: "minus.circle.fill").foregroundStyle(Mocha.yellow) }
                    }
                }
                .padding(6)
            }
            .frame(width: Self.cardW, height: Self.cardH - 24)
            Text(w.app).font(.system(size: 11.5, weight: selected ? .bold : .medium))
                .foregroundStyle(selected ? Mocha.text : Mocha.subtext).lineLimit(1)
                .frame(height: 16)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(selected ? Mocha.mauve.opacity(0.16) : .clear)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? Mocha.mauve : .clear, lineWidth: 2))
        )
        .scaleEffect(selected ? 1.03 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.85), value: selected)
        .contentShape(Rectangle())
    }
}

/// Apple's own Cmd+Tab app switcher is a WindowServer "symbolic hotkey" that fires before any
/// event tap, so it's turned off while NotchDock runs and turned back on when it quits
/// (the same private call AltTab-style apps use).
enum AppleSwitcher {
    private typealias SetFn = @convention(c) (Int32, Bool) -> Int32
    private static let fn: SetFn? = {
        guard let h = dlopen("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices", RTLD_NOW),
              let p = dlsym(h, "CGSSetSymbolicHotKeyEnabled") else { return nil }
        return unsafeBitCast(p, to: SetFn.self)
    }()
    static func set(enabled: Bool) {
        for id: Int32 in [1, 2] { _ = fn?(id, enabled) }   // 1: Cmd+Tab, 2: Cmd+Shift+Tab
    }
}
