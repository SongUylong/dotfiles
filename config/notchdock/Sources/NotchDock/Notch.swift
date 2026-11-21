import AppKit
import Combine
import QuickLookThumbnailing
import SwiftUI

/// Files parked on the notch shelf. Persisted as bookmarks so they survive relaunches.
final class ShelfModel: ObservableObject {
    @Published var files: [URL] = [] { didSet { save() } }
    @Published var expanded = false
    @Published var dropTargeted = false

    init() { load() }

    func add(_ urls: [URL]) {
        for u in urls where !files.contains(u) { files.append(u) }
    }
    func remove(_ url: URL) { files.removeAll { $0 == url } }
    func clear() { files.removeAll() }

    private func save() {
        let data = files.compactMap { try? $0.bookmarkData() }
        UserDefaults.standard.set(data, forKey: "shelf")
    }
    private func load() {
        let data = UserDefaults.standard.array(forKey: "shelf") as? [Data] ?? []
        files = data.compactMap { d in
            var stale = false
            guard let u = try? URL(resolvingBookmarkData: d, bookmarkDataIsStale: &stale),
                  FileManager.default.fileExists(atPath: u.path) else { return nil }
            return u
        }
    }
}

struct NotchGeometry {
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let hasNotch: Bool

    static func of(_ screen: NSScreen) -> NotchGeometry {
        let top = screen.safeAreaInsets.top
        if top > 0, let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
            return NotchGeometry(notchWidth: screen.frame.width - l.width - r.width,
                                 notchHeight: top, hasNotch: true)
        }
        // No notch: use a slim pill under the menu bar centre as the drop target.
        let menuBar = screen.frame.maxY - screen.visibleFrame.maxY
        return NotchGeometry(notchWidth: 200, notchHeight: max(menuBar, 24), hasNotch: false)
    }
}

struct NotchShape: Shape {
    var bottomRadius: CGFloat
    var animatableData: CGFloat {
        get { bottomRadius } set { bottomRadius = newValue }
    }
    func path(in r: CGRect) -> Path {
        var p = Path()
        let t: CGFloat = 6   // small outward flare at the top, like the hardware notch
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX + t, y: r.minY + t), control: CGPoint(x: r.minX + t, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + t, y: r.maxY - bottomRadius))
        p.addQuadCurve(to: CGPoint(x: r.minX + t + bottomRadius, y: r.maxY), control: CGPoint(x: r.minX + t, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - t - bottomRadius, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - t, y: r.maxY - bottomRadius), control: CGPoint(x: r.maxX - t, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - t, y: r.minY + t))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.maxX - t, y: r.minY))
        p.closeSubpath()
        return p
    }
}

struct NotchView: View {
    @ObservedObject var shelf: ShelfModel
    let geo: NotchGeometry

    private var open: Bool { shelf.expanded || shelf.dropTargeted }
    private var width: CGFloat { open ? max(geo.notchWidth + 260, 520) : geo.notchWidth + 12 }
    private var height: CGFloat { open ? geo.notchHeight + 130 : geo.notchHeight }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                NotchShape(bottomRadius: open ? 14 : 10)
                    .fill(open ? Mocha.base : Color.black)
                    .overlay(NotchShape(bottomRadius: open ? 14 : 10).stroke(open ? Mocha.surface1 : .clear, lineWidth: 1))
                    .shadow(color: .black.opacity(open ? 0.5 : 0), radius: 12, y: 4)
                if open { content.padding(.top, geo.notchHeight + 4).transition(.opacity) }
                else if !shelf.files.isEmpty { collapsedBadge }
            }
            .frame(width: width, height: height)
            // Closed: only the middle of the notch opens it (small overlay).
            // Open: hover is tracked on the shelf itself, so tiles stay draggable.
            .overlay(alignment: .top) {
                if !open {
                    Color.clear
                        .frame(width: geo.notchWidth * 0.6, height: geo.notchHeight * 0.8)
                        .contentShape(Rectangle())
                        .onHover { h in if h { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shelf.expanded = true } } }
                }
            }
            .onHover { h in
                if !h, shelf.expanded { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shelf.expanded = false } }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: open)
        .preferredColorScheme(.dark)
    }

    private var collapsedBadge: some View {
        HStack {
            Image(systemName: "tray.full.fill").font(.system(size: 11))
            Spacer()
            Text("\(shelf.files.count)").font(.system(size: 11, weight: .semibold)).monospacedDigit()
        }
        .foregroundStyle(Mocha.mauve)
        .padding(.horizontal, 14)
        .frame(height: geo.notchHeight)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Shelf", systemImage: "tray.full").font(.system(size: 13, weight: .semibold)).foregroundStyle(Mocha.mauve)
                Spacer()
                if !shelf.files.isEmpty {
                    Button("Clear") { withAnimation { shelf.clear() } }
                        .buttonStyle(.plain).font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.red)
                }
            }
            if shelf.files.isEmpty {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(shelf.dropTargeted ? Mocha.blue : Mocha.surface1)
                    .overlay(Text("Drop files here to keep them handy").font(.system(size: 12, weight: .medium)).foregroundStyle(Mocha.subtext))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(shelf.files, id: \.self) { ShelfTile(url: $0, shelf: shelf) }
                    }
                }
            }
        }
        .foregroundStyle(Mocha.text)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

struct ShelfTile: View {
    let url: URL
    @ObservedObject var shelf: ShelfModel
    @State private var thumb: NSImage?
    @State private var hover = false

    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: thumb ?? NSWorkspace.shared.icon(forFile: url.path))
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
            Text(url.lastPathComponent)
                .font(.system(size: 10)).lineLimit(1).truncationMode(.middle)
                .frame(width: 70)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 9).fill(hover ? Mocha.surface0 : .clear))
        .overlay(alignment: .topTrailing) {
            if hover {
                Button { withAnimation { shelf.remove(url) } } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 14))
                        .symbolRenderingMode(.palette).foregroundStyle(Mocha.base, Mocha.red)
                }.buttonStyle(.plain).offset(x: 4, y: -4)
            }
        }
        .onHover { hover = $0 }
        .onTapGesture(count: 2) { NSWorkspace.shared.open(url) }
        .onDrag { NSItemProvider(contentsOf: url) ?? NSItemProvider() }
        .contextMenu {
            Button("Open") { NSWorkspace.shared.open(url) }
            Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.path, forType: .string)
            }
            Divider()
            Button("Remove from Shelf") { shelf.remove(url) }
        }
        .task {
            let req = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 104, height: 104),
                                                   scale: 2, representationTypes: .thumbnail)
            if let rep = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: req) {
                thumb = rep.nsImage
            }
        }
    }
}

/// AppKit drop target for the whole notch panel. SwiftUI's onDrop was unreliable in a
/// non-activating panel at screen-saver level, so drops are handled here directly.
/// A plain NSView (not NSHostingView, which re-registers its own drag types on every
/// SwiftUI update and so drops ours) that hosts the SwiftUI shelf as a subview.
final class NotchDropView: NSView {
    let shelf: ShelfModel
    var activeRect: () -> NSRect = { .zero }   // bottom-left origin; drops outside it are refused

    init(shelf: ShelfModel, geo: NotchGeometry) {
        self.shelf = shelf
        super.init(frame: .zero)
        let host = NSHostingView(rootView: NotchView(shelf: shelf, geo: geo))
        host.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: leadingAnchor), host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.topAnchor.constraint(equalTo: topAnchor), host.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        registerForDraggedTypes([.fileURL])
    }
    required init?(coder: NSCoder) { fatalError() }

    private func hasFiles(_ info: NSDraggingInfo) -> Bool {
        info.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
    }
    private func update(_ info: NSDraggingInfo) -> NSDragOperation {
        var pt = convert(info.draggingLocation, from: nil)
        if isFlipped { pt.y = bounds.height - pt.y }   // activeRect uses bottom-left origin
        let inside = hasFiles(info) && activeRect().contains(pt)
        if shelf.dropTargeted != inside {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shelf.dropTargeted = inside }
        }
        return inside ? .copy : []
    }
    override func draggingEntered(_ info: NSDraggingInfo) -> NSDragOperation { update(info) }
    override func draggingUpdated(_ info: NSDraggingInfo) -> NSDragOperation { update(info) }
    override func draggingExited(_ info: NSDraggingInfo?) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shelf.dropTargeted = false }
    }
    override func prepareForDragOperation(_ info: NSDraggingInfo) -> Bool { shelf.dropTargeted }
    override func performDragOperation(_ info: NSDraggingInfo) -> Bool {
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self],
                                                       options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        shelf.add(urls)
        return !urls.isEmpty
    }
    override func concludeDragOperation(_ info: NSDraggingInfo?) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shelf.dropTargeted = false; shelf.expanded = true }
    }
}

final class NotchController {
    let settings: Settings
    let shelf = ShelfModel()
    var panel: FloatingPanel?
    private var bag = Set<AnyCancellable>()
    private var dragMonitor: Any?
    private var dragCount = -1

    init(settings: Settings) {
        self.settings = settings
        settings.$showNotchShelf.sink { [weak self] _ in DispatchQueue.main.async { self?.reposition() } }.store(in: &bag)
        // While a file is dragged anywhere (e.g. from Finder), open the shelf as the pointer nears
        // the notch, so there is a big target instead of the tiny hardware notch.
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] e in
            self?.trackDrag(e)
        }
        // Drags that start inside NotchDock (e.g. a file from the launcher) aren't seen by the
        // global monitor, so poll the pointer until the mouse button is released.
        NotificationCenter.default.addObserver(forName: .notchdockInternalDrag, object: nil, queue: .main) { [weak self] _ in
            self?.pollInternalDrag()
        }
    }

    private var pollTimer: Timer?
    private func pollInternalDrag() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] t in
            guard let self, let screen = self.screen else { t.invalidate(); return }
            if NSEvent.pressedMouseButtons & 1 == 0 {
                t.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if self.shelf.expanded, !(self.panel?.frame.contains(NSEvent.mouseLocation) ?? false) { self.setExpanded(false) }
                }
                return
            }
            let p = NSEvent.mouseLocation
            let geo = NotchGeometry.of(screen)
            let near = abs(p.x - screen.frame.midX) < geo.notchWidth * 0.3 && p.y > screen.frame.maxY - geo.notchHeight * 0.8
            if near, !self.shelf.expanded { self.setExpanded(true) }
            else if !near, self.shelf.expanded, !(self.panel?.frame.contains(p) ?? false) { self.setExpanded(false) }
        }
    }

    private func trackDrag(_ e: NSEvent) {
        guard let screen, panel != nil else { return }
        if e.type == .leftMouseUp {
            if shelf.expanded, !(panel?.frame.contains(NSEvent.mouseLocation) ?? false) { setExpanded(false) }
            return
        }
        let pb = NSPasteboard(name: .drag)
        guard pb.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else { return }
        let p = NSEvent.mouseLocation
        // Only right at the notch: its width plus a small margin, and the top ~notch height.
        let geo = NotchGeometry.of(screen)
        let near = abs(p.x - screen.frame.midX) < geo.notchWidth * 0.3 && p.y > screen.frame.maxY - geo.notchHeight * 0.8
        if near != shelf.expanded { setExpanded(near) }
    }

    private func setExpanded(_ v: Bool) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shelf.expanded = v }
    }

    /// Prefer the built-in display (the one with the notch).
    private var screen: NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main
    }

    func reposition() {
        panel?.orderOut(nil)
        panel = nil
        guard settings.showNotchShelf, let screen else { return }
        let geo = NotchGeometry.of(screen)
        let w: CGFloat = 640, h: CGFloat = geo.notchHeight + 160
        let rect = NSRect(x: screen.frame.midX - w / 2, y: screen.frame.maxY - h, width: w, height: h)
        // Not .screenSaver: macOS never delivers drags to windows at that level.
        let p = FloatingPanel(rect: rect, level: .statusBar)
        let view = NotchDropView(shelf: shelf, geo: geo)
        // Accept drops on the notch itself, or on the whole shelf once it is open.
        view.activeRect = { [weak shelf] in
            let open = (shelf?.expanded ?? false) || (shelf?.dropTargeted ?? false)
            let ww: CGFloat = open ? max(geo.notchWidth + 260, 520) : geo.notchWidth * 0.6
            let hh: CGFloat = open ? geo.notchHeight + 130 : geo.notchHeight
            return NSRect(x: (w - ww) / 2, y: h - hh, width: ww, height: hh)
        }
        p.contentView = view
        p.orderFrontRegardless()
        panel = p
    }
}

extension Notification.Name {
    static let notchdockInternalDrag = Notification.Name("notchdockInternalDrag")
}
