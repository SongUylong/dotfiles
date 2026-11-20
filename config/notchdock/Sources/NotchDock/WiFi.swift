import CoreLocation
import CoreWLAN
import SwiftUI

/// Wi-Fi control for the controls dropdown: power, nearby networks, join.
/// macOS hides network names from apps without Location permission, so we ask for it once.
final class WiFiModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    struct Network: Identifiable, Equatable {
        var id: String { ssid }
        let ssid: String
        let rssi: Int
        let secure: Bool
        let known: Bool
    }

    @Published var powered = false
    @Published var current: String?
    @Published var networks: [Network] = []
    @Published var scanning = false
    @Published var joining: String?
    @Published var askPasswordFor: String?
    @Published var error: String?
    @Published var locationOK = false

    private let client = CWWiFiClient.shared()
    private let location = CLLocationManager()
    private let q = DispatchQueue(label: "notchdock.wifi", qos: .userInitiated)
    private var iface: CWInterface? { client.interface() }
    private var lastScan = Date.distantPast

    override init() {
        super.init()
        location.delegate = self
        updateAuth()
        refresh()
        if location.authorizationStatus == .notDetermined { requestLocation() }
        // Debug hook: `notifyutil`-style trigger to join a saved network by name from the shell.
        DistributedNotificationCenter.default().addObserver(forName: .init("com.eric.notchdock.debug.wifijoin"), object: nil, queue: .main) { [weak self] note in
            guard let self, let ssid = note.object as? String else { return }
            self.join(self.networks.first { $0.ssid == ssid } ?? Network(ssid: ssid, rssi: -50, secure: true, known: true))
        }
        scan(force: true)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuth()
        if locationOK { scan(force: true) }
    }

    private func updateAuth() {
        let s = location.authorizationStatus
        let ok = s == .authorizedAlways || s == .authorized
        if ok != locationOK { locationOK = ok }
    }

    func requestLocation() {
        NSApp.activate(ignoringOtherApps: true)   // the prompt only shows for an active app
        location.requestAlwaysAuthorization(); location.requestWhenInUseAuthorization(); location.startUpdatingLocation(); location.stopUpdatingLocation() }

    /// Reads power and the current network off the main thread; publishes only what changed.
    func refresh() {
        q.async {
            let p = self.iface?.powerOn() ?? false
            let c = self.iface?.ssid()
            main {
                if p != self.powered { self.powered = p }
                if c != self.current { self.current = c }
            }
        }
    }

    func setPower(_ on: Bool) {
        powered = on; error = nil          // flip the switch immediately
        if !on { networks = [] }
        q.async {
            var failed = false
            do { try self.iface?.setPower(on) } catch { failed = true }
            main {
                if failed { self.powered = !on; self.error = "Couldn't turn Wi-Fi \(on ? "on" : "off")" }
                self.refresh()
                if on && !failed { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.scan(force: true) } }
            }
        }
    }

    /// Scans in the background. The cached list stays on screen meanwhile, so opening the
    /// dropdown is instant; a rescan happens at most every 15 s unless forced.
    func scan(force: Bool = false) {
        guard powered || force, !scanning else { return }
        if !force, Date().timeIntervalSince(lastScan) < 15 { refresh(); return }
        if !locationOK { requestLocation() }
        scanning = true
        q.async {
            let iface = self.iface
            guard iface?.powerOn() == true else { main { self.scanning = false; self.refresh() }; return }
            let profiles = iface?.configuration()?.networkProfiles.array as? [CWNetworkProfile] ?? []
            let known = Set(profiles.compactMap(\.ssid))
            let cur = iface?.ssid()
            let found = (try? iface?.scanForNetworks(withSSID: nil)) ?? []
            var best: [String: CWNetwork] = [:]
            for n in found {
                guard let s = n.ssid, !s.isEmpty else { continue }
                if let b = best[s], b.rssiValue >= n.rssiValue { continue }
                best[s] = n
            }
            // Stable order: current, saved, then others, alphabetically (signal strength jitters).
            let list = best.values.map { n in
                Network(ssid: n.ssid!, rssi: n.rssiValue, secure: !n.supportsSecurity(.none), known: known.contains(n.ssid!))
            }.sorted {
                let a = ($0.ssid == cur ? 0 : $0.known ? 1 : 2), b = ($1.ssid == cur ? 0 : $1.known ? 1 : 2)
                return a != b ? a < b : $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending
            }
            main {
                self.lastScan = Date()
                if list.map(\.ssid) != self.networks.map(\.ssid) || list != self.networks {
                    withAnimation(.easeOut(duration: 0.2)) { self.networks = list }
                }
                self.scanning = false
                self.refresh()
            }
        }
    }

    /// Joins a network. Saved networks use the password stored by macOS; for new secured ones
    /// we show a password box first.
    func join(_ n: Network, password: String? = nil) {
        if n.secure, !n.known, password == nil { withAnimation(.easeOut(duration: 0.15)) { askPasswordFor = n.ssid }; return }
        joining = n.ssid; error = nil; askPasswordFor = nil
        q.async {
            let iface = self.iface
            let dev = iface?.interfaceName ?? "en0"
            func joined() -> Bool {
                for _ in 0..<40 { if iface?.ssid() == n.ssid { return true }; Thread.sleep(forTimeInterval: 0.5) }
                return false
            }
            // 1) CoreWLAN; 2) networksetup, which uses the keychain password for saved networks.
            // Success is judged by actually being on the network, not by error output.
            var ok = false
            wlog("join \(n.ssid) known=\(n.known) secure=\(n.secure) pw=\(password != nil) loc=\(self.location.authorizationStatus.rawValue) cur=\(iface?.ssid() ?? "nil")")
            if n.known && password == nil {
                ok = Self.joinViaControlCenter(n.ssid) && joined()
                wlog("control center joined=\(ok)")
            }
            if !ok { do {
                let nets = try iface?.scanForNetworks(withSSID: n.ssid.data(using: .utf8)) ?? []
                wlog("scan-by-ssid found \(nets.count)")
                if let net = nets.first {
                    try iface?.associate(to: net, password: password)
                    wlog("associate returned ok")
                    ok = joined()
                    wlog("after associate joined=\(ok) cur=\(iface?.ssid() ?? "nil")")
                }
            } catch { wlog("corewlan error: \(error as NSError)") } }
            if !ok {
                let q1 = { (x: String) in "'" + x.replacingOccurrences(of: "'", with: "'\\''") + "'" }
                let out = sh("networksetup -setairportnetwork \(dev) \(q1(n.ssid))\(password.map { " " + q1($0) } ?? "") 2>&1")
                wlog("networksetup said: [\(out)]")
                ok = joined()
                wlog("after networksetup joined=\(ok) cur=\(iface?.ssid() ?? "nil")")
            }
            let cur = iface?.ssid()
            main {
                self.joining = nil
                self.error = ok ? nil : (password != nil ? "Couldn't join \(n.ssid) — check the password" : "Couldn't join \(n.ssid)")
                if cur != self.current { self.current = cur }
                if !ok, n.secure { self.askPasswordFor = n.ssid }
            }
        }
    }

    /// macOS only lets the system Wi-Fi menu use saved passwords, so for saved networks we open
    /// Control Center's Wi-Fi menu through Accessibility, press the network and close the menu.
    static func joinViaControlCenter(_ ssid: String) -> Bool {
        guard AXIsProcessTrusted(),
              let cc = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.controlcenter").first
        else { wlog("cc: not trusted or no ControlCenter"); return false }
        let app = AXUIElementCreateApplication(cc.processIdentifier)
        guard let bar: AXUIElement = ax(app, "AXExtrasMenuBar") else { wlog("cc: no extras bar"); return false }
        let wifiItem = axChildren(bar).first { el in
            let id: String = ax(el, "AXIdentifier") ?? ""
            let d: String = ax(el, kAXDescriptionAttribute) ?? ""
            return id.contains("wifi") || d.lowercased().contains("wi-fi") || d.lowercased().contains("wifi")
        }
        guard let wifiItem else { wlog("cc: no wifi item: " + axChildren(bar).map { (ax($0, "AXIdentifier") as String?) ?? "?" }.joined(separator: ",")); return false }
        AXUIElementPerformAction(wifiItem, kAXPressAction as CFString)
        defer { // close the menu again
            Thread.sleep(forTimeInterval: 0.3)
            if let w: [AXUIElement] = ax(app, kAXWindowsAttribute), !w.isEmpty { AXUIElementPerformAction(wifiItem, kAXPressAction as CFString) }
        }
        func find(_ el: AXUIElement, _ depth: Int) -> AXUIElement? {
            if depth > 12 { return nil }
            let t: String = ax(el, kAXTitleAttribute) ?? ""
            let d: String = ax(el, kAXDescriptionAttribute) ?? ""
            let id: String = ax(el, "AXIdentifier") ?? ""
            if t == ssid || d == ssid || id == "wifi-network-\(ssid)" { return el }
            for c in axChildren(el) { if let f = find(c, depth + 1) { return f } }
            return nil
        }
        for _ in 0..<20 {   // the network list fills in over a second or two
            Thread.sleep(forTimeInterval: 0.25)
            for w in (ax(app, kAXWindowsAttribute) as [AXUIElement]?) ?? [] {
                if let el = find(w, 0) {
                    var target = el   // press the row (button/checkbox), not a text label inside it
                    let role: String = ax(el, kAXRoleAttribute) ?? ""
                    if role == kAXStaticTextRole, let p: AXUIElement = ax(el, kAXParentAttribute) { target = p }
                    let r = AXUIElementPerformAction(target, kAXPressAction as CFString)
                    wlog("cc: pressed \(ssid) role=\(role) result=\(r.rawValue)")
                    return r == .success
                }
            }
        }
        wlog("cc: network \(ssid) not found in menu")
        return false
    }

    func disconnect() { q.async { self.iface?.disassociate(); self.refresh() } }

    static func bars(_ rssi: Int) -> String {
        rssi > -60 ? "wifi" : rssi > -72 ? "wifi" : "wifi.exclamationmark"
    }
}

struct WiFiSection: View {
    @ObservedObject var wifi: WiFiModel
    @State private var password = ""
    @FocusState private var pwFocused: Bool
    static let rowH: CGFloat = 27

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Image(systemName: wifi.powered ? "wifi" : "wifi.slash")
                    .foregroundStyle(wifi.powered ? Mocha.green : Mocha.red).frame(width: 18)
                Text("Wi-Fi").foregroundStyle(Mocha.subtext)
                Spacer()
                ZStack {   // fixed slot so the header never shifts
                    if wifi.scanning { ProgressView().controlSize(.mini) }
                    else if wifi.powered {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Mocha.subtext)
                            .contentShape(Rectangle())
                            .onTapGesture { wifi.scan(force: true) }
                    }
                }.frame(width: 18, height: 18)
                ToggleSwitch(on: wifi.powered) { wifi.setPower(!wifi.powered) }
            }
            .font(.system(size: 12.5, weight: .semibold))
            .padding(.horizontal, 14).frame(height: 30)

            if wifi.powered {
                if !wifi.locationOK {
                    Text("Allow Location for NotchDock to see network names")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.peach)
                        .padding(.horizontal, 42).frame(height: 22)
                        .onTapGesture {
                            wifi.requestLocation()
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
                        }
                }
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(wifi.networks) { n in network(n) }
                    }
                }
                .frame(height: listHeight)
                .animation(.easeOut(duration: 0.2), value: listHeight)
                if let e = wifi.error {
                    Text(e).font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.red).padding(.horizontal, 42)
                }
            }
        }
        .animation(.easeOut(duration: 0.18), value: wifi.powered)
        .onAppear { wifi.scan() }
    }

    private var listHeight: CGFloat {
        let rows = CGFloat(min(wifi.networks.count, 7))
        let pw: CGFloat = wifi.askPasswordFor != nil && wifi.networks.count <= 7 ? 30 : 0
        return max(wifi.networks.isEmpty ? Self.rowH : 0, rows * Self.rowH + pw)
    }

    private func network(_ n: WiFiModel.Network) -> some View {
        let connected = wifi.current == n.ssid
        return VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "wifi").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(n.rssi > -67 ? Mocha.text : Mocha.overlay0).frame(width: 18)
                Text(n.ssid).font(.system(size: 12.5, weight: connected ? .bold : .medium))
                    .foregroundStyle(connected ? Mocha.green : Mocha.text).lineLimit(1)
                Spacer()
                ZStack {
                    if wifi.joining == n.ssid { ProgressView().controlSize(.mini) }
                    else if connected { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Mocha.green) }
                }.frame(width: 16)
                Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(Mocha.overlay0)
                    .opacity(n.secure ? 1 : 0).frame(width: 10)
            }
            .padding(.leading, 28).padding(.trailing, 14).frame(height: Self.rowH)
            .background(RowHover(active: connected))
            .contentShape(Rectangle())
            .onTapGesture {
                if connected || wifi.joining != nil { return }
                password = ""
                wifi.join(n)
            }
            if wifi.askPasswordFor == n.ssid {
                HStack(spacing: 6) {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(.horizontal, 8).frame(height: 24)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Mocha.surface0))
                        .focused($pwFocused)
                        .onSubmit { wifi.join(n, password: password) }
                    Text("Join").font(.system(size: 12, weight: .bold)).foregroundStyle(Mocha.base)
                        .padding(.horizontal, 10).frame(height: 24)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Mocha.green))
                        .onTapGesture { wifi.join(n, password: password) }
                }
                .padding(.leading, 54).padding(.trailing, 14).padding(.bottom, 4)
                .transition(.opacity)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    DispatchQueue.main.async { pwFocused = true }
                }
            }
        }
    }
}

/// Row background with a hover highlight, shared by the Wi-Fi and Bluetooth lists.
struct RowHover: View {
    let active: Bool
    @State private var hover = false
    var body: some View {
        RoundedRectangle(cornerRadius: 7)
            .fill(active ? Mocha.surface0 : hover ? Mocha.surface0.opacity(0.55) : .clear)
            .padding(.horizontal, 6)
            .onHover { hover = $0 }
            .animation(.easeOut(duration: 0.1), value: hover)
    }
}

/// Small switch drawn in the bar's style (not the system control).
struct ToggleSwitch: View {
    let on: Bool
    let action: () -> Void
    var body: some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule().fill(on ? Mocha.green : Mocha.surface1).frame(width: 30, height: 18)
            Circle().fill(Mocha.text).frame(width: 14, height: 14).padding(2)
        }
        .animation(.easeOut(duration: 0.15), value: on)
        .contentShape(Capsule())
        .onTapGesture(perform: action)
    }
}

/// Appends a line to ~/.cache/notchdock/wifi.log (never logs passwords).
func wlog(_ msg: String) {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache/notchdock/wifi.log")
    let line = "\(Date()) \(msg)\n"
    if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close() }
    else { try? Data(line.utf8).write(to: url) }
}
