import AppKit

final class ColorPickerApp: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        pickColor()
    }

    private func pickColor() {
        NSColorSampler().show { color in
            guard let color else {
                NSApp.terminate(nil)
                return
            }

            let hex = Self.hexString(from: color)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(hex, forType: .string)
            Self.notify(title: "Copied color", body: hex)
            print(hex)
            NSApp.terminate(nil)
        }
    }

    private static func hexString(from color: NSColor) -> String {
        let rgb = color.usingColorSpace(.sRGB) ?? color
        let red = max(0, min(255, Int(round(rgb.redComponent * 255))))
        let green = max(0, min(255, Int(round(rgb.greenComponent * 255))))
        let blue = max(0, min(255, Int(round(rgb.blueComponent * 255))))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private static func notify(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        NSUserNotificationCenter.default.deliver(notification)
    }
}

let app = NSApplication.shared
let delegate = ColorPickerApp()
app.delegate = delegate
app.run()
