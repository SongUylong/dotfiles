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
    private let bu = "/opt/homebrew/bin/blueutil"

    init() { refresh() }

    func refresh() {
        let bu = self.bu
        bg {
            let p = sh("\(bu) --power") == "1"
            let js = sh("\(bu) --paired --format json 2>/dev/null")
            let list = ((try? JSONSerialization.jsonObject(with: Data(js.utf8))) as? [[String: Any]] ?? [])
                .compactMap { d -> Device? in
                    guard let a = d["address"] as? String else { return nil }
                    return Device(name: (d["name"] as? String) ?? a, address: a, connected: (d["connected"] as? Bool) ?? false)
                }
                .sorted { ($0.connected ? 0 : 1, $0.name) < ($1.connected ? 0 : 1, $1.name) }
            main { self.powered = p; self.devices = list }
        }
    }

    func setPower(_ on: Bool) {
        powered = on
        let bu = self.bu
        bg { sh("\(bu) --power \(on ? 1 : 0)"); main { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.refresh() } } }
    }

    func toggle(_ d: Device) {
        busy = d.address; error = nil
        let bu = self.bu
        bg {
            let out = sh("\(bu) --\(d.connected ? "disconnect" : "connect") \(d.address) 2>&1")
            main {
                self.busy = nil
                if !out.isEmpty && !d.connected { self.error = "Couldn't connect \(d.name)" }
                self.refresh()
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
                ScrollView {
                    VStack(spacing: 1) { ForEach(bt.devices) { device($0) } }
                }.frame(maxHeight: 160)
                if let e = bt.error {
                    Text(e).font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.red).padding(.horizontal, 42)
                }
            }
        }
        .onAppear { bt.refresh() }
    }

    private func device(_ d: BluetoothModel.Device) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon(d.name)).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(d.connected ? Mocha.blue : Mocha.overlay0).frame(width: 18)
            Text(d.name).font(.system(size: 12.5, weight: d.connected ? .bold : .medium))
                .foregroundStyle(d.connected ? Mocha.blue : Mocha.text).lineLimit(1)
            Spacer()
            if bt.busy == d.address { ProgressView().controlSize(.mini) }
            else if d.connected { Text("Connected").font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.subtext) }
        }
        .padding(.leading, 28).padding(.trailing, 14).frame(height: 26)
        .background(RoundedRectangle(cornerRadius: 7).fill(d.connected ? Mocha.surface0 : .clear).padding(.horizontal, 6))
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
