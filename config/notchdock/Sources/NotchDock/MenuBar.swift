import AppKit
import ApplicationServices
import Carbon
import Combine

/// Reads the real macOS menu bar through Accessibility: the frontmost app's menus and every
/// app's menu bar icons ("menu extras"). Menus are rebuilt as NSMenus whose items press the
/// original element, so they behave exactly like the system ones.
final class MenuBarModel: ObservableObject {
    struct TopMenu: Identifiable { let id: Int; let title: String; let element: AXUIElement }
    struct Extra: Identifiable {
        let id: String
        let pid: pid_t
        let title: String
        let icon: NSImage?
        let element: AXUIElement
    }

    @Published var trusted = AXIsProcessTrusted()
    @Published var appName = ""
    @Published var menus: [TopMenu] = []   // index 0 is the Apple menu
    @Published var extras: [Extra] = []
    @Published var inputSource = InputSources.current()

    private var bag = Set<AnyCancellable>()
    private var timer: Timer?

    /// Apple's own items we already draw ourselves (clock, battery, Wi-Fi, …) are skipped.
    private let skipBundles: Set<String> = ["com.apple.controlcenter", "com.apple.systemuiserver",
                                            "com.apple.TextInputMenuAgent", "com.apple.Spotlight",
                                            "com.eric.notchdock"]

    init() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in self?.refreshMenus() }.store(in: &bag)
        nc.publisher(for: NSWorkspace.didLaunchApplicationNotification).merge(with: nc.publisher(for: NSWorkspace.didTerminateApplicationNotification))
            .debounce(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.refreshExtras() }.store(in: &bag)
        DistributedNotificationCenter.default().publisher(for: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.inputSource = InputSources.current() }.store(in: &bag)
        // Permission can be granted while we run; extras also appear later as apps add them.
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self else { return }
            let t = AXIsProcessTrusted()
            if t != self.trusted { self.trusted = t; self.refreshMenus() }
            self.refreshExtras()
        }
        // Ask only when the user clicks the hint; prompting on every launch keeps opening Settings.
        refreshMenus()
        refreshExtras()
    }

    func requestTrust() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        trusted = AXIsProcessTrustedWithOptions(opts)
    }

    // MARK: app menus

    func refreshMenus() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        appName = app.localizedName ?? ""
        guard trusted else { menus = []; return }
        let pid = app.processIdentifier
        bg {
            let axApp = AXUIElementCreateApplication(pid)
            var result: [TopMenu] = []
            if let bar: AXUIElement = ax(axApp, kAXMenuBarAttribute) {
                for (i, item) in (axChildren(bar)).enumerated() {
                    let t: String = ax(item, kAXTitleAttribute) ?? ""
                    result.append(TopMenu(id: i, title: t, element: item))
                }
            }
            main { if NSWorkspace.shared.frontmostApplication?.processIdentifier == pid { self.menus = result } }
        }
    }

    /// Shows the given top-level menu as a native NSMenu at the current mouse position.
    func open(_ m: TopMenu, at point: NSPoint) {
        guard let submenu = axChildren(m.element).first else { return }
        let menu = buildMenu(submenu)
        menu.popUp(positioning: nil, at: point, in: nil)
    }

    /// One menu holding the Apple menu and every app menu as submenus. Submenus are filled
    /// lazily when hovered, so big apps (Xcode, browsers) stay fast.
    func combinedMenu() -> NSMenu {
        let root = NSMenu()
        root.autoenablesItems = false
        let header = NSMenuItem(title: appName, action: nil, keyEquivalent: "")
        header.isEnabled = false
        header.attributedTitle = NSAttributedString(string: appName, attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .bold)])
        root.addItem(header)
        root.addItem(.separator())
        for (i, m) in menus.enumerated() {
            let title = i == 0 ? "Apple" : m.title
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            if i == 0 { item.image = NSImage(systemSymbolName: "applelogo", accessibilityDescription: nil) }
            if i == 1 { item.attributedTitle = NSAttributedString(string: title, attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold)]) }
            let sub = LazyAXMenu(top: m, model: self)
            item.submenu = sub
            root.addItem(item)
            if i == 0 { root.addItem(.separator()) }
        }
        return root
    }

    /// Fills an existing NSMenu with a top-level menu's items (used by the » overflow menu).
    func fill(_ target: NSMenu, from m: TopMenu) {
        guard let submenu = axChildren(m.element).first else { return }
        for item in buildMenu(submenu).items { item.menu?.removeItem(item); target.addItem(item) }
    }

    func buildMenu(_ axMenu: AXUIElement) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for child in axChildren(axMenu) {
            let title: String = ax(child, kAXTitleAttribute) ?? ""
            if title.isEmpty {
                // Untitled entries are separators (or custom views we can't mirror).
                if menu.items.last?.isSeparatorItem == false { menu.addItem(.separator()) }
                continue
            }
            let item = AXMenuItem(title: title, element: child)
            item.isEnabled = (ax(child, kAXEnabledAttribute) as Bool?) ?? true
            if let mark: String = ax(child, kAXMenuItemMarkCharAttribute), !mark.isEmpty { item.state = .on }
            if let key: String = ax(child, kAXMenuItemCmdCharAttribute), !key.isEmpty {
                item.keyEquivalent = key.lowercased()
                let mods: Int = ax(child, kAXMenuItemCmdModifiersAttribute) ?? 0
                var flags: NSEvent.ModifierFlags = []
                if mods & 0x8 == 0 { flags.insert(.command) }   // kAXMenuItemModifierNoCommand
                if mods & 0x1 != 0 { flags.insert(.shift) }
                if mods & 0x2 != 0 { flags.insert(.option) }
                if mods & 0x4 != 0 { flags.insert(.control) }
                item.keyEquivalentModifierMask = flags
            }
            if let sub = axChildren(child).first, !axChildren(sub).isEmpty {
                item.submenu = buildMenu(sub)
            } else {
                item.target = item
                item.action = #selector(AXMenuItem.press)
            }
            menu.addItem(item)
        }
        if menu.items.last?.isSeparatorItem == true { menu.removeItem(at: menu.items.count - 1) }
        return menu
    }

    // MARK: menu bar icons

    func refreshExtras() {
        guard trusted else { extras = []; return }
        let apps = NSWorkspace.shared.runningApplications.filter { !skipBundles.contains($0.bundleIdentifier ?? "") }
        bg {
            var out: [Extra] = []
            for app in apps {
                let axApp = AXUIElementCreateApplication(app.processIdentifier)
                guard let bar: AXUIElement = ax(axApp, "AXExtrasMenuBar") else { continue }
                for (i, item) in axChildren(bar).enumerated() {
                    let title: String = ax(item, kAXDescriptionAttribute) ?? ax(item, kAXTitleAttribute) ?? app.localizedName ?? ""
                    out.append(Extra(id: "\(app.processIdentifier)-\(i)", pid: app.processIdentifier,
                                     title: title.isEmpty ? (app.localizedName ?? "") : title,
                                     icon: Self.snapshot(of: item) ?? app.icon, element: item))
                }
            }
            main { self.extras = out }
        }
    }

    /// Captures the status item's own pixels when Screen Recording is allowed; nil otherwise.
    private static func snapshot(of item: AXUIElement) -> NSImage? {
        guard CGPreflightScreenCaptureAccess(),
              let pos: CGPoint = axValue(item, kAXPositionAttribute),
              let size: CGSize = axValue(item, kAXSizeAttribute), size.width > 0 else { return nil }
        guard let cg = CGWindowListCreateImage(CGRect(origin: pos, size: size), .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
        else { return nil }
        return NSImage(cgImage: cg, size: size)
    }

    /// Opens Notification Center by pressing Control Center's clock item (what clicking the
    /// date in the real menu bar does). Needs Accessibility.
    func openNotificationCenter() {
        guard trusted, let cc = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.controlcenter").first else { return }
        bg {
            let app = AXUIElementCreateApplication(cc.processIdentifier)
            guard let bar: AXUIElement = ax(app, "AXExtrasMenuBar") else { return }
            let items = axChildren(bar)
            let clock = items.first { el in
                let id: String = ax(el, "AXIdentifier") ?? ""
                let d: String = ax(el, kAXDescriptionAttribute) ?? ""
                return id.contains("clock") || d.localizedCaseInsensitiveContains("clock")
            } ?? items.last   // the clock is the rightmost item
            if let clock { AXUIElementPerformAction(clock, kAXPressAction as CFString) }
        }
    }

    func click(_ e: Extra) {
        // Pressing the real item opens its own menu/popover where the app drew it.
        bg { AXUIElementPerformAction(e.element, kAXPressAction as CFString) }
    }
}

final class AXMenuItem: NSMenuItem {
    let element: AXUIElement
    init(title: String, element: AXUIElement) {
        self.element = element
        super.init(title: title, action: nil, keyEquivalent: "")
    }
    required init(coder: NSCoder) { fatalError() }
    @objc func press() {
        let e = element
        bg { AXUIElementPerformAction(e, kAXPressAction as CFString) }
    }
}

// MARK: AX helpers

func ax<T>(_ el: AXUIElement, _ attr: String) -> T? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success else { return nil }
    return v as? T
}

func axChildren(_ el: AXUIElement) -> [AXUIElement] {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, kAXChildrenAttribute as CFString, &v) == .success else { return [] }
    return v as? [AXUIElement] ?? []
}

func axValue<T>(_ el: AXUIElement, _ attr: String) -> T? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(el, attr as CFString, &v) == .success, let v,
          CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
    let val = v as! AXValue
    if T.self == CGPoint.self { var p = CGPoint.zero; AXValueGetValue(val, .cgPoint, &p); return p as? T }
    if T.self == CGSize.self { var s = CGSize.zero; AXValueGetValue(val, .cgSize, &s); return s as? T }
    return nil
}

// MARK: input sources

enum InputSources {
    struct Source: Identifiable, Equatable {
        let id: String
        let name: String
        let icon: NSImage?
        let ref: TISInputSource
        static func == (a: Source, b: Source) -> Bool { a.id == b.id }
    }

    private static func prop<T>(_ s: TISInputSource, _ key: CFString) -> T? {
        guard let p = TISGetInputSourceProperty(s, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(p).takeUnretainedValue() as? T
    }

    private static func make(_ s: TISInputSource) -> Source {
        let id: String = prop(s, kTISPropertyInputSourceID) ?? "?"
        let name: String = prop(s, kTISPropertyLocalizedName) ?? id
        var icon: NSImage?
        if let url: URL = prop(s, kTISPropertyIconImageURL) {
            // Input-method icons ship as .tiff; @2x versions sit next to them.
            let x2 = url.deletingPathExtension().appendingPathExtension("tiff").path.replacingOccurrences(of: ".tiff", with: "@2x.tiff")
            icon = NSImage(contentsOfFile: x2) ?? NSImage(contentsOf: url)
        } else if let iconRef = TISGetInputSourceProperty(s, kTISPropertyIconRef) {
            icon = NSImage(iconRef: OpaquePointer(iconRef))
        }
        icon?.isTemplate = true
        return Source(id: id, name: name, icon: icon, ref: s)
    }

    static func current() -> Source { make(TISCopyCurrentKeyboardInputSource().takeRetainedValue()) }

    /// The sources the user has enabled for switching (what the system menu lists).
    static func enabled() -> [Source] {
        let filter = [kTISPropertyInputSourceIsSelectCapable: true,
                      kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource] as CFDictionary
        let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] ?? []
        return list.map(make).filter { !$0.id.contains("PressAndHold") }
    }

    static func menu() -> NSMenu {
        let m = NSMenu()
        let cur = current().id
        for s in enabled() {
            let item = ClosureMenuItem(title: s.name) { TISSelectInputSource(s.ref) }
            item.image = s.icon.map { img in
                let i = img.copy() as! NSImage; i.size = NSSize(width: 18, height: 18); return i
            }
            item.state = s.id == cur ? .on : .off
            m.addItem(item)
        }
        m.addItem(.separator())
        m.addItem(ClosureMenuItem(title: "Show Emoji & Symbols") { NSApp.orderFrontCharacterPalette(nil) })
        m.addItem(ClosureMenuItem(title: "Open Keyboard Settings…") {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!)
        })
        return m
    }
}

final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void
    init(title: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: "")
        target = self
    }
    required init(coder: NSCoder) { fatalError() }
    @objc private func fire() { handler() }
}

/// A submenu that reads its items from Accessibility the first time it opens.
final class LazyAXMenu: NSMenu, NSMenuDelegate {
    let top: MenuBarModel.TopMenu
    weak var model: MenuBarModel?
    private var loaded = false
    init(top: MenuBarModel.TopMenu, model: MenuBarModel) {
        self.top = top; self.model = model
        super.init(title: top.title)
        autoenablesItems = false
        delegate = self
        addItem(NSMenuItem(title: "…", action: nil, keyEquivalent: ""))   // so the arrow shows
    }
    required init(coder: NSCoder) { fatalError() }
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard !loaded, let model, let ax = axChildren(top.element).first else { return }
        loaded = true
        removeAllItems()
        for item in model.buildMenu(ax).items { item.menu?.removeItem(item); addItem(item) }
    }
}
