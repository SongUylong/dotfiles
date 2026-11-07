// Native AppKit overlay that mirrors the SketchyBar layout and shows running
// app icons inside each yabai workspace pill.
import AppKit
import Foundation

@discardableResult
func run(_ path: String, _ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    let out = Pipe()
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    do { try p.run() } catch { return "" }
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

@discardableResult
func shell(_ command: String) -> String {
    run("/bin/zsh", ["-lc", command])
}

struct Workspace {
    let id: Int
    let focused: Bool
    let apps: [(pid: pid_t, icon: NSImage)]
}

struct BarData {
    var workspaces: [Workspace] = []
    var clock = ""
    var battery = "--%"
    var volume = "--%"
    var muted = false
    var micOn = false
    var wifi = "Wi-Fi"
    var cpu = "--%"
    var memory = "--GB"
    var disk = "--GB"
    var temperature = "--°C"
    var power = "--W"
    var frontApp = ""
}

enum HitAction: Equatable {
    case focus(Int)
    case activate(pid_t, Int)
    case mic
    case volume
    case wifi
    case bluetooth
}

final class BarView: NSView {
    private(set) var data = BarData()
    private var hitRegions: [(NSRect, HitAction)] = []
    weak var owner: BarController?
    private let pillColor = NSColor(calibratedRed: 0x3c / 255, green: 0x3e / 255, blue: 0x4f / 255, alpha: 1)
    private let activeColor = NSColor(calibratedRed: 0x1e / 255, green: 0x1e / 255, blue: 0x2e / 255, alpha: 1)
    private let blue = NSColor(calibratedRed: 0x89 / 255, green: 0xb4 / 255, blue: 0xfa / 255, alpha: 1)
    private let white = NSColor.white
    private let font = NSFont.systemFont(ofSize: 12, weight: .semibold)

    override var isFlipped: Bool { false }

    func update(_ newData: BarData) {
        data = newData
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedWhite: 0, alpha: 0.25).setFill()
        bounds.fill()
        hitRegions.removeAll(keepingCapacity: true)

        let pillHeight: CGFloat = 28
        let y = (bounds.height - pillHeight) / 2
        var left: CGFloat = 10

        for space in data.workspaces {
            let iconCount = min(space.apps.count, 4)
            let extra = max(0, space.apps.count - iconCount)
            let width = max(38, 30 + CGFloat(iconCount) * 20 + (extra > 0 ? 20 : 0))
            let rect = NSRect(x: left, y: y, width: width, height: pillHeight)
            rounded(rect, color: space.focused ? activeColor : pillColor, radius: 14)
            if space.focused {
                let border = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75), xRadius: 13, yRadius: 13)
                border.lineWidth = 1.5
                blue.setStroke()
                border.stroke()
            }
            hitRegions.append((rect, .focus(space.id)))

            let iconY = y + (pillHeight - 17) / 2
            var iconX = left + 7
            for app in space.apps.prefix(iconCount) {
                let iconRect = NSRect(x: iconX, y: iconY, width: 17, height: 17)
                app.icon.draw(in: iconRect)
                hitRegions.append((iconRect.insetBy(dx: -2, dy: -4), .activate(app.pid, space.id)))
                iconX += 20
            }
            if extra > 0 {
                text("+\(extra)", at: NSPoint(x: iconX, y: y + 7), color: white, font: NSFont.systemFont(ofSize: 10, weight: .medium))
            } else if space.apps.isEmpty {
                text("\(space.id)", at: NSPoint(x: left + 14, y: y + 7), color: space.focused ? blue : white, font: font)
            }
            left += width + 5
        }

        // Left-side items from sketchybarrc.
        left += 3
        left = chip("♥ Potato", x: left, y: y, action: nil)
        left = chip(data.micOn ? "Mic ON" : "Mic OFF", x: left, y: y, color: data.micOn ? NSColor.systemGreen : NSColor.systemRed, action: .mic)
        left = chip("ϟ \(data.power)", x: left, y: y, action: nil)
        left = chip("Temp \(data.temperature)", x: left, y: y, action: nil)
        left = chip("Disk \(data.disk)", x: left, y: y, action: nil)

        // Right-side items, laid out right-to-left.
        var right = bounds.width - 10
        right = rightChip(data.clock, right: right, y: y, action: nil)
        right = rightChip("Vol \(data.muted ? "Muted" : data.volume)", right: right, y: y, action: .volume)
        right = rightChip("Bat \(data.battery)", right: right, y: y, action: nil)
        right = rightChip("Wi-Fi \(data.wifi)", right: right, y: y, action: .wifi)
        right = rightChip("BT", right: right, y: y, action: .bluetooth)
        right = rightChip("CPU \(data.cpu)  RAM \(data.memory)", right: right, y: y, action: nil)
    }

    private func chip(_ title: String, x: CGFloat, y: CGFloat, color: NSColor = .white, action: HitAction?) -> CGFloat {
        let width = textWidth(title) + 20
        let rect = NSRect(x: x, y: y, width: width, height: 28)
        rounded(rect, color: pillColor, radius: 8)
        text(title, at: NSPoint(x: x + 10, y: y + 8), color: color, font: font)
        if let action { hitRegions.append((rect, action)) }
        return x + width + 6
    }

    private func rightChip(_ title: String, right: CGFloat, y: CGFloat, action: HitAction?) -> CGFloat {
        let width = textWidth(title) + 20
        let x = right - width
        let rect = NSRect(x: x, y: y, width: width, height: 28)
        rounded(rect, color: pillColor, radius: 8)
        text(title, at: NSPoint(x: x + 10, y: y + 8), color: white, font: font)
        if let action { hitRegions.append((rect, action)) }
        return x - 6
    }

    private func rounded(_ rect: NSRect, color: NSColor, radius: CGFloat) {
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }

    private func text(_ value: String, at point: NSPoint, color: NSColor, font: NSFont) {
        (value as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private func textWidth(_ value: String) -> CGFloat {
        (value as NSString).size(withAttributes: [.font: font]).width
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let (_, action) = hitRegions.reversed().first(where: { $0.0.contains(point) }) else { return }
        switch action {
        case .focus(let id):
            _ = shell("yabai -m space --focus \(id)")
        case .activate(let pid, let space):
            _ = shell("yabai -m space --focus \(space)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NSRunningApplication(processIdentifier: pid)?.activate()
            }
        case .mic:
            let current = Int(shell("osascript -e 'input volume of (get volume settings)'")) ?? 0
            _ = shell("osascript -e 'set volume input volume \(current == 0 ? 100 : 0)'")
        case .volume:
            _ = shell(data.muted ? "osascript -e 'set volume without output muted'" : "osascript -e 'set volume with output muted'")
        case .wifi:
            _ = shell("open 'x-apple.systempreferences:com.apple.preference.network?Wi-Fi'")
        case .bluetooth:
            _ = shell("open 'x-apple.systempreferences:com.apple.preferences.Bluetooth'")
        }
        owner?.refresh()
    }

    override func scrollWheel(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard hitRegions.contains(where: { $0.1 == .volume && $0.0.contains(point) }) else { return }
        let current = Int(shell("osascript -e 'output volume of (get volume settings)'")) ?? 0
        let next = max(0, min(100, current + (event.deltaY > 0 ? 5 : -5)))
        _ = shell("osascript -e 'set volume output volume \(next)'")
        owner?.refresh()
    }
}

final class BarWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class BarController: NSObject {
    private let window: BarWindow
    private let view: BarView
    private var timer: Timer?
    private var iconCache: [pid_t: NSImage] = [:]

    override init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let height: CGFloat = 40
        window = BarWindow(contentRect: NSRect(x: screen.frame.minX, y: screen.frame.maxY - height,
                                               width: screen.frame.width, height: height),
                           styleMask: .borderless, backing: .buffered, defer: false)
        view = BarView(frame: NSRect(x: 0, y: 0, width: screen.frame.width, height: height))
        super.init()
        view.owner = self
        window.contentView = view
        window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.orderFrontRegardless()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appChanged),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    @objc private func appChanged() { refresh() }

    func refresh() {
        var result = BarData()
        let spacesJSON = json("yabai -m query --spaces")
        let windowsJSON = json("yabai -m query --windows")
        let focused = (spacesJSON as? [[String: Any]])?.first(where: { $0["has-focus"] as? Bool == true })?["index"] as? Int ?? 1
        let windows = windowsJSON as? [[String: Any]] ?? []

        result.workspaces = (spacesJSON as? [[String: Any]] ?? [])
            .filter { ($0["index"] as? Int ?? 999) <= 5 }
            .sorted { ($0["index"] as? Int ?? 0) < ($1["index"] as? Int ?? 0) }
            .map { space in
                let id = space["index"] as? Int ?? 1
                var seen = Set<pid_t>()
                let apps: [(pid_t, NSImage)] = windows.compactMap { item in
                    guard item["space"] as? Int == id,
                          (item["is-minimized"] as? Bool ?? false) == false,
                          let number = item["pid"] as? Int else { return nil }
                    let pid = pid_t(number)
                    guard seen.insert(pid).inserted else { return nil }
                    guard let icon = appIcon(pid) else { return nil }
                    return (pid, icon)
                }
                return Workspace(id: id, focused: id == focused, apps: apps)
            }

        let now = DateFormatter()
        now.dateFormat = "EEE dd MMM HH:mm"
        result.clock = now.string(from: Date())
        let batteryText = run("/usr/bin/pmset", ["-g", "batt"])
        result.battery = batteryText.range(of: #"\d+%"#, options: .regularExpression)
            .map { String(batteryText[$0]) } ?? "--%"
        let volumeText = shell("osascript -e 'output volume of (get volume settings)'")
        result.volume = volumeText.isEmpty ? "--%" : "\(volumeText)%"
        result.muted = shell("osascript -e 'output muted of (get volume settings)'") == "true"
        let micVolume = Int(shell("osascript -e 'input volume of (get volume settings)'")) ?? 0
        result.micOn = micVolume > 0
        result.wifi = wifiName()
        result.cpu = shell("top -l 1 -n 0 | awk '/CPU usage/ {gsub(/%/,\"\",$3); print $3; exit}'")
        if result.cpu.isEmpty { result.cpu = "--" }
        result.memory = memoryUsage()
        result.disk = shell("df -g /System/Volumes/Data | awk 'NR==2 {print $4 \"GB\"}'")
        if result.disk.isEmpty { result.disk = "--GB" }
        let temp = NSHomeDirectory() + "/.config/sketchybar/plugins/helpers/mac_temp"
        let tempText = run(temp, [])
        result.temperature = tempText.isEmpty ? "--°C" : tempText
        let batt = run("/usr/bin/pmset", ["-g", "batt"])
        result.power = batt.contains("AC Power") ? "AC" : "Battery"
        result.frontApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
        view.update(result)
    }

    private func json(_ command: String) -> Any? {
        let text = shell(command)
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private func appIcon(_ pid: pid_t) -> NSImage? {
        if let cached = iconCache[pid] { return cached }
        guard let image = NSRunningApplication(processIdentifier: pid)?.icon else { return nil }
        iconCache[pid] = image
        return image
    }

    private func wifiName() -> String {
        let ports = run("/usr/sbin/networksetup", ["-listallhardwareports"])
        let lines = ports.components(separatedBy: .newlines)
        for i in lines.indices where lines[i].contains("Hardware Port: Wi-Fi") {
            if i + 1 < lines.count,
               let device = lines[i + 1].components(separatedBy: ": ").last {
                let status = run("/usr/sbin/networksetup", ["-getairportnetwork", device])
                if let colon = status.firstIndex(of: ":") {
                    let name = status[status.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty && !name.contains("not associated") { return name.components(separatedBy: .whitespaces).first ?? "Wi-Fi" }
                }
            }
        }
        return "Off"
    }

    private func memoryUsage() -> String {
        let text = run("/usr/bin/vm_stat", [])
        func pages(_ name: String) -> Int {
            guard let range = text.range(of: #"\#(name):\s+(\d+)"#, options: .regularExpression),
                  let value = text[range].split(whereSeparator: { !$0.isNumber }).last,
                  let number = Int(value) else { return 0 }
            return number
        }
        let pageSizeLine = text.components(separatedBy: .newlines).first { $0.contains("page size of") } ?? ""
        let pageSize = pageSizeLine.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }.first ?? 4096
        let gb = Double((pages("Pages active") + pages("Pages wired down")) * pageSize) / 1_073_741_824
        return String(format: "%.1fGB", gb)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = BarController()
app.run()
