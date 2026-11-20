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
    private var iface: CWInterface? { client.interface() }

    override init() {
        super.init()
        location.delegate = self
        updateAuth()
        refresh()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuth()
        if locationOK { scan() }
    }

    private func updateAuth() {
        let s = location.authorizationStatus
        locationOK = s == .authorizedAlways || s == .authorized
    }

    func requestLocation() { location.requestWhenInUseAuthorization(); location.startUpdatingLocation(); location.stopUpdatingLocation() }

    func refresh() {
        powered = iface?.powerOn() ?? false
        current = iface?.ssid()
    }

    func setPower(_ on: Bool) {
        do { try iface?.setPower(on); error = nil } catch { self.error = "Couldn't turn Wi-Fi \(on ? "on" : "off")" }
        refresh()
        if on { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.scan() } } else { networks = [] }
    }

    /// Known networks are the ones saved in the system Wi-Fi settings.
    private var knownSSIDs: Set<String> {
        let profiles = iface?.configuration()?.networkProfiles.array as? [CWNetworkProfile] ?? []
        return Set(profiles.compactMap(\.ssid))
    }

    func scan() {
        guard powered, !scanning else { return }
        if !locationOK { requestLocation() }
        scanning = true
        let known = knownSSIDs
        let iface = self.iface
        bg {
            let found = (try? iface?.scanForNetworks(withSSID: nil)) ?? []
            var best: [String: CWNetwork] = [:]
            for n in found {
                guard let s = n.ssid, !s.isEmpty else { continue }
                if let b = best[s], b.rssiValue >= n.rssiValue { continue }
                best[s] = n
            }
            let list = best.values.map { n in
                Network(ssid: n.ssid!, rssi: n.rssiValue, secure: !n.supportsSecurity(.none), known: known.contains(n.ssid!))
            }.sorted { ($0.known ? 1 : 0, $0.rssi) > ($1.known ? 1 : 0, $1.rssi) }
            main { self.networks = list; self.scanning = false; self.refresh() }
        }
    }

    /// Joins a network. Saved networks use the password stored by macOS; for new secured ones
    /// we show a password box first.
    func join(_ n: Network, password: String? = nil) {
        if n.secure, !n.known, password == nil { askPasswordFor = n.ssid; return }
        joining = n.ssid; error = nil; askPasswordFor = nil
        let iface = self.iface
        bg {
            var err: String?
            if let net = (try? iface?.scanForNetworks(withSSID: n.ssid.data(using: .utf8)))?.first {
                do { try iface?.associate(to: net, password: password) }
                catch {
                    // Fall back to networksetup, which can read saved passwords from the keychain.
                    let dev = iface?.interfaceName ?? "en0"
                    let pw = password.map { " '" + $0.replacingOccurrences(of: "'", with: "'\\''") + "'" } ?? ""
                    let out = sh("networksetup -setairportnetwork \(dev) '\(n.ssid.replacingOccurrences(of: "'", with: "'\\''"))'\(pw) 2>&1")
                    if !out.isEmpty { err = n.known ? "Couldn't join \(n.ssid)" : "Wrong password or couldn't join" }
                }
            } else { err = "\(n.ssid) is out of range" }
            main {
                self.joining = nil; self.error = err; self.refresh()
                if err != nil, n.secure { self.askPasswordFor = n.ssid }
            }
        }
    }

    func disconnect() { iface?.disassociate(); refresh() }

    static func bars(_ rssi: Int) -> String {
        rssi > -60 ? "wifi" : rssi > -72 ? "wifi" : "wifi.exclamationmark"
    }
}

struct WiFiSection: View {
    @ObservedObject var wifi: WiFiModel
    @State private var password = ""
    @FocusState private var pwFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Image(systemName: wifi.powered ? "wifi" : "wifi.slash")
                    .foregroundStyle(wifi.powered ? Mocha.green : Mocha.red).frame(width: 18)
                Text("Wi-Fi").foregroundStyle(Mocha.subtext)
                Spacer()
                if wifi.powered {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .bold))
                        .foregroundStyle(wifi.scanning ? Mocha.overlay0 : Mocha.subtext)
                        .rotationEffect(.degrees(wifi.scanning ? 180 : 0))
                        .animation(wifi.scanning ? .linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: wifi.scanning)
                        .onTapGesture { wifi.scan() }
                }
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
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(wifi.networks) { n in network(n) }
                    }
                }
                .frame(maxHeight: 190)
                if let e = wifi.error {
                    Text(e).font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.red).padding(.horizontal, 42)
                }
            }
        }
        .onAppear { wifi.refresh(); wifi.scan() }
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
                if wifi.joining == n.ssid { ProgressView().controlSize(.mini) }
                else if connected { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Mocha.green) }
                if n.secure { Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(Mocha.overlay0) }
            }
            .padding(.leading, 28).padding(.trailing, 14).frame(height: 26)
            .background(RoundedRectangle(cornerRadius: 7).fill(connected ? Mocha.surface0 : .clear).padding(.horizontal, 6))
            .contentShape(Rectangle())
            .onTapGesture {
                if connected { return }
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
                .padding(.leading, 54).padding(.trailing, 14)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    DispatchQueue.main.async { pwFocused = true }
                }
            }
        }
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
