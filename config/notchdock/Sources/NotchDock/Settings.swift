import AppKit
import Combine

/// Persisted user preferences, shared by the dock, the notch shelf and the settings window.
final class Settings: ObservableObject {
    static let shared = Settings()
    private let d = UserDefaults.standard

    @Published var showDock: Bool { didSet { d.set(showDock, forKey: "showDock") } }
    @Published var autoHideDock: Bool { didSet { d.set(autoHideDock, forKey: "autoHideDock") } }
    @Published var iconSize: Double { didSet { d.set(iconSize, forKey: "iconSize") } }
    @Published var magnification: Double { didSet { d.set(magnification, forKey: "magnification") } }
    @Published var showNotchShelf: Bool { didSet { d.set(showNotchShelf, forKey: "showNotchShelf") } }
    @Published var showTopBar: Bool { didSet { d.set(showTopBar, forKey: "showTopBar") } }
    @Published var pinnedBundleIDs: [String] { didSet { d.set(pinnedBundleIDs, forKey: "pinned") } }

    private init() {
        d.register(defaults: [
            "showDock": true, "autoHideDock": true, "iconSize": 48.0,
            "magnification": 1.6, "showNotchShelf": true, "showTopBar": true,
            "pinned": ["com.apple.finder", "com.apple.Safari", "com.apple.Terminal", "com.apple.systempreferences"],
        ])
        showDock = d.bool(forKey: "showDock")
        autoHideDock = d.bool(forKey: "autoHideDock")
        iconSize = d.double(forKey: "iconSize")
        magnification = d.double(forKey: "magnification")
        showNotchShelf = d.bool(forKey: "showNotchShelf")
        showTopBar = d.bool(forKey: "showTopBar")
        pinnedBundleIDs = d.stringArray(forKey: "pinned") ?? []
    }

    func togglePin(_ id: String) {
        if let i = pinnedBundleIDs.firstIndex(of: id) { pinnedBundleIDs.remove(at: i) }
        else { pinnedBundleIDs.append(id) }
    }
}
