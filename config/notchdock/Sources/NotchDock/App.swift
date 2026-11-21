import AppKit
import SwiftUI

@main
struct NotchDockApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = Settings.shared
    var dock: DockController?
    var notch: NotchController?
    var topBar: TopBarController?
    var launcher: LauncherController?
    var switcher: SwitcherController?
    var settingsWindow: NSWindow?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        dock = DockController(settings: settings)
        topBar = TopBarController(settings: settings)
        notch = NotchController(settings: settings)
        launcher = LauncherController()
        switcher = SwitcherController()
        setupStatusItem()
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc func screensChanged() {
        dock?.reposition()
        topBar?.reposition()
        notch?.reposition()
    }

    func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "NotchDock")
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Launcher", action: #selector(openLauncher), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit NotchDock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    @objc func openLauncher() { launcher?.show() }

    @objc func openSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
                             styleMask: [.titled, .closable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.isMovableByWindowBackground = true
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: SettingsView(settings: settings))
            w.center()
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
