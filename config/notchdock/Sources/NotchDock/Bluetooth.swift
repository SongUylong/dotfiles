import IOBluetooth
import SwiftUI

/// Bluetooth control for the controls dropdown, through blueutil: power, paired devices, connect.
final class BluetoothModel: ObservableObject {
    struct Device: Identifiable, Equatable {
        var id: String { address }
        let name: String
        let address: String
        let connected: Bool
    }
    @Published var powered = false
    @Published var devices: [Device] = []
    @Published var busy: String?
    @Published var error: String?
    private let q = DispatchQueue(label: "notchdock.bt", qos: .userInitiated)
    private var lastRefresh = Date.distantPast

    // Power on/off lives in IOBluetooth but isn't in its public headers; look it up at runtime.
    private typealias GetPower = @convention(c) () -> Int32
    private typealias SetPower = @convention(c) (Int32) -> Void
    private static let lib = dlopen("/System/Library/Frameworks/IOBluetooth.framework/IOBluetooth", RTLD_NOW)
    private static let getPower = dlsym(lib, "IOBluetoothPreferenceGetControllerPowerState").map { unsafeBitCast($0, to: GetPower.self) }
    private static let setPowerFn = dlsym(lib, "IOBluetoothPreferenceSetControllerPowerState").map { unsafeBitCast($0, to: SetPower.self) }

    init() { refresh() }   // first IOBluetooth use makes macOS ask for Bluetooth permission once

    func refresh() {
        lastRefresh = Date()
        q.async {
            let p = (Self.getPower?() ?? 0) != 0
            let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
            let list = paired.compactMap { d -> Device? in
                guard let a = d.addressString else { return nil }
                return Device(name: d.name ?? a, address: a, connected: d.isConnected())
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            main {
                if p != self.powered { self.powered = p }
                if list != self.devices { withAnimation(.easeOut(duration: 0.2)) { self.devices = list } }
            }
        }
    }
    func refreshIfStale() { if Date().timeIntervalSince(lastRefresh) > 5 { refresh() } }

    func setPower(_ on: Bool) {
        powered = on; error = nil
        q.async {
            Self.setPowerFn?(on ? 1 : 0)
            Thread.sleep(forTimeInterval: 1.2)
            let now = (Self.getPower?() ?? 0) != 0
            main {
                if now != on { self.error = "Couldn't turn Bluetooth \(on ? "on" : "off")" }
                self.refresh()
            }
        }
    }

    func toggle(_ d: Device) {
        busy = d.address; error = nil
        q.async {
            var ok = false
            if let dev = IOBluetoothDevice(addressString: d.address) {
                ok = d.connected ? dev.closeConnection() == kIOReturnSuccess
                                 : dev.openConnection() == kIOReturnSuccess
            }
            main {
                self.busy = nil
                if ok, let i = self.devices.firstIndex(of: d) {   // show the new state right away
                    self.devices[i] = Device(name: d.name, address: d.address, connected: !d.connected)
                } else if !ok { self.error = "Couldn't \(d.connected ? "disconnect" : "connect") \(d.name)" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.refresh() }
            }
        }
    }
}

struct BluetoothSection: View {
    @ObservedObject var bt: BluetoothModel
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.horizontal.circle")
                    .foregroundStyle(bt.powered ? Mocha.blue : Mocha.red).frame(width: 18)
                Text("Bluetooth").foregroundStyle(Mocha.subtext)
                Spacer()
                ToggleSwitch(on: bt.powered) { bt.setPower(!bt.powered) }
            }
            .font(.system(size: 12.5, weight: .semibold))
            .padding(.horizontal, 14).frame(height: 30)
            if bt.powered {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) { ForEach(bt.devices) { device($0) } }
                }
                .frame(height: max(27, CGFloat(min(bt.devices.count, 6)) * 27))
                if let e = bt.error {
                    Text(e).font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.red).padding(.horizontal, 42)
                }
            }
        }
        .animation(.easeOut(duration: 0.18), value: bt.powered)
        .onAppear { bt.refreshIfStale() }
    }

    private func device(_ d: BluetoothModel.Device) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon(d.name)).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(d.connected ? Mocha.blue : Mocha.overlay0).frame(width: 18)
            Text(d.name).font(.system(size: 12.5, weight: d.connected ? .bold : .medium))
                .foregroundStyle(d.connected ? Mocha.blue : Mocha.text).lineLimit(1)
            Spacer()
            ZStack(alignment: .trailing) {
                if bt.busy == d.address { ProgressView().controlSize(.mini) }
                else if d.connected { Text("Connected").font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.subtext) }
            }.frame(width: 70, alignment: .trailing)
        }
        .padding(.leading, 28).padding(.trailing, 14).frame(height: 27)
        .background(RowHover(active: d.connected))
        .contentShape(Rectangle())
        .onTapGesture { if bt.busy == nil { bt.toggle(d) } }
    }

    private func icon(_ n: String) -> String {
        let s = n.lowercased()
        if s.contains("airpods") { return "airpods" }
        if s.contains("keyboard") { return "keyboard" }
        if s.contains("mouse") { return "computermouse" }
        if s.contains("trackpad") { return "rectangle.and.hand.point.up.left" }
        if s.contains("buds") || s.contains("head") || s.contains("phone") { return "headphones" }
        return "dot.radiowaves.left.and.right"
    }
}
