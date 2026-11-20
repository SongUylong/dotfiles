import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

// MARK: model

struct LaunchItem: Identifiable {
    enum Kind: String { case app = "Application", command = "Command", file = "File", clipboard = "Clipboard", calc = "Calculator", web = "Search", window = "Window" }
    var id: String { kind.rawValue + "|" + title + "|" + subtitle }
    let title: String
    var subtitle = ""
    let kind: Kind
    var icon: NSImage?
    var symbol: String = "circle"
    var color: Color = Mocha.text
    let run: () -> Void
}

/// Remembers recently copied text (polls the pasteboard, like most clipboard managers).
final class ClipboardHistory {
    private(set) var items: [String] = []
    private var lastChange = NSPasteboard.general.changeCount
    private var timer: Timer?
    init() {
        items = UserDefaults.standard.stringArray(forKey: "clipHistory") ?? []
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in self?.poll() }
    }
    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChange else { return }
        lastChange = pb.changeCount
        // Skip content marked secret by password managers.
        if pb.types?.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")) == true { return }
        guard let s = pb.string(forType: .string), !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        items.removeAll { $0 == s }
        items.insert(s, at: 0)
        if items.count > 100 { items.removeLast(items.count - 100) }
        UserDefaults.standard.set(items, forKey: "clipHistory")
    }
    func clear() { items = []; UserDefaults.standard.set(items, forKey: "clipHistory") }
}

final class LauncherModel: ObservableObject {
    @Published var query = "" { didSet { search() } }
    @Published var results: [LaunchItem] = []
    @Published var selected = 0
    var close: () -> Void = {}

    private var apps: [(name: String, url: URL)] = []
    private var launchCounts: [String: Int] = UserDefaults.standard.dictionary(forKey: "launchCounts") as? [String: Int] ?? [:]
    let clipboard = ClipboardHistory()
    private var fileQuery: Process?
    private var fileResults: [URL] = []

    init() { reloadApps() }

    func reloadApps() {
        let fm = FileManager.default
        var found: [(String, URL)] = []
        let roots = ["/Applications", "/System/Applications", "/System/Applications/Utilities",
                     "/Applications/Utilities", NSHomeDirectory() + "/Applications"]
        for root in roots {
            for name in (try? fm.contentsOfDirectory(atPath: root)) ?? [] where name.hasSuffix(".app") {
                found.append((String(name.dropLast(4)), URL(fileURLWithPath: root).appendingPathComponent(name)))
            }
        }
        // Apps elsewhere (Homebrew casks in subfolders, Setapp, ~/Applications/Chrome Apps…) via Spotlight.
        let extra = sh("mdfind 'kMDItemContentType == com.apple.application-bundle' 2>/dev/null")
        for line in extra.split(separator: "\n") {
            let u = URL(fileURLWithPath: String(line))
            let p = u.path
            if p.contains("/Library/") || p.contains(".app/") || p.hasPrefix("/System/Library") { continue }
            found.append((u.deletingPathExtension().lastPathComponent, u))
        }
        var seen = Set<String>()
        apps = found.filter { seen.insert($0.0.lowercased()).inserted }
    }

    // MARK: search

    func search() {
        selected = 0
        let q = query.trimmingCharacters(in: .whitespaces)
        var out: [LaunchItem] = []

        // Prefixes switch modes, like Raycast's dedicated commands.
        if q.hasPrefix("clip") || q.hasPrefix("cb ") {
            let rest = q.drop { $0 != " " }.trimmingCharacters(in: .whitespaces).lowercased()
            out = clipboard.items.filter { rest.isEmpty || $0.lowercased().contains(rest) }.prefix(30).map(clipItem)
            if out.isEmpty { out = [LaunchItem(title: "Clipboard history is empty", kind: .clipboard, symbol: "doc.on.clipboard", run: {})] }
            results = out; return
        }
        if q.hasPrefix("f ") || q.hasPrefix("file ") {
            let rest = String(q.drop { $0 != " " }).trimmingCharacters(in: .whitespaces)
            findFiles(rest)
            results = fileResults.prefix(30).map(fileItem); return
        }

        if q.isEmpty {
            // Favourites: most launched apps, then a few commands.
            let top = apps.sorted { (launchCounts[$0.name] ?? 0) > (launchCounts[$1.name] ?? 0) }.prefix(6)
            results = top.map(appItem) + commands().prefix(4); return
        }

        if let v = Calc.evaluate(q) {
            let text = Calc.format(v)
            out.append(LaunchItem(title: text, subtitle: "\(q) =  ·  Enter to copy", kind: .calc, symbol: "equal.square.fill", color: Mocha.peach) {
                NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
            })
        }

        let scoredApps = apps.compactMap { a -> (Int, LaunchItem)? in
            guard let s = Fuzzy.score(q, a.name) else { return nil }
            return (s + min(launchCounts[a.name] ?? 0, 20) * 3, appItem(a))
        }
        let scoredCmds = commands().compactMap { c -> (Int, LaunchItem)? in
            guard let s = Fuzzy.score(q, c.title) else { return nil }
            return (s - 5, c)
        }
        out += (scoredApps + scoredCmds).sorted { $0.0 > $1.0 }.prefix(10).map(\.1)

        if q.count >= 2 {
            let clips = clipboard.items.filter { $0.localizedCaseInsensitiveContains(q) }.prefix(2).map(clipItem)
            out += clips
        }
        out.append(webItem(q))
        results = out
    }

    private func appItem(_ a: (name: String, url: URL)) -> LaunchItem {
        LaunchItem(title: a.name, subtitle: a.url.deletingLastPathComponent().path, kind: .app,
                   icon: NSWorkspace.shared.icon(forFile: a.url.path)) { [weak self] in
            self?.launchCounts[a.name, default: 0] += 1
            UserDefaults.standard.set(self?.launchCounts, forKey: "launchCounts")
            NSWorkspace.shared.openApplication(at: a.url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    private func clipItem(_ s: String) -> LaunchItem {
        let one = s.replacingOccurrences(of: "\n", with: " ⏎ ")
        return LaunchItem(title: String(one.prefix(80)), subtitle: "\(s.count) characters  ·  Enter to copy",
                          kind: .clipboard, symbol: "doc.on.clipboard", color: Mocha.teal) {
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(s, forType: .string)
        }
    }

    private func fileItem(_ u: URL) -> LaunchItem {
        LaunchItem(title: u.lastPathComponent, subtitle: u.deletingLastPathComponent().path.replacingOccurrences(of: NSHomeDirectory(), with: "~"),
                   kind: .file, icon: NSWorkspace.shared.icon(forFile: u.path)) { NSWorkspace.shared.open(u) }
    }

    private func webItem(_ q: String) -> LaunchItem {
        LaunchItem(title: "Search Google for “\(q)”", kind: .web, symbol: "magnifyingglass", color: Mocha.blue) {
            var c = URLComponents(string: "https://www.google.com/search")!
            c.queryItems = [URLQueryItem(name: "q", value: q)]
            if let u = c.url { NSWorkspace.shared.open(u) }
        }
    }

    /// Spotlight's index, limited to the home folder; results arrive synchronously but are capped and fast.
    private func findFiles(_ q: String) {
        guard q.count >= 2 else { fileResults = []; return }
        let out = sh("mdfind -onlyin ~ -name \(shellQuote(q)) 2>/dev/null | grep -v '/Library/' | head -40")
        fileResults = out.split(separator: "\n").map { URL(fileURLWithPath: String($0)) }
    }

    private func shellQuote(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }

    // MARK: built-in commands

    func commands() -> [LaunchItem] {
        func cmd(_ t: String, _ sub: String, _ sym: String, _ c: Color, _ kind: LaunchItem.Kind = .command, _ f: @escaping () -> Void) -> LaunchItem {
            LaunchItem(title: t, subtitle: sub, kind: kind, symbol: sym, color: c, run: f)
        }
        let y = { (args: String) in bg { sh("yabai -m \(args)") } }
        return [
            cmd("Clipboard History", "Type “clip” to search copied text", "doc.on.clipboard", Mocha.teal) { [weak self] in
                main { self?.query = "clip " } },
            cmd("Search Files", "Type “f ” and a name", "doc.text.magnifyingglass", Mocha.yellow) { [weak self] in
                main { self?.query = "f " } },
            cmd("Toggle Fullscreen Window", "yabai", "arrow.up.left.and.arrow.down.right", Mocha.mauve, .window) { y("window --toggle zoom-fullscreen") },
            cmd("Float / Tile Window", "yabai", "square.on.square", Mocha.mauve, .window) { y("window --toggle float") },
            cmd("Balance Windows", "yabai", "rectangle.split.3x1", Mocha.mauve, .window) { y("space --balance") },
            cmd("Rotate Layout", "yabai", "rotate.right", Mocha.mauve, .window) { y("space --rotate 90") },
            cmd("Toggle Dark Mode", "System appearance", "circle.lefthalf.filled", Mocha.lavender) {
                bg { sh("osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode'") } },
            cmd("Lock Screen", "", "lock.fill", Mocha.red) {
                bg { sh("osascript -e 'tell application \"System Events\" to keystroke \"q\" using {control down, command down}'") } },
            cmd("Sleep", "", "moon.fill", Mocha.blue) { bg { sh("pmset sleepnow") } },
            cmd("Toggle Mute", "", "speaker.slash.fill", Mocha.peach) {
                bg { sh("osascript -e 'set volume output muted (not output muted of (get volume settings))'") } },
            cmd("Open Downloads", "", "arrow.down.circle.fill", Mocha.green) { NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")) },
            cmd("Show Desktop", "", "menubar.dock.rectangle", Mocha.subtext) { NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")) },
            cmd("Clear Clipboard History", "", "trash", Mocha.red) { [weak self] in self?.clipboard.clear() },
            cmd("Restart Top Bar & Dock", "NotchDock", "arrow.clockwise", Mocha.mauve) {
                bg { sh("launchctl kickstart -k gui/$(id -u)/com.eric.notchdock") } },
            cmd("Quit Frontmost App", "", "xmark.app", Mocha.red) {
                NSWorkspace.shared.frontmostApplication?.terminate() },
        ]
    }

    func runSelected() {
        guard results.indices.contains(selected) else { return }
        let item = results[selected]
        let keepsOpen = item.title == "Clipboard History" || item.title == "Search Files"
        item.run()
        if !keepsOpen { close() }
    }
}

// MARK: helpers

enum Fuzzy {
    /// Higher is better; nil means no match. Prefix > word-start > substring > subsequence.
    static func score(_ q: String, _ s: String) -> Int? {
        let q = q.lowercased(), t = s.lowercased()
        if t == q { return 1000 }
        if t.hasPrefix(q) { return 800 - t.count }
        let words = t.split(whereSeparator: { " -_.".contains($0) })
        if words.contains(where: { $0.hasPrefix(q) }) { return 600 - t.count }
        let initials = String(words.compactMap(\.first))
        if initials.hasPrefix(q) { return 550 }
        if t.contains(q) { return 400 - t.count }
        var i = t.startIndex
        for c in q {
            guard let f = t[i...].firstIndex(of: c) else { return nil }
            i = t.index(after: f)
        }
        return 100 - t.count
    }
}

enum Calc {
    /// Evaluates plain arithmetic safely (digits, operators, parentheses only).
    static func evaluate(_ s: String) -> Double? {
        let expr = s.replacingOccurrences(of: "x", with: "*").replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/").replacingOccurrences(of: ",", with: "")
        guard expr.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789")) != nil,
              expr.rangeOfCharacter(from: CharacterSet(charactersIn: "+-*/%^()")) != nil,
              expr.allSatisfy({ "0123456789.+-*/%^() ".contains($0) }) else { return nil }
        var p = Parser(Array(expr.filter { $0 != " " }))
        guard let v = p.expr(), p.i == p.c.count, v.isFinite else { return nil }
        return v
    }
    static func format(_ v: Double) -> String {
        if v == v.rounded(), abs(v) < 1e15 { return String(format: "%.0f", v) }
        return String(format: "%.10g", v)
    }
    private struct Parser {
        let c: [Character]; var i = 0
        init(_ c: [Character]) { self.c = c }
        mutating func peek() -> Character? { i < c.count ? c[i] : nil }
        mutating func expr() -> Double? {
            guard var v = term() else { return nil }
            while let o = peek(), o == "+" || o == "-" { i += 1; guard let r = term() else { return nil }; v = o == "+" ? v + r : v - r }
            return v
        }
        mutating func term() -> Double? {
            guard var v = power() else { return nil }
            while let o = peek(), "*/%".contains(o) {
                i += 1; guard let r = power() else { return nil }
                v = o == "*" ? v * r : o == "/" ? v / r : v.truncatingRemainder(dividingBy: r)
            }
            return v
        }
        mutating func power() -> Double? {
            guard let b = unary() else { return nil }
            if peek() == "^" { i += 1; guard let e = power() else { return nil }; return pow(b, e) }
            return b
        }
        mutating func unary() -> Double? {
            if peek() == "-" { i += 1; return unary().map { -$0 } }
            if peek() == "(" { i += 1; let v = expr(); guard peek() == ")" else { return nil }; i += 1; return v }
            let s = i
            while let ch = peek(), ch.isNumber || ch == "." { i += 1 }
            return Double(String(c[s..<i]))
        }
    }
}

// MARK: view

struct LauncherView: View {
    @ObservedObject var model: LauncherModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").font(.system(size: 18, weight: .medium)).foregroundStyle(Mocha.overlay0)
                TextField("Search apps, commands, files, clipboard…", text: $model.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20))
                    .foregroundStyle(Mocha.text)
                    .focused($focused)
                    .onSubmit { model.runSelected() }
            }
            .padding(.horizontal, 18).frame(height: 58)
            Rectangle().fill(Mocha.surface0).frame(height: 1)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(model.results.enumerated()), id: \.offset) { i, item in
                            row(item, selected: i == model.selected)
                                .id(i)
                                .onTapGesture { model.selected = i; model.runSelected() }
                        }
                    }.padding(8)
                    .id(model.query)
                }
                .onChange(of: model.selected) { _, s in withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(s) } }
            }
            Rectangle().fill(Mocha.surface0).frame(height: 1)
            HStack {
                Image(systemName: "command").foregroundStyle(Mocha.mauve)
                Text("NotchDock").foregroundStyle(Mocha.subtext)
                Spacer()
                hint("↵", "Open"); hint("↑↓", "Move"); hint("esc", "Close")
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 14).frame(height: 32)
        }
        .frame(width: 720, height: 460)
        .background(BarBackground(radius: 16))
        .onAppear { focused = true }
        .onKeyPress(.downArrow) { move(1); return .handled }
        .onKeyPress(.upArrow) { move(-1); return .handled }
        .onKeyPress(.escape) {
            if model.query.isEmpty { model.close() } else { model.query = "" }
            return .handled
        }
        .environment(\.colorScheme, .dark)
    }

    private func move(_ d: Int) {
        guard !model.results.isEmpty else { return }
        model.selected = (model.selected + d + model.results.count) % model.results.count
    }

    private func row(_ item: LaunchItem, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Group {
                if let icon = item.icon { Image(nsImage: icon).resizable() }
                else {
                    Image(systemName: item.symbol).font(.system(size: 13, weight: .semibold)).foregroundStyle(item.color)
                        .frame(width: 26, height: 26)
                        .background(RoundedRectangle(cornerRadius: 7).fill(Mocha.surface0))
                }
            }.frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.system(size: 14, weight: .medium)).foregroundStyle(Mocha.text).lineLimit(1)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle).font(.system(size: 11)).foregroundStyle(Mocha.overlay0).lineLimit(1).truncationMode(.middle)
                }
            }
            Spacer()
            Text(item.kind.rawValue).font(.system(size: 11, weight: .medium)).foregroundStyle(Mocha.overlay0)
        }
        .padding(.horizontal, 10).frame(height: 44)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(selected ? Mocha.surface0 : .clear))
        .contentShape(Rectangle())
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key).padding(.horizontal, 5).padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 4).fill(Mocha.surface0)).foregroundStyle(Mocha.text)
            Text(label).foregroundStyle(Mocha.overlay0)
        }.padding(.leading, 8)
    }
}

// MARK: controller + global hotkey

final class LauncherPanel: NSPanel {
    var onResign: () -> Void = {}
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 720, height: 460),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false; backgroundColor = .clear; hasShadow = true
        level = .modalPanel
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isMovableByWindowBackground = true
    }
    override var canBecomeKey: Bool { true }
    override func resignKey() { super.resignKey(); onResign() }
}

final class LauncherController {
    let model = LauncherModel()
    let panel = LauncherPanel()
    private var hotKeys: [EventHotKeyRef?] = []
    private(set) var shortcut = "⌥Space"

    init() {
        panel.contentView = NSHostingView(rootView: LauncherView(model: model))
        panel.onResign = { [weak self] in self?.hide() }
        model.close = { [weak self] in self?.hide() }
        registerHotKeys()
    }

    func toggle() { panel.isVisible ? hide() : show() }

    private var lastReload = Date()
    func show() {
        if Date().timeIntervalSince(lastReload) > 300 { model.reloadApps(); lastReload = Date() }
        model.query = ""
        model.search()
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main!
        let f = screen.frame
        panel.setFrameOrigin(NSPoint(x: f.midX - 360, y: f.minY + f.height * 0.62 - 230))
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
    }

    /// ⌘Space if Spotlight has released it, and ⌥Space always as a fallback.
    private func registerHotKeys() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let me = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, ctx in
            guard let ctx else { return noErr }
            let c = Unmanaged<LauncherController>.fromOpaque(ctx).takeUnretainedValue()
            DispatchQueue.main.async { c.toggle() }
            return noErr
        }, 1, &spec, me, nil)
        for (i, mods) in [cmdKey, optionKey].enumerated() {
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: OSType(0x4E444C43), id: UInt32(i + 1))   // 'NDLC'
            let st = RegisterEventHotKey(UInt32(kVK_Space), UInt32(mods), id, GetApplicationEventTarget(), 0, &ref)
            if st == noErr { hotKeys.append(ref); if i == 0 { shortcut = "⌘Space" } }
        }
    }
}
