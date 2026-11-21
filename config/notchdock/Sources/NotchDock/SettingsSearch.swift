import SwiftUI

/// System Settings panes for the launcher, like Raycast's settings search.
enum SettingsPanes {
    struct Pane { let title: String; let id: String; let symbol: String; let keywords: String }
    static let all: [Pane] = [
        .init(title: "Wi-Fi", id: "com.apple.wifi-settings-extension", symbol: "wifi", keywords: "network internet wireless"),
        .init(title: "Bluetooth", id: "com.apple.BluetoothSettings", symbol: "dot.radiowaves.left.and.right", keywords: "airpods headphones devices"),
        .init(title: "Network", id: "com.apple.Network-Settings.extension", symbol: "network", keywords: "ethernet vpn dns proxy"),
        .init(title: "VPN", id: "com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension", symbol: "lock.shield", keywords: "network"),
        .init(title: "Notifications", id: "com.apple.Notifications-Settings.extension", symbol: "bell.badge", keywords: "alerts banners"),
        .init(title: "Sound", id: "com.apple.Sound-Settings.extension", symbol: "speaker.wave.2", keywords: "volume audio output input microphone"),
        .init(title: "Focus", id: "com.apple.Focus-Settings.extension", symbol: "moon", keywords: "do not disturb dnd"),
        .init(title: "Screen Time", id: "com.apple.Screen-Time-Settings.extension", symbol: "hourglass", keywords: "limits"),
        .init(title: "General", id: "com.apple.systempreferences.GeneralSettings", symbol: "gearshape", keywords: "about software update storage"),
        .init(title: "Software Update", id: "com.apple.Software-Update-Settings.extension", symbol: "arrow.down.circle", keywords: "upgrade macos"),
        .init(title: "Storage", id: "com.apple.settings.Storage", symbol: "internaldrive", keywords: "disk space"),
        .init(title: "About This Mac", id: "com.apple.SystemProfiler.AboutExtension", symbol: "info.circle", keywords: "serial model version"),
        .init(title: "Login Items", id: "com.apple.LoginItems-Settings.extension", symbol: "person.crop.circle.badge.checkmark", keywords: "startup background apps"),
        .init(title: "Date & Time", id: "com.apple.Date-Time-Settings.extension", symbol: "clock", keywords: "timezone clock"),
        .init(title: "Sharing", id: "com.apple.Sharing-Settings.extension", symbol: "folder.badge.person.crop", keywords: "airdrop remote ssh screen sharing"),
        .init(title: "Time Machine", id: "com.apple.Time-Machine-Settings.extension", symbol: "clock.arrow.circlepath", keywords: "backup"),
        .init(title: "Appearance", id: "com.apple.Appearance-Settings.extension", symbol: "circle.lefthalf.filled", keywords: "dark light mode accent"),
        .init(title: "Accessibility", id: "com.apple.Accessibility-Settings.extension", symbol: "accessibility", keywords: "zoom voiceover"),
        .init(title: "Control Center", id: "com.apple.ControlCenter-Settings.extension", symbol: "switch.2", keywords: "menu bar"),
        .init(title: "Desktop & Dock", id: "com.apple.Desktop-Settings.extension", symbol: "dock.rectangle", keywords: "stage manager mission control hot corners"),
        .init(title: "Displays", id: "com.apple.Displays-Settings.extension", symbol: "display", keywords: "monitor resolution brightness night shift"),
        .init(title: "Wallpaper", id: "com.apple.Wallpaper-Settings.extension", symbol: "photo", keywords: "background"),
        .init(title: "Screen Saver", id: "com.apple.ScreenSaver-Settings.extension", symbol: "sparkles.tv", keywords: ""),
        .init(title: "Battery", id: "com.apple.Battery-Settings.extension", symbol: "battery.75", keywords: "power energy low power"),
        .init(title: "Lock Screen", id: "com.apple.Lock-Screen-Settings.extension", symbol: "lock", keywords: "sleep display off"),
        .init(title: "Privacy & Security", id: "com.apple.settings.PrivacySecurity.extension", symbol: "hand.raised", keywords: "permissions filevault"),
        .init(title: "Accessibility Permissions", id: "com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility", symbol: "hand.raised", keywords: "privacy allow control"),
        .init(title: "Screen Recording Permissions", id: "com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture", symbol: "record.circle", keywords: "privacy capture"),
        .init(title: "Full Disk Access", id: "com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles", symbol: "externaldrive.badge.checkmark", keywords: "privacy files"),
        .init(title: "Location Services", id: "com.apple.settings.PrivacySecurity.extension?Privacy_LocationServices", symbol: "location", keywords: "privacy gps"),
        .init(title: "Touch ID & Password", id: "com.apple.Touch-ID-Settings.extension", symbol: "touchid", keywords: "fingerprint"),
        .init(title: "Users & Groups", id: "com.apple.Users-Groups-Settings.extension", symbol: "person.2", keywords: "accounts"),
        .init(title: "Passwords", id: "com.apple.Passwords-Settings.extension", symbol: "key", keywords: "keychain"),
        .init(title: "Internet Accounts", id: "com.apple.Internet-Accounts-Settings.extension", symbol: "at", keywords: "mail google"),
        .init(title: "Keyboard", id: "com.apple.Keyboard-Settings.extension", symbol: "keyboard", keywords: "shortcuts input sources key repeat"),
        .init(title: "Trackpad", id: "com.apple.Trackpad-Settings.extension", symbol: "rectangle.and.hand.point.up.left", keywords: "gestures click scroll"),
        .init(title: "Mouse", id: "com.apple.Mouse-Settings.extension", symbol: "computermouse", keywords: "scroll"),
        .init(title: "Printers & Scanners", id: "com.apple.Print-Scan-Settings.extension", symbol: "printer", keywords: ""),
        .init(title: "Siri & Apple Intelligence", id: "com.apple.Siri-Settings.extension", symbol: "sparkle", keywords: "assistant"),
        .init(title: "Spotlight", id: "com.apple.Spotlight-Settings.extension", symbol: "magnifyingglass", keywords: "search"),
        .init(title: "Apple Account", id: "com.apple.systempreferences.AppleIDSettings", symbol: "person.crop.circle", keywords: "icloud apple id"),
    ]

    static func open(_ id: String) {
        if let u = URL(string: "x-apple.systempreferences:" + id) { NSWorkspace.shared.open(u) }
    }
}
