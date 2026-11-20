import Carbon
import AppKit
import Combine
import SwiftUI

enum Dropdown: String { case controls, stats, ai, calendar }

final class TopBarState: ObservableObject {
    @Published var open: Dropdown?
    let calendar = CalendarModel()
}

// MARK: building blocks

struct Pill<Content: View>: View {
    var active = false
    var border: Color? = nil
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: 6) { content }
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(active ? Mocha.surface1 : Mocha.surface0))
            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(border ?? .clear, lineWidth: 1))
            .contentShape(Rectangle())
    }
}

struct AppIcon: View {
    let name: String
    var size: CGFloat = 16
    var body: some View {
        Image(nsImage: Self.icon(for: name)).resizable().interpolation(.high).frame(width: size, height: size)
    }
    private static var cache: [String: NSImage] = [:]
    static func icon(for name: String) -> NSImage {
        if let i = cache[name] { return i }
        let ws = NSWorkspace.shared
        let img: NSImage
        if let app = ws.runningApplications.first(where: { $0.localizedName == name }), let i = app.icon { img = i }
        else if let p = ws.fullPath(forApplication: name) { img = ws.icon(forFile: p) }
        else { img = NSImage(systemSymbolName: "app", accessibilityDescription: nil)! }
        cache[name] = img
        return img
    }
    static func bundleIcon(_ id: String) -> NSImage? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: id).map { NSWorkspace.shared.icon(forFile: $0.path) }
    }
}

struct Meter: View {
    let pct: Double
    var color: Color { pct >= 85 ? Mocha.red : pct >= 60 ? Mocha.yellow : Mocha.green }
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Mocha.surface1)
                Capsule().fill(color).frame(width: max(4, g.size.width * min(pct, 100) / 100))
            }
        }.frame(height: 6)
    }
}

struct Row<Trailing: View>: View {
    let symbol: String
    let title: String
    let color: Color
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).foregroundStyle(color).frame(width: 18)
            Text(title).foregroundStyle(Mocha.subtext).frame(width: 84, alignment: .leading)
            trailing.frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12.5, weight: .semibold))
        .padding(.horizontal, 14).frame(height: 28)
        .contentShape(Rectangle())
    }
}

/// A slider drawn in the bar's own style (not the system control).
struct BarSlider: View {
    @Binding var value: Double
    var color: Color
    var onCommit: (Double) -> Void
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Mocha.surface1).frame(height: 6)
                Capsule().fill(color).frame(width: g.size.width * CGFloat(value) / 100, height: 6)
                Circle().fill(Mocha.text).frame(width: 12, height: 12)
                    .offset(x: max(0, g.size.width * CGFloat(value) / 100 - 6))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value = Double(min(100, max(0, $0.location.x / g.size.width * 100))) }
                .onEnded { _ in onCommit(value) })
        }.frame(height: 16)
    }
}

// MARK: the bar

struct TopBarView: View {
    @ObservedObject var data: BarData
    @ObservedObject var menuBar: MenuBarModel
    @ObservedObject var state: TopBarState
    @State private var hoveringPotato = false
    let notchGap: CGFloat   // width reserved for the hardware notch (0 if none)
    var dropdownOnly = false

    var body: some View {
        if dropdownOnly {
            // Lives in its own window under the bar, top-aligned so it never moves the bar.
            VStack(spacing: 0) { dropdown; Spacer(minLength: 0) }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .foregroundStyle(Mocha.text)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()
        } else {
            barBody
        }
    }

    private var barBody: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                left
                Spacer(minLength: notchGap > 0 ? notchGap + 16 : 8)
                right
            }
            .padding(.horizontal, 6)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Mocha.base.opacity(0.82))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Mocha.surface1, lineWidth: 1))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .foregroundStyle(Mocha.text)
        .environment(\.colorScheme, .dark)
        .ignoresSafeArea()
    }

    private var left: some View {
        HStack(spacing: 6) {
            Pill {
                Image(systemName: "applelogo").foregroundStyle(Mocha.mauve)
                Text("Potato").foregroundStyle(Mocha.mauve)
            }
            .font(.system(size: 13, weight: .semibold))
            .onHover { h in
                hoveringPotato = h
                guard h else { return }
                // Short delay so just passing over Potato doesn't open the menu.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    guard hoveringPotato, !menuBar.menus.isEmpty else { return }
                    hoveringPotato = false
                    menuBar.refreshMenus()
                    menuBar.combinedMenu().popUp(positioning: nil, at: Self.potatoPoint(), in: nil)
                }
            }
            .onTapGesture {
                if menuBar.menus.isEmpty { menuBar.requestTrust() }
                else { menuBar.combinedMenu().popUp(positioning: nil, at: Self.potatoPoint(), in: nil) }
            }

            ForEach(data.spaces) { s in
                HStack(spacing: 6) {
                    Text("\(s.id)").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(s.focused ? Mocha.blue : Mocha.subtext)
                    let shown = s.focused ? Array(s.apps.prefix(6)) : Array(s.apps.prefix(1))
                    ForEach(shown, id: \.self) { AppIcon(name: $0, size: 17) }
                    if !s.focused, s.apps.count > 1 {
                        Text("+\(s.apps.count - 1)").font(.system(size: 10, weight: .bold)).foregroundStyle(Mocha.overlay0)
                    }
                }
                .padding(.horizontal, 12).frame(height: 30)
                .background(Capsule().fill(Mocha.surface0))
                .overlay(Capsule().strokeBorder(s.focused ? Mocha.blue : .clear, lineWidth: 1.5))
                .contentShape(Capsule())
                .onTapGesture { data.focusSpace(s.id) }
            }

            appMenus
        }
    }

    private var appMenus: some View {
        HStack(spacing: 6) {
            if !menuBar.trusted {
                Text("Allow Accessibility for menus").font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.peach)
                    .onTapGesture { menuBar.requestTrust() }.fixedSize()
            }
        }
        .padding(.leading, 6)
    }

    /// Where the Potato dropdown opens: under the Potato pill at the bar's left edge.
    static func potatoPoint() -> NSPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main!
        return NSPoint(x: screen.frame.minX + 16, y: screen.frame.maxY - 46)
    }

    /// Menus open just under the bar, left-aligned with the pointer.
    static func menuPoint() -> NSPoint {
        let m = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(m) } ?? NSScreen.main!
        return NSPoint(x: m.x - 12, y: screen.frame.maxY - 46)
    }

    /// Short label for the keyboard layout, like the system menu's icon (A, 拼, ក…).
    static func inputLabel(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("pinyin") { return "拼" }
        if n.contains("khmer") { return "ក" }
        if n == "abc" || n.hasPrefix("u.s") || n.hasPrefix("british") { return "A" }
        return String(name.prefix(2))
    }


    private var right: some View {
        HStack(spacing: 6) {
            if !menuBar.extras.isEmpty {
                Pill {
                    ForEach(menuBar.extras) { e in
                        Group {
                            if let icon = e.icon { Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit) }
                            else { Image(systemName: "app") }
                        }
                        .frame(width: 18, height: 18)
                        .help(e.title)
                        .contentShape(Rectangle())
                        .onTapGesture { menuBar.click(e) }
                        .contextMenu {
                            Button("Open Menu") { menuBar.click(e) }
                            Divider()
                            Button("Quit \(NSRunningApplication(processIdentifier: e.pid)?.localizedName ?? e.title)") {
                                NSRunningApplication(processIdentifier: e.pid)?.terminate()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { menuBar.refreshExtras() }
                            }
                        }
                    }
                }
            }
            Pill(active: state.open == .stats) {
                Image(systemName: "sparkles").foregroundStyle(Mocha.mauve)
                Image(systemName: "gauge.with.dots.needle.67percent").foregroundStyle(Mocha.green)
            }
            .help("AI and system usage")
            .onTapGesture {
                state.open = state.open == .stats ? nil : .stats
                if state.open == .stats { data.refreshAI(fetch: true); data.refreshSlowStats() }
            }
            Pill(active: state.open == .controls, border: data.caffeinated ? Mocha.peach : nil) {
                Image(systemName: volumeSymbol).foregroundStyle(data.muted ? Mocha.red : Mocha.text)
                Image(systemName: data.wifi.isEmpty ? "wifi.slash" : "wifi").foregroundStyle(data.wifi.isEmpty ? Mocha.red : Mocha.text)
                if data.caffeinated { Image(systemName: "cup.and.saucer.fill").foregroundStyle(Mocha.peach) }
                Text(Self.inputLabel(menuBar.inputSource.name)).font(.system(size: 12, weight: .bold))
            }
            .help("Sound, Wi-Fi, keep awake and keyboard")
            .onTapGesture {
                state.open = state.open == .controls ? nil : .controls
                if state.open == .controls { data.refreshControls() }
            }
            Pill(border: data.lowPower ? Mocha.yellow : nil) {
                Image(systemName: batterySymbol).foregroundStyle(data.lowPower ? Mocha.yellow : batteryColor)
                Text("\(data.batteryPct)%")
            }
            .help(data.lowPower ? "Low Power Mode on (click to turn off)" : "Click to turn on Low Power Mode")
            .onTapGesture { data.toggleLowPower() }
            Pill {
                Image(systemName: "clock").foregroundStyle(Mocha.peach)
                Text(data.now, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
            }
            .onTapGesture { state.open = state.open == .calendar ? nil : .calendar }
            Pill {
                Image(systemName: "bell.fill").foregroundStyle(Mocha.yellow)
            }
            .help(menuBar.trusted ? "Notification Center" : "Allow Accessibility to open Notification Center")
            .onTapGesture {
                state.open = nil
                if menuBar.trusted { menuBar.openNotificationCenter() } else { menuBar.requestTrust() }
            }
        }
        .font(.system(size: 13, weight: .semibold))
    }

    private func toggle(_ d: Dropdown, symbol: String, color: Color) -> some View {
        Pill(active: state.open == d) { Image(systemName: symbol).foregroundStyle(color) }
            .onTapGesture {
                state.open = state.open == d ? nil : d
                if state.open == .ai { data.refreshAI(fetch: true) }
                if state.open == .controls { data.refreshControls() }
                if state.open == .stats { data.refreshSlowStats() }
            }
    }

    // MARK: dropdown panels

    @ViewBuilder private var dropdown: some View {
        if let open = state.open {
            VStack(alignment: .leading, spacing: 2) {
                switch open {
                case .controls: controls
                case .stats: ai; Divider().overlay(Mocha.surface0).padding(.horizontal, 14).padding(.vertical, 4); stats
                case .ai: ai
                case .calendar: CalendarDropView(model: state.calendar)
                }
            }
            .padding(.vertical, 8)
            .frame(width: 340)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Mocha.base)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Mocha.surface1, lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 14, y: 6))
            .padding(.top, 2).padding(.trailing, 16).padding([.leading, .bottom], 24)   // room for the shadow
        }
    }

    @ViewBuilder private var controls: some View {
        controlsAudioNet
        Divider().overlay(Mocha.surface0).padding(.horizontal, 14).padding(.vertical, 4)
        Row(symbol: data.caffeinated ? "cup.and.saucer.fill" : "moon.zzz", title: "Keep awake",
            color: data.caffeinated ? Mocha.peach : Mocha.overlay0) {
            Text(data.caffeinated ? "On — never sleeps" : "Off — normal sleep")
                .foregroundStyle(data.caffeinated ? Mocha.peach : Mocha.subtext)
        }
        .onTapGesture { data.toggleCaffeinate() }
        Row(symbol: "keyboard", title: "Keyboard", color: Mocha.lavender) {
            Text(menuBar.inputSource.name).lineLimit(1)
        }
        .onTapGesture { InputSources.menu().popUp(positioning: nil, at: Self.menuPoint(), in: nil) }
        ForEach(InputSources.enabled()) { src in
            HStack {
                Text(Self.inputLabel(src.name)).font(.system(size: 12, weight: .bold)).frame(width: 18)
                Text(src.name).font(.system(size: 12))
                Spacer()
                if src.id == menuBar.inputSource.id { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Mocha.green) }
            }
            .foregroundStyle(src.id == menuBar.inputSource.id ? Mocha.text : Mocha.subtext)
            .padding(.leading, 42).padding(.trailing, 14).frame(height: 24)
            .contentShape(Rectangle())
            .onTapGesture { TISSelectInputSource(src.ref); menuBar.inputSource = InputSources.current() }
        }
    }

    @ViewBuilder private var controlsAudioNet: some View {
        let vol = Binding(get: { Double(data.volume) }, set: { data.volume = Int($0) })
        Row(symbol: volumeSymbol, title: "Volume", color: data.muted ? Mocha.red : Mocha.blue) {
            HStack {
                BarSlider(value: vol, color: Mocha.blue) { data.setVolume(Int($0)) }
                Text(data.muted ? "muted" : "\(data.volume)%").frame(width: 46, alignment: .trailing)
                    .foregroundStyle(data.muted ? Mocha.red : Mocha.text)
                    .onTapGesture { data.toggleMute() }
            }
        }
        Row(symbol: data.mic == 0 ? "mic.slash.fill" : "mic.fill", title: "Mic", color: data.mic == 0 ? Mocha.red : Mocha.green) {
            HStack { Meter(pct: Double(data.mic)); Text(data.mic == 0 ? "muted" : "\(data.mic)%").frame(width: 46, alignment: .trailing) }
        }
        .onTapGesture { data.toggleMic() }
        Row(symbol: data.wifi.isEmpty ? "wifi.slash" : "wifi", title: "Wi-Fi", color: data.wifi.isEmpty ? Mocha.red : Mocha.green) {
            Text(data.wifi.isEmpty ? "Off" : "\(data.wifi)  \(data.ip)").lineLimit(1)
        }
        .onTapGesture { open("x-apple.systempreferences:com.apple.preference.network?Wi-Fi") }
        Row(symbol: "bolt.horizontal.circle", title: "Bluetooth", color: Mocha.blue) {
            Text(data.btDevices.isEmpty ? "No devices" : "\(data.btDevices.count) connected").foregroundStyle(Mocha.subtext)
        }
        .onTapGesture { open("x-apple.systempreferences:com.apple.preferences.Bluetooth") }
        ForEach(data.btDevices, id: \.self) { d in
            Text(d).font(.system(size: 12)).foregroundStyle(Mocha.subtext).padding(.leading, 42).frame(height: 22)
        }
    }

    @ViewBuilder private var stats: some View {
        Row(symbol: "cpu", title: "CPU", color: Mocha.green) {
            HStack { Meter(pct: Double(data.cpu)); Text("\(data.cpu)%").frame(width: 46, alignment: .trailing) }
        }
        .onTapGesture { NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")) }
        Row(symbol: "memorychip", title: "Memory", color: Mocha.teal) {
            HStack { Meter(pct: Double(data.ram)); Text("\(data.ram)%").frame(width: 46, alignment: .trailing) }
        }
        Row(symbol: "thermometer.medium", title: "Temp", color: Mocha.peach) { Text(data.temp) }
        Row(symbol: "internaldrive", title: "Disk free", color: Mocha.yellow) { Text(data.diskFree) }
        Row(symbol: "bolt.fill", title: "Charger", color: Mocha.green) { Text(data.charger) }
        Row(symbol: "bolt.badge.clock", title: "Power draw", color: Mocha.peach) { Text(data.powerDraw) }
    }

    @ViewBuilder private var ai: some View {
        if data.ai.isEmpty {
            Text("No usage data yet").foregroundStyle(Mocha.subtext).padding(14)
        }
        ForEach(data.ai) { a in
            HStack(spacing: 8) {
                if let i = AppIcon.bundleIcon(a.id == "codex" ? "com.openai.codex" : "com.anthropic.claudefordesktop") {
                    Image(nsImage: i).resizable().frame(width: 16, height: 16)
                }
                Text(a.title).font(.system(size: 13, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 10).frame(height: 26)
            .background(RoundedRectangle(cornerRadius: 8).fill(Mocha.surface0))
            .padding(.horizontal, 8).padding(.top, 4)
            meterRow("clock.arrow.circlepath", "5-hour", a.fiveHour)
            meterRow("calendar", "Weekly", a.weekly)
            ForEach(a.extra, id: \.self) { e in
                Row(symbol: "arrow.counterclockwise", title: "Resets", color: Mocha.teal) { Text(e).font(.system(size: 12)) }
            }
        }
        Divider().overlay(Mocha.surface0).padding(.horizontal, 14).padding(.vertical, 4)
        Row(symbol: "clock", title: "Updated", color: Mocha.overlay0) {
            Text(data.aiUpdated.map { $0.formatted(date: .omitted, time: .shortened) } ?? "--").foregroundStyle(Mocha.overlay0)
        }
        .onTapGesture { data.refreshAI(fetch: true, force: true) }
        Row(symbol: "chart.bar.xaxis", title: "Dashboard", color: Mocha.blue) {
            Text("localhost:3100").foregroundStyle(Mocha.blue)
        }
        .onTapGesture { open("http://localhost:3100/") }
    }

    private func meterRow(_ sym: String, _ title: String, _ m: UsageMeter) -> some View {
        Row(symbol: sym, title: title, color: Mocha.subtext) {
            HStack {
                Meter(pct: m.pct ?? 0)
                Text(m.pct.map { "\(Int($0))%" } ?? "--").frame(width: 38, alignment: .trailing)
                Text(m.reset.map { BarData.left($0) } ?? "").foregroundStyle(Mocha.subtext).frame(width: 52, alignment: .trailing)
            }
        }
    }

    private func open(_ s: String) {
        if let u = URL(string: s) { NSWorkspace.shared.open(u) }
        state.open = nil
    }

    private var volumeSymbol: String {
        if data.muted || data.volume == 0 { return "speaker.slash.fill" }
        return data.volume >= 60 ? "speaker.wave.3.fill" : data.volume >= 30 ? "speaker.wave.2.fill" : "speaker.wave.1.fill"
    }
    private var batterySymbol: String {
        if data.charging { return "battery.100percent.bolt" }
        switch data.batteryPct { case 88...: return "battery.100percent"; case 63...: return "battery.75percent"
        case 38...: return "battery.50percent"; case 13...: return "battery.25percent"; default: return "battery.0percent" }
    }
    private var batteryColor: Color {
        if data.charging { return Mocha.green }
        switch data.batteryPct { case 70...: return Mocha.green; case 50...: return Mocha.yellow
        case 30...: return Mocha.peach; default: return Mocha.red }
    }
    static func short(_ t: String) -> String {
        var s = t.replacingOccurrences(of: #"\s*[\(\[][^\)\]]*[\)\]]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        if s.isEmpty { s = t }
        return s.count > 18 ? String(s.prefix(17)) + "…" : s
    }
}

// MARK: controller

final class TopBarController {
    let data = BarData()
    let menuBar = MenuBarModel()
    let state = TopBarState()
    let settings: Settings
    var panel: FloatingPanel?
    var dropPanel: FloatingPanel?
    private var bag = Set<AnyCancellable>()
    private var clickMonitor: Any?
    private let barHeight: CGFloat = 48

    init(settings: Settings) {
        self.settings = settings
        settings.$showTopBar.sink { [weak self] _ in main { self?.reposition() } }.store(in: &bag)
        // The bar window never changes size; dropdowns fade in their own window below it.
        state.$open.removeDuplicates().sink { [weak self] open in self?.showDropdown(open != nil) }.store(in: &bag)
        // Close an open dropdown when clicking anywhere else.
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            main { self?.state.open = nil }
        }
    }

    private func showDropdown(_ show: Bool) {
        guard let p = dropPanel else { return }
        if show {
            p.alphaValue = 0
            p.orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = show ? 0.14 : 0.12
            p.animator().alphaValue = show ? 1 : 0
        }, completionHandler: { [weak self] in
            if !show, self?.state.open == nil { p.orderOut(nil) }
        })
    }

    func reposition() {
        panel?.orderOut(nil); panel = nil
        dropPanel?.orderOut(nil); dropPanel = nil
        guard settings.showTopBar, let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main else { return }
        let geo = NotchGeometry.of(screen)
        let f = screen.frame
        let bar = FloatingPanel(rect: NSRect(x: f.minX, y: f.maxY - barHeight, width: f.width, height: barHeight), level: .floating)
        bar.contentView = FirstClickHostingView(rootView: TopBarView(data: data, menuBar: menuBar, state: state,
                                                                     notchGap: geo.hasNotch ? geo.notchWidth : 0))
        bar.orderFrontRegardless()
        panel = bar

        // Fixed-size, mostly transparent window under the bar's right end; content is top-aligned.
        let w: CGFloat = 400, h: CGFloat = 820
        let drop = FloatingPanel(rect: NSRect(x: f.maxX - w, y: f.maxY - barHeight - h, width: w, height: h), level: .floating)
        drop.contentView = FirstClickHostingView(rootView: TopBarView(data: data, menuBar: menuBar, state: state,
                                                                      notchGap: 0, dropdownOnly: true))
        dropPanel = drop
        if state.open != nil { showDropdown(true) }
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] { var seen = Set<Element>(); return filter { seen.insert($0).inserted } }
}
