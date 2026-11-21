// Floating dictation pill (bottom-center), in the spirit of a Flow-style HUD.
//   dictate-hud <out.wav>
//   records 16 kHz mono WAV and draws a live waveform.
//   SIGUSR1 -> stop recording, show "transcribing" dots, touch <out.wav>.done
//   SIGTERM -> fade out and quit
// Build: swiftc -O dictate-hud.swift -o dictate-hud
import AppKit
import AVFoundation

let outURL = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/dictate.wav")

final class PillView: NSView {
    var levels = [CGFloat](repeating: 0.05, count: 18)
    var transcribing = false
    var phase: CGFloat = 0

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 1, dy: 1)
        let bg = NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2)
        NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.09, alpha: 0.92).setFill(); bg.fill()
        NSColor(white: 1, alpha: 0.12).setStroke(); bg.lineWidth = 1; bg.stroke()

        let midY = r.midY
        if transcribing {
            for i in 0..<3 {
                let a = 0.35 + 0.65 * max(0, sin(phase - CGFloat(i) * 0.9))
                NSColor(white: 1, alpha: a).setFill()
                let d: CGFloat = 6, x = r.midX + CGFloat(i - 1) * 13 - d / 2
                NSBezierPath(ovalIn: NSRect(x: x, y: midY - d / 2, width: d, height: d)).fill()
            }
            return
        }
        // red recording dot
        NSColor(calibratedRed: 0.95, green: 0.33, blue: 0.40, alpha: 0.6 + 0.4 * abs(sin(phase / 2))).setFill()
        NSBezierPath(ovalIn: NSRect(x: r.minX + 13, y: midY - 4, width: 8, height: 8)).fill()
        // waveform bars
        let barW: CGFloat = 3, gap: CGFloat = 3
        let total = CGFloat(levels.count) * (barW + gap) - gap
        var x = r.midX - total / 2 + 8
        for l in levels {
            let h = max(3, min(r.height - 12, l * (r.height - 12)))
            NSColor(white: 1, alpha: 0.9).setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: midY - h / 2, width: barW, height: h), xRadius: 1.5, yRadius: 1.5).fill()
            x += barW + gap
        }
    }
}

final class App: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    let view = PillView(frame: NSRect(x: 0, y: 0, width: 168, height: 38))
    var recorder: AVAudioRecorder?
    var timer: Timer?
    var sources: [DispatchSourceSignal] = []

    func applicationDidFinishLaunching(_ n: Notification) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let f = screen.visibleFrame
        panel = NSPanel(contentRect: NSRect(x: f.midX - 84, y: f.minY + 28, width: 168, height: 38),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.level = .statusBar; panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = view
        panel.alphaValue = 0; panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; panel.animator().alphaValue = 1 }

        let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16000,
                                       AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16,
                                       AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false]
        recorder = try? AVAudioRecorder(url: outURL, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.record()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.tick() }
        trap(SIGUSR1) { [weak self] in self?.stop() }
        trap(SIGTERM) { [weak self] in self?.quit() }
        trap(SIGINT) { [weak self] in self?.stop() }
    }

    func trap(_ sig: Int32, _ h: @escaping () -> Void) {
        signal(sig, SIG_IGN)
        let s = DispatchSource.makeSignalSource(signal: sig, queue: .main)
        s.setEventHandler(handler: h); s.resume(); sources.append(s)
    }

    func tick() {
        view.phase += 0.25
        if let rec = recorder, rec.isRecording {
            rec.updateMeters()
            let db = CGFloat(rec.averagePower(forChannel: 0))          // -160...0
            let lvl = max(0.05, min(1, pow(10, db / 20) * 4))
            view.levels.removeFirst()
            view.levels.append(lvl * CGFloat.random(in: 0.7...1.0))
        }
        view.needsDisplay = true
    }

    func stop() {
        guard let rec = recorder, rec.isRecording else { return }
        rec.stop()
        FileManager.default.createFile(atPath: outURL.path + ".done", contents: nil)
        view.transcribing = true
    }

    func quit() {
        stop()
        NSAnimationContext.runAnimationGroup({ $0.duration = 0.15; panel.animator().alphaValue = 0 },
                                             completionHandler: { NSApp.terminate(nil) })
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = App()
app.delegate = delegate
app.run()
