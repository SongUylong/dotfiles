import Cocoa
import SwiftUI

// MARK: palette (Catppuccin Mocha, same as NotchDock)

extension Color {
    init(hex: UInt32) { self.init(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255) }
}
enum Mocha {
    static let base = Color(hex: 0x1e1e2e), surface0 = Color(hex: 0x313244), surface1 = Color(hex: 0x45475a)
    static let overlay0 = Color(hex: 0x6c7086), subtext = Color(hex: 0xa6adc8), text = Color(hex: 0xcdd6f4)
    static let red = Color(hex: 0xf38ba8), green = Color(hex: 0xa6e3a1), blue = Color(hex: 0x89b4fa)
    static let mauve = Color(hex: 0xcba6f7), peach = Color(hex: 0xfab387), teal = Color(hex: 0x94e2d5), yellow = Color(hex: 0xf9e2af)
}

// MARK: data

struct Listener: Identifiable, Equatable {
    var id: String { "\(pid)-\(port)" }
    let port: Int
    let pid: Int32
    let name: String       // process or container name
    let detail: String     // project folder, or the docker image
    let kind: Kind
    let local: Bool        // bound to localhost only
    enum Kind { case node, python, ruby, go, java, php, docker, db, other }
}

func run(_ path: String, _ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    let pipe = Pipe(); p.standardOutput = pipe; p.standardError = Pipe()
    guard (try? p.run()) != nil else { return "" }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(decoding: data, as: UTF8.self)
}

func exePath(_ pid: Int32) -> String {
    var buf = [CChar](repeating: 0, count: 4096)
    return proc_pidpath(pid, &buf, UInt32(buf.count)) > 0 ? String(cString: buf) : ""
}

/// Processes that are part of macOS or ordinary apps (AirPlay receiver, rapportd, app helper
/// agents…). These aren't things you'd want to kill from a dev port list.
func isSystem(_ path: String, _ name: String) -> Bool {
    if name.hasPrefix("com.docker") || name == "docker" || name.lowercased().contains("orbstack") { return false }
    let sys = ["/System/", "/usr/libexec/", "/usr/sbin/", "/sbin/", "/Library/Apple/"]
    if sys.contains(where: path.hasPrefix) { return true }
    // GUI apps and their helper agents (Figma, Apidog, Spotify, ControlCenter…)
    if path.contains(".app/") && !path.contains("/Docker.app/") { return true }
    return false
}

func kind(_ name: String, _ path: String) -> Listener.Kind {
    let n = (name + " " + path).lowercased()
    if n.contains("docker") || n.contains("orbstack") { return .docker }
    if n.contains("node") || n.contains("bun") || n.contains("deno") { return .node }
    if n.contains("python") || n.contains("uvicorn") || n.contains("gunicorn") { return .python }
    if n.contains("ruby") || n.contains("puma") || n.contains("rails") { return .ruby }
    if n.contains("java") { return .java }
    if n.contains("php") { return .php }
    if n.contains("postgres") || n.contains("redis") || n.contains("mysql") || n.contains("mongo") { return .db }
    if n.contains("/go-build") || n.hasSuffix(" go") { return .go }
    return .other
}

func cwd(_ pid: Int32) -> String {
    let out = run("/usr/sbin/lsof", ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"])
    guard let line = out.split(separator: "\n").first(where: { $0.hasPrefix("n") }) else { return "" }
    let p = String(line.dropFirst())
    return p == "/" ? "" : p.replacingOccurrences(of: NSHomeDirectory(), with: "~")
}

/// Docker publishes container ports from com.docker.backend; map them back to container names.
func dockerContainers() -> [Int: (String, String)] {
    let docker = ["/usr/local/bin/docker", "/opt/homebrew/bin/docker", "/Applications/Docker.app/Contents/Resources/bin/docker"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }
    guard let docker else { return [:] }
    var map: [Int: (String, String)] = [:]
    for line in run(docker, ["ps", "--format", "{{.Names}}\t{{.Image}}\t{{.Ports}}"]).split(separator: "\n") {
        let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard f.count == 3 else { continue }
        // "127.0.0.1:5432->5432/tcp, :::5432->5432/tcp"
        for part in f[2].split(separator: ",") {
            if let host = part.split(separator: "-").first?.split(separator: ":").last, let p = Int(host) { map[p] = (f[0], f[1]) }
        }
    }
    return map
}

func listeners(all: Bool) -> [Listener] {
    let out = run("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN", "-FpcPn"])
    var raw: [(Int, Int32, String, Bool)] = [], seen = Set<String>()
    var pid: Int32 = 0, name = ""
    for line in out.split(separator: "\n") {
        let v = String(line.dropFirst())
        switch line.first {
        case "p": pid = Int32(v) ?? 0
        case "c": name = v
        case "n":
            guard let port = Int(v.split(separator: ":").last ?? "") else { continue }
            let local = v.hasPrefix("127.") || v.hasPrefix("[::1]") || v.hasPrefix("localhost")
            if seen.insert("\(port)-\(pid)").inserted { raw.append((port, pid, name, local)) }
        default: break
        }
    }
    let docker = raw.contains { $0.2.hasPrefix("com.docker") } ? dockerContainers() : [:]
    var cwdCache: [Int32: String] = [:]
    return raw.compactMap { port, pid, name, local in
        let path = exePath(pid)
        if !all && isSystem(path, name) { return nil }
        let k = kind(name, path)
        if k == .docker, let c = docker[port] {
            return Listener(port: port, pid: pid, name: c.0, detail: c.1, kind: .docker, local: local)
        }
        if cwdCache[pid] == nil { cwdCache[pid] = cwd(pid) }
        return Listener(port: port, pid: pid, name: name, detail: cwdCache[pid] ?? "", kind: k, local: local)
    }.sorted { $0.port < $1.port }
}

// MARK: model

final class Model: ObservableObject {
    @Published var items: [Listener] = []
    @Published var showAll = UserDefaults.standard.bool(forKey: "showAll") {
        didSet { UserDefaults.standard.set(showAll, forKey: "showAll"); refresh() }
    }
    @Published var loading = false
    @Published var killing: Set<String> = []

    func refresh() {
        loading = true
        let all = showAll
        DispatchQueue.global(qos: .userInitiated).async {
            let list = listeners(all: all)
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.18)) { self.items = list }
                self.loading = false
            }
        }
    }

    func kill(_ l: Listener, force: Bool) {
        killing.insert(l.id)
        DispatchQueue.global().async {
            if l.kind == .docker, l.pid != 0, let docker = ["/usr/local/bin/docker", "/opt/homebrew/bin/docker"].first(where: { FileManager.default.isExecutableFile(atPath: $0) }),
               !l.name.hasPrefix("com.docker") {
                _ = run(docker, ["stop", l.name])           // stop the container, not Docker itself
            } else {
                Darwin.kill(l.pid, force ? SIGKILL : SIGTERM)
                if !force {   // escalate if it ignores SIGTERM
                    for _ in 0..<15 { if Darwin.kill(l.pid, 0) != 0 { break }; Thread.sleep(forTimeInterval: 0.1) }
                    if Darwin.kill(l.pid, 0) == 0 { Darwin.kill(l.pid, SIGKILL) }
                }
            }
            DispatchQueue.main.async { self.killing.remove(l.id); self.refresh() }
        }
    }

    func killAll() { for l in items where l.kind != .db { kill(l, force: false) } }
}

// MARK: views

struct PortsView: View {
    @ObservedObject var model: Model
    var close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.horizontal.circle.fill").foregroundStyle(Mocha.mauve)
                Text("Ports").font(.system(size: 14, weight: .bold)).foregroundStyle(Mocha.text)
                Text("\(model.items.count)").font(.system(size: 11, weight: .bold)).foregroundStyle(Mocha.base)
                    .padding(.horizontal, 6).padding(.vertical, 1).background(Capsule().fill(Mocha.mauve))
                Spacer()
                Pill(text: model.showAll ? "All" : "Dev only", on: !model.showAll) { model.showAll.toggle() }
                IconButton(symbol: "arrow.clockwise", spinning: model.loading) { model.refresh() }
            }
            .padding(.horizontal, 14).frame(height: 44)
            Rectangle().fill(Mocha.surface0).frame(height: 1)

            if model.items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle").font(.system(size: 26)).foregroundStyle(Mocha.green)
                    Text(model.loading ? "Looking…" : "No dev servers running").font(.system(size: 12.5, weight: .medium)).foregroundStyle(Mocha.subtext)
                }.frame(maxWidth: .infinity).frame(height: 120)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 2) { ForEach(model.items) { PortRow(l: $0, model: model) } }.padding(6)
                }.frame(height: min(CGFloat(model.items.count) * 52 + 12, 420))
            }

            Rectangle().fill(Mocha.surface0).frame(height: 1)
            HStack {
                Text("Click ✕ to stop  ·  ⌥ force").foregroundStyle(Mocha.overlay0)
                Spacer()
                if model.items.contains(where: { $0.kind != .db }) {
                    Text("Stop all").foregroundStyle(Mocha.red).fontWeight(.semibold)
                        .onTapGesture { model.killAll() }
                }
                Text("Quit").foregroundStyle(Mocha.subtext).padding(.leading, 10)
                    .onTapGesture { NSApp.terminate(nil) }
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 14).frame(height: 32)
        }
        .frame(width: 380)
        .background(Mocha.base)
        .environment(\.colorScheme, .dark)
    }
}

struct PortRow: View {
    let l: Listener
    @ObservedObject var model: Model
    @State private var hover = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 13, weight: .semibold)).foregroundStyle(color)
                .frame(width: 30, height: 30).background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(":\(l.port)").font(.system(size: 13.5, weight: .bold, design: .monospaced)).foregroundStyle(Mocha.text)
                    Text(l.name).font(.system(size: 12.5, weight: .medium)).foregroundStyle(Mocha.subtext).lineLimit(1)
                    if !l.local {
                        Text("LAN").font(.system(size: 9, weight: .bold)).foregroundStyle(Mocha.peach)
                            .padding(.horizontal, 4).background(Capsule().stroke(Mocha.peach.opacity(0.6)))
                    }
                }
                Text(l.detail.isEmpty ? "pid \(l.pid)" : l.detail).font(.system(size: 11)).foregroundStyle(Mocha.overlay0)
                    .lineLimit(1).truncationMode(.head)
            }
            Spacer(minLength: 4)
            if hover || model.killing.contains(l.id) {
                IconButton(symbol: "safari", tint: Mocha.blue) {
                    NSWorkspace.shared.open(URL(string: "http://localhost:\(l.port)")!)
                }
                IconButton(symbol: "xmark", tint: Mocha.red, spinning: model.killing.contains(l.id)) {
                    model.kill(l, force: NSEvent.modifierFlags.contains(.option))
                }
            }
        }
        .padding(.horizontal, 8).frame(height: 50)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(hover ? Mocha.surface0 : .clear))
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.1)) { hover = h } }
    }

    private var symbol: String {
        switch l.kind {
        case .node: "hexagon.fill"; case .python: "chevron.left.forwardslash.chevron.right"; case .ruby: "diamond.fill"
        case .go: "bolt.fill"; case .java: "cup.and.saucer.fill"; case .php: "curlybraces"
        case .docker: "shippingbox.fill"; case .db: "cylinder.split.1x2.fill"; case .other: "terminal.fill"
        }
    }
    private var color: Color {
        switch l.kind {
        case .node: Mocha.green; case .python: Mocha.yellow; case .ruby: Mocha.red; case .go: Mocha.teal
        case .java: Mocha.peach; case .php: Mocha.mauve; case .docker: Mocha.blue; case .db: Mocha.peach; case .other: Mocha.subtext
        }
    }
}

struct IconButton: View {
    let symbol: String
    var tint: Color = Mocha.subtext
    var spinning = false
    let action: () -> Void
    @State private var hover = false
    var body: some View {
        ZStack {
            if spinning { ProgressView().controlSize(.mini) }
            else { Image(systemName: symbol).font(.system(size: 11, weight: .bold)).foregroundStyle(tint) }
        }
        .frame(width: 26, height: 26)
        .background(RoundedRectangle(cornerRadius: 7).fill(hover ? tint.opacity(0.2) : Mocha.surface0.opacity(0.6)))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .onTapGesture { if !spinning { action() } }
    }
}

struct Pill: View {
    let text: String
    let on: Bool
    let action: () -> Void
    var body: some View {
        Text(text).font(.system(size: 11, weight: .semibold))
            .foregroundStyle(on ? Mocha.base : Mocha.subtext)
            .padding(.horizontal, 9).frame(height: 22)
            .background(Capsule().fill(on ? Mocha.green : Mocha.surface0))
            .contentShape(Capsule())
            .onTapGesture(perform: action)
    }
}

// MARK: app

final class App: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()
    let model = Model()

    func applicationDidFinishLaunching(_ n: Notification) {
        item.button?.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Ports")
        item.button?.action = #selector(toggle)
        item.button?.target = self
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = NSHostingController(rootView: PortsView(model: model) { [weak self] in self?.popover.performClose(nil) })
        model.refresh()
    }

    @objc func toggle() {
        if popover.isShown { popover.performClose(nil); return }
        model.refresh()
        guard let b = item.button else { return }
        popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
