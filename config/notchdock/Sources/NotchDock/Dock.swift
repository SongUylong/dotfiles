import AppKit
import Combine
import SwiftUI

struct DockItem: Identifiable, Equatable {
    let id: String          // bundle id
    let name: String
    let icon: NSImage
    let url: URL?
    var isRunning: Bool
    var isPinned: Bool
    static func == (a: DockItem, b: DockItem) -> Bool {
        a.id == b.id && a.isRunning == b.isRunning && a.isPinned == b.isPinned
    }
}

final class DockModel: ObservableObject {
    @Published var items: [DockItem] = []
    @Published var frontmostID: String?
    let settings: Settings
    private var bag = Set<AnyCancellable>()

    init(settings: Settings) {
        self.settings = settings
        let nc = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification,
                     NSWorkspace.didTerminateApplicationNotification,
                     NSWorkspace.didActivateApplicationNotification] {
            nc.publisher(for: name).sink { [weak self] _ in self?.refresh() }.store(in: &bag)
        }
        settings.$pinnedBundleIDs.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }.store(in: &bag)
        refresh()
    }

    func refresh() {
        let ws = NSWorkspace.shared
        let running = ws.runningApplications.filter { $0.activationPolicy == .regular }
        let runningIDs = Set(running.compactMap(\.bundleIdentifier))
        var result: [DockItem] = []
        for id in settings.pinnedBundleIDs {
            guard let url = ws.urlForApplication(withBundleIdentifier: id) else { continue }
            result.append(DockItem(id: id, name: FileManager.default.displayName(atPath: url.path)
                                    .replacingOccurrences(of: ".app", with: ""),
                                   icon: ws.icon(forFile: url.path), url: url,
                                   isRunning: runningIDs.contains(id), isPinned: true))
        }
        for app in running {
            guard let id = app.bundleIdentifier, !settings.pinnedBundleIDs.contains(id) else { continue }
            result.append(DockItem(id: id, name: app.localizedName ?? id,
                                   icon: app.icon ?? NSImage(), url: app.bundleURL,
                                   isRunning: true, isPinned: false))
        }
        frontmostID = ws.frontmostApplication?.bundleIdentifier
        if result != items { items = result }
    }

    func open(_ item: DockItem) {
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: item.id).first {
            if app.isActive { app.hide() } else {
                app.unhide()
                app.activate()
                // Reopen a window if the app has none (like the real Dock).
                if let url = item.url {
                    NSWorkspace.shared.openApplication(at: url, configuration: .init())
                }
            }
        } else if let url = item.url {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }

    func quit(_ item: DockItem) {
        NSRunningApplication.runningApplications(withBundleIdentifier: item.id).forEach { $0.terminate() }
    }

    func reveal(_ item: DockItem) {
        if let url = item.url { NSWorkspace.shared.activateFileViewerSelecting([url]) }
    }

    /// Files dropped on an app icon are opened with that app.
    func openFiles(_ urls: [URL], with item: DockItem) {
        guard let app = item.url else { return }
        NSWorkspace.shared.open(urls, withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
    }
}

struct DockView: View {
    @ObservedObject var model: DockModel
    @ObservedObject var settings: Settings
    @State private var hoverX: CGFloat?
    @State private var hoveredID: String?

    private var size: CGFloat { settings.iconSize }
    private let spacing: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                    if index > 0, !item.isPinned, model.items[index - 1].isPinned {
                        Rectangle().fill(Mocha.surface1).frame(width: 1, height: size * 0.7)
                            .padding(.horizontal, 4).padding(.bottom, size * 0.15)
                    }
                    DockIcon(item: item, size: size, scale: scale(for: index),
                             isFront: model.frontmostID == item.id,
                             showLabel: hoveredID == item.id, model: model, settings: settings)
                        .onHover { hoveredID = $0 ? item.id : (hoveredID == item.id ? nil : hoveredID) }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BarBackground(radius: 12).frame(height: size + 16), alignment: .bottom)
            .onContinuousHover(coordinateSpace: .local) { phase in
                withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.8)) {
                    if case .active(let p) = phase { hoverX = p.x } else { hoverX = nil }
                }
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
    }

    /// Classic fisheye: icons near the pointer grow, falling off smoothly over ~3 icons.
    private func scale(for index: Int) -> CGFloat {
        guard let x = hoverX, settings.magnification > 1 else { return 1 }
        let center = 10 + CGFloat(index) * (size + spacing) + size / 2
        let d = abs(x - center) / (size * 2.5)
        guard d < 1 else { return 1 }
        return 1 + (settings.magnification - 1) * cos(d * .pi / 2)
    }
}

struct DockIcon: View {
    let item: DockItem
    let size: CGFloat
    let scale: CGFloat
    let isFront: Bool
    let showLabel: Bool
    let model: DockModel
    @ObservedObject var settings: Settings
    @State private var bounce = false
    @State private var dropTarget = false

    var body: some View {
        VStack(spacing: 3) {
            Image(nsImage: item.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: size * scale, height: size * scale)
                .offset(y: bounce ? -size * 0.35 : 0)
                .brightness(dropTarget ? 0.15 : 0)
                .overlay(alignment: .top) {
                    if showLabel {
                        Text(item.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Mocha.lavender)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(BarBackground(radius: 8))
                            .fixedSize()
                            .offset(y: -30)
                            .transition(.opacity)
                    }
                }
            Circle()
                .fill(isFront ? Mocha.blue : Mocha.subtext)
                .frame(width: 4, height: 4)
                .opacity(item.isRunning ? 1 : 0)
        }
        .frame(width: size * scale)
        .contentShape(Rectangle())
        .onTapGesture {
            if !item.isRunning {
                withAnimation(.easeOut(duration: 0.25).repeatCount(2, autoreverses: true)) { bounce = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { bounce = false }
            }
            model.open(item)
        }
        .onDrop(of: [.fileURL], isTargeted: $dropTarget) { providers in
            loadURLs(providers) { model.openFiles($0, with: item) }
            return true
        }
        .contextMenu {
            Button(item.isPinned ? "Remove from Dock" : "Keep in Dock") { settings.togglePin(item.id) }
            Button("Show in Finder") { model.reveal(item) }
            if item.isRunning {
                Divider()
                Button("Quit") { model.quit(item) }
            }
        }
    }
}

func loadURLs(_ providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
    let group = DispatchGroup()
    var urls: [URL] = []
    for p in providers {
        group.enter()
        _ = p.loadObject(ofClass: URL.self) { url, _ in
            if let url { DispatchQueue.main.async { urls.append(url) } }
            group.leave()
        }
    }
    group.notify(queue: .main) { completion(urls) }
}

final class DockController {
    let settings: Settings
    let model: DockModel
    let panel: FloatingPanel
    private var bag = Set<AnyCancellable>()
    private var mouseMonitor: Any?
    private var hidden = false

    init(settings: Settings) {
        self.settings = settings
        model = DockModel(settings: settings)
        panel = FloatingPanel(rect: .zero, level: .statusBar)
        panel.contentView = NSHostingView(rootView: DockView(model: model, settings: settings))
        hidden = settings.autoHideDock
        reposition()
        settings.$autoHideDock.dropFirst().sink { [weak self] on in DispatchQueue.main.async { self?.setHidden(on) } }.store(in: &bag)
        settings.$showDock.sink { [weak self] _ in DispatchQueue.main.async { self?.applyVisibility() } }.store(in: &bag)
        settings.$iconSize.sink { [weak self] _ in DispatchQueue.main.async { self?.reposition() } }.store(in: &bag)
        settings.$magnification.sink { [weak self] _ in DispatchQueue.main.async { self?.reposition() } }.store(in: &bag)
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in self?.trackMouse() }
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] e in self?.trackMouse(); return e }
    }

    /// The panel is wide and tall enough for magnified icons and labels; the
    /// transparent area lets clicks fall through to windows below.
    func reposition() {
        guard let screen = NSScreen.main else { return }
        let f = screen.frame
        let height = settings.iconSize * max(settings.magnification, 1) + 70
        let frame = NSRect(x: f.minX, y: f.minY + (hidden ? -height : 0), width: f.width, height: height)
        panel.setFrame(frame, display: true)
        applyVisibility()
    }

    private func applyVisibility() {
        if settings.showDock { panel.orderFrontRegardless() } else { panel.orderOut(nil) }
    }

    private func trackMouse() {
        guard settings.showDock, let screen = NSScreen.main else { return }
        let p = NSEvent.mouseLocation
        if !settings.autoHideDock {
            if hidden { setHidden(false) }
            return
        }
        let barTop = screen.frame.minY + settings.iconSize * max(settings.magnification, 1) + 30
        if hidden, p.y <= screen.frame.minY + 2 { setHidden(false) }
        else if !hidden, p.y > barTop { setHidden(true) }
    }

    private func setHidden(_ h: Bool) {
        hidden = h
        guard let screen = NSScreen.main else { return }
        var frame = panel.frame
        frame.origin.y = screen.frame.minY + (h ? -frame.height : 0)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            panel.animator().setFrame(frame, display: true)
        }
    }
}
