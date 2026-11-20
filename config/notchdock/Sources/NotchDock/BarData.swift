import AppKit
import Combine
import Darwin

// Catppuccin Mocha, same palette as the old SketchyBar config.
enum Mocha {
    static let base = Color(hex: 0x1e1e2e), surface0 = Color(hex: 0x313244), surface1 = Color(hex: 0x45475a)
    static let overlay0 = Color(hex: 0x6c7086), text = Color(hex: 0xcdd6f4), subtext = Color(hex: 0xa6adc8)
    static let mauve = Color(hex: 0xcba6f7), red = Color(hex: 0xf38ba8), peach = Color(hex: 0xfab387)
    static let yellow = Color(hex: 0xf9e2af), green = Color(hex: 0xa6e3a1), teal = Color(hex: 0x94e2d5)
    static let blue = Color(hex: 0x89b4fa), lavender = Color(hex: 0xb4befe)
}

import SwiftUI
extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}

/// Runs a shell command and returns trimmed stdout.
@discardableResult
func sh(_ cmd: String, env: [String: String] = [:]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = ["-c", cmd]
    var e = ProcessInfo.processInfo.environment
    e["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + (e["PATH"] ?? "")
    e.merge(env) { $1 }
    p.environment = e
    let out = Pipe()
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    do { try p.run() } catch { return "" }
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
}

func bg(_ work: @escaping () -> Void) { DispatchQueue.global(qos: .utility).async(execute: work) }
func main(_ work: @escaping () -> Void) { DispatchQueue.main.async(execute: work) }

struct SpaceInfo: Identifiable, Equatable {
    let id: Int
    var focused: Bool
    var apps: [String]   // app names, front-most first
}

struct UsageMeter: Equatable { var pct: Double?; var reset: Date? }
struct AIAccount: Identifiable, Equatable {
    let id: String
    var title: String
    var fiveHour = UsageMeter()
    var weekly = UsageMeter()
    var extra: [String] = []
}

struct MediaInfo: Equatable { var title: String; var artist: String; var bundle: String; var playing: Bool }

/// All live data for the top bar. Each source refreshes on its own timer, off the main thread.
final class BarData: ObservableObject {
    @Published var spaces: [SpaceInfo] = []
    @Published var frontApp = ""
    @Published var now = Date()
    @Published var batteryPct = 0
    @Published var charging = false
    @Published var caffeinated = false
    @Published var cpu = 0
    @Published var ram = 0
    @Published var temp = "--"
    @Published var diskFree = "--"
    @Published var charger = "--"
    @Published var powerDraw = "--"
    @Published var volume = 0
    @Published var muted = false
    @Published var mic = 0
    @Published var wifi = ""
    @Published var ip = ""
    @Published var btDevices: [String] = []
    @Published var media: MediaInfo?
    @Published var ai: [AIAccount] = []
    @Published var aiUpdated: Date?

    private var timers: [Timer] = []
    private var lastCPU: host_cpu_load_info?
    private var caffeinatePID: Int32?
    private let cache = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache/sketchybar")
    private let pluginDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/sketchybar/plugins")

    init() {
        every(1.5) { [weak self] in self?.refreshSpaces() }
        every(15) { [weak self] in self?.now = Date() }
        every(60) { [weak self] in self?.refreshBattery() }
        every(5) { [weak self] in self?.refreshStats() }
        every(10) { [weak self] in self?.refreshSlowStats() }
        every(3) { [weak self] in self?.refreshMedia() }
        every(20) { [weak self] in self?.refreshControls() }
        every(120) { [weak self] in self?.refreshAI(fetch: true) }
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] n in
            let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.frontApp = app?.localizedName ?? ""
            self?.refreshSpaces()
        }
        nc.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refreshSpaces()
        }
        frontApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
        caffeinated = existingCaffeinate() != nil
        [refreshSpaces, refreshBattery, refreshStats, refreshSlowStats, refreshMedia, refreshControls].forEach { $0() }
        refreshAI(fetch: false)
        refreshAI(fetch: true)
    }

    private func every(_ s: TimeInterval, _ f: @escaping () -> Void) {
        let t = Timer(timeInterval: s, repeats: true) { _ in f() }
        t.tolerance = s * 0.2
        RunLoop.main.add(t, forMode: .common)
        timers.append(t)
    }

    // MARK: yabai spaces

    func refreshSpaces() {
        bg {
            let raw = sh("yabai -m query --spaces 2>/dev/null; echo '@@'; yabai -m query --windows 2>/dev/null")
            let parts = raw.components(separatedBy: "@@")
            guard parts.count == 2,
                  let sp = try? JSONSerialization.jsonObject(with: Data(parts[0].utf8)) as? [[String: Any]],
                  let wins = try? JSONSerialization.jsonObject(with: Data(parts[1].utf8)) as? [[String: Any]] else { return }
            var result: [SpaceInfo] = []
            for s in sp {
                guard let idx = s["index"] as? Int, idx <= 5 else { continue }
                var apps: [String] = []
                for w in wins where (w["space"] as? Int) == idx && (w["is-minimized"] as? Bool) != true {
                    if let a = w["app"] as? String, !apps.contains(a) {
                        if (w["has-focus"] as? Bool) == true { apps.insert(a, at: 0) } else { apps.append(a) }
                    }
                }
                result.append(SpaceInfo(id: idx, focused: (s["has-focus"] as? Bool) == true, apps: apps))
            }
            main { if self.spaces != result { self.spaces = result } }
        }
    }

    func focusSpace(_ id: Int) {
        bg { sh("yabai -m space --focus \(id)"); self.refreshSpaces() }
    }

    // MARK: battery / caffeinate

    func refreshBattery() {
        bg {
            let s = sh("pmset -g batt")
            let pct = Int(s.range(of: #"\d+(?=%)"#, options: .regularExpression).map { String(s[$0]) } ?? "") ?? 0
            let charging = s.contains("AC Power")
            main { self.batteryPct = pct; self.charging = charging }
        }
    }

    private var caffeinatePIDFile: URL { cache.appendingPathComponent("caffeinate.pid") }

    private func existingCaffeinate() -> Int32? {
        guard let s = try? String(contentsOf: caffeinatePIDFile, encoding: .utf8),
              let pid = Int32(s.trimmingCharacters(in: .whitespacesAndNewlines)), kill(pid, 0) == 0 else { return nil }
        return pid
    }

    /// Same pid file as the SketchyBar plugin, so the lid-sleep LaunchDaemon keeps working.
    func toggleCaffeinate() {
        if let pid = existingCaffeinate() {
            kill(pid, SIGTERM)
            try? FileManager.default.removeItem(at: caffeinatePIDFile)
            caffeinated = false
        } else {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
            p.arguments = ["-dims"]
            try? p.run()
            try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
            try? "\(p.processIdentifier)".write(to: caffeinatePIDFile, atomically: true, encoding: .utf8)
            caffeinated = true
        }
    }

    // MARK: system stats

    func refreshStats() {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        var info = host_cpu_load_info()
        let r = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size) }
        }
        if r == KERN_SUCCESS, let last = lastCPU {
            let u = Double(info.cpu_ticks.0 - last.cpu_ticks.0), s = Double(info.cpu_ticks.1 - last.cpu_ticks.1)
            let i = Double(info.cpu_ticks.2 - last.cpu_ticks.2), n = Double(info.cpu_ticks.3 - last.cpu_ticks.3)
            let total = u + s + i + n
            if total > 0 { cpu = Int((u + s + n) / total * 100) }
        }
        lastCPU = info

        var vm = vm_statistics64()
        var vsize = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let vr = withUnsafeMutablePointer(to: &vm) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vsize)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &vsize) }
        }
        if vr == KERN_SUCCESS {
            let used = Double(vm.active_count + vm.wire_count + vm.compressor_page_count)
            let total = Double(ProcessInfo.processInfo.physicalMemory) / Double(vm_kernel_page_size)
            ram = Int(used / total * 100)
        }
    }

    func refreshSlowStats() {
        bg {
            let helper = self.pluginDir.appendingPathComponent("helpers/mac_temp").path
            let t = FileManager.default.isExecutableFile(atPath: helper) ? sh("'\(helper)'") : ""
            var disk = "--"
            if let v = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
               let free = v.volumeAvailableCapacityForImportantUsage {
                disk = String(format: "%.0f GB", Double(free) / 1e9)
            }
            let io = sh("ioreg -r -c AppleSmartBattery")
            func num(_ key: String) -> Double? {
                guard let r = io.range(of: "\"\(key)\"\\s*=\\s*(-?\\d+)", options: .regularExpression) else { return nil }
                return Double(io[r].split(separator: "=").last!.trimmingCharacters(in: .whitespaces))
            }
            let ext = io.contains("\"ExternalConnected\" = Yes")
            var charger = "0.0V"
            if ext, let r = io.range(of: #""AdapterVoltage"=(\d+)"#, options: .regularExpression),
               let mv = Double(io[r].split(separator: "=").last!) { charger = String(format: "%.1fV", mv / 1000) }
            var draw = "--W"
            if let r = io.range(of: #""SystemLoad"=(\d+)"#, options: .regularExpression),
               let mw = Double(io[r].split(separator: "=").last!), mw > 0 { draw = String(format: "%.1fW", mw / 1000) }
            else if let v = num("Voltage"), let a = num("Amperage") { draw = String(format: "%.1fW", abs(v * a) / 1e6) }
            main {
                self.temp = t.isEmpty ? "--" : t
                self.diskFree = disk; self.charger = charger; self.powerDraw = draw
            }
        }
    }

    // MARK: controls

    func refreshControls() {
        bg {
            let a = sh("osascript -e 'set s to get volume settings' -e 'return ((output volume of s) as text) & \",\" & ((output muted of s) as text) & \",\" & ((input volume of s) as text)'")
                .split(separator: ",").map(String.init)
            let dev = sh("networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}'")
            let ssid = dev.isEmpty ? "" : sh("ipconfig getsummary \(dev) | awk -F ' SSID : ' '/ SSID : / {print $2; exit}'")
            let ip = dev.isEmpty ? "" : sh("ipconfig getifaddr \(dev)")
            let bt = sh("blueutil --connected --format json 2>/dev/null")
            let devices = ((try? JSONSerialization.jsonObject(with: Data(bt.utf8))) as? [[String: Any]] ?? [])
                .compactMap { $0["name"] as? String }
            main {
                if a.count == 3 {
                    self.volume = Int(a[0]) ?? 0; self.muted = a[1] == "true"; self.mic = Int(a[2]) ?? 0
                }
                self.wifi = ssid; self.ip = ip; self.btDevices = devices
            }
        }
    }

    func setVolume(_ v: Int) {
        volume = v
        bg { sh("osascript -e 'set volume output volume \(v)'") }
    }
    func toggleMute() {
        muted.toggle()
        let m = muted
        bg { sh("osascript -e 'set volume output muted \(m)'") }
    }
    private var lastMic = 70
    func toggleMic() {
        if mic > 0 { lastMic = mic; mic = 0 } else { mic = lastMic }
        let m = mic
        bg { sh("osascript -e 'set volume input volume \(m)'") }
    }

    // MARK: media

    func refreshMedia() {
        bg {
            let s = sh("media-control get --no-artwork 2>/dev/null")
            var m: MediaInfo?
            if let o = (try? JSONSerialization.jsonObject(with: Data(s.utf8))) as? [String: Any],
               let title = o["title"] as? String, !title.isEmpty {
                m = MediaInfo(title: title, artist: o["artist"] as? String ?? "",
                              bundle: o["bundleIdentifier"] as? String ?? "", playing: o["playing"] as? Bool ?? false)
            }
            main { if self.media != m { self.media = m } }
        }
    }
    func mediaCommand(_ c: String) {
        bg { sh("media-control \(c)"); Thread.sleep(forTimeInterval: 0.3); self.refreshMedia() }
    }

    // MARK: AI usage

    /// Fetching reuses the SketchyBar ai_usage.sh script (it owns the keychain/token logic and
    /// rate-limit backoff) and writes JSON caches; this app only reads them.
    func refreshAI(fetch: Bool, force: Bool = false) {
        bg {
            let script = self.pluginDir.appendingPathComponent("ai_usage.sh").path
            if fetch, FileManager.default.fileExists(atPath: script) {
                sh("'\(script)' >/dev/null 2>&1", env: ["NAME": "ai_footer", "SENDER": force ? "mouse.clicked" : "routine"])
            }
            var accounts: [AIAccount] = []
            for (id, title) in [("personal", "Claude Personal"), ("company", "Claude Company")] {
                guard let o = self.json("claude_\(id).json") as? [String: Any] else { continue }
                var a = AIAccount(id: id, title: title)
                a.fiveHour = Self.claudeMeter(o["five_hour"]); a.weekly = Self.claudeMeter(o["seven_day"])
                accounts.append(a)
            }
            if let o = self.json("codex_usage.json") as? [String: Any], let rl = o["rate_limit"] as? [String: Any] {
                var a = AIAccount(id: "codex", title: "Codex" + ((o["plan_type"] as? String).map { " · \($0.capitalized)" } ?? ""))
                func m(_ k: String) -> UsageMeter {
                    let w = rl[k] as? [String: Any]
                    return UsageMeter(pct: (w?["used_percent"] as? NSNumber)?.doubleValue,
                                      reset: (w?["reset_at"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) })
                }
                a.fiveHour = m("primary_window"); a.weekly = m("secondary_window")
                if let r = self.json("codex_resets.json") as? [String: Any], let credits = r["credits"] as? [[String: Any]] {
                    let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    a.extra = credits.filter { ($0["status"] as? String) == "available" }.map { c in
                        let exp = (c["expires_at"] as? String).flatMap { iso.date(from: $0) }
                        return "Reset credit" + (exp.map { " · expires \(Self.left($0))" } ?? "")
                    }
                }
                accounts.append(a)
            }
            let updated = (try? self.cache.appendingPathComponent("claude_personal.json")
                .resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            main { self.ai = accounts; self.aiUpdated = updated }
        }
    }

    private func json(_ name: String) -> Any? {
        guard let d = try? Data(contentsOf: cache.appendingPathComponent(name)) else { return nil }
        return try? JSONSerialization.jsonObject(with: d)
    }

    private static func claudeMeter(_ v: Any?) -> UsageMeter {
        guard let o = v as? [String: Any] else { return UsageMeter() }
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return UsageMeter(pct: (o["utilization"] as? NSNumber)?.doubleValue,
                          reset: (o["resets_at"] as? String).flatMap { iso.date(from: $0) })
    }

    static func left(_ d: Date) -> String {
        let s = Int(d.timeIntervalSinceNow)
        if s <= 0 { return "now" }
        if s >= 86400 { return "\(s / 86400)d\(s % 86400 / 3600)h" }
        if s >= 3600 { return String(format: "%dh%02dm", s / 3600, s % 3600 / 60) }
        return "\(s / 60)m"
    }
}
