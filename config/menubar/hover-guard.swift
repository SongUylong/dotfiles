import AppKit
import Carbon
import CoreGraphics

private final class HoverGuard {
    private let inset: CGFloat = 4
    private var displays: [CGRect] = []
    private var enabled = true
    var tap: CFMachPort?

    func updateDisplays() {
        displays = NSScreen.screens.compactMap { screen in
            let key = NSDeviceDescriptionKey("NSScreenNumber")
            guard let number = screen.deviceDescription[key] as? NSNumber else { return nil }
            return CGDisplayBounds(number.uint32Value)
        }
    }

    func toggle() {
        enabled.toggle()
        fputs("hover-guard: clamp \(enabled ? "ON" : "OFF")\n", stderr)
    }

    func handle(_ type: CGEventType, _ event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        guard enabled, type == .mouseMoved else { return }

        let point = event.location
        guard let display = displays.first(where: { $0.contains(point) }),
              point.y < display.minY + inset else { return }
        // A shared edge must remain passable when another display sits above it.
        let above = CGPoint(x: point.x, y: display.minY - 1)
        guard !displays.contains(where: { $0.contains(above) }) else { return }
        event.location = CGPoint(x: point.x, y: display.minY + inset)
    }
}

private func fail(_ message: String) -> Never {
    fputs("hover-guard: \(message)\n", stderr)
    exit(EXIT_FAILURE)
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
private let guardState = HoverGuard()
guardState.updateDisplays()
let displayObserver = NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification, object: app, queue: .main
) { _ in guardState.updateDisplays() }

var hotkeyEvent = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
let eventTarget = GetApplicationEventTarget()
let handlerStatus = InstallEventHandler(eventTarget, { _, _, _ in
    guardState.toggle()
    return noErr
}, 1, &hotkeyEvent, nil, nil)
guard handlerStatus == noErr else { fail("cannot install hotkey handler (\(handlerStatus))") }

var hotkey: EventHotKeyRef?
let hotkeyStatus = RegisterEventHotKey(
    UInt32(kVK_ANSI_B), UInt32(cmdKey | optionKey),
    EventHotKeyID(signature: 0x48475544, id: 1), eventTarget, 0, &hotkey
)
guard hotkeyStatus == noErr else { fail("cannot register Command-Option-B (\(hotkeyStatus))") }

guard let tap = CGEvent.tapCreate(
    tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap,
    eventsOfInterest: CGEventMask(1) << CGEventType.mouseMoved.rawValue,
    callback: { _, type, event, _ in
        guardState.handle(type, event)
        return Unmanaged.passUnretained(event)
    }, userInfo: nil
), let source = CFMachPortCreateRunLoopSource(nil, tap, 0) else {
    fail("cannot create pointer tap; grant the launching app Accessibility and Input Monitoring")
}
guardState.tap = tap
CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
fputs("hover-guard: clamp ON (top 4 pixels; Command-Option-B toggles)\n", stderr)
app.run()
