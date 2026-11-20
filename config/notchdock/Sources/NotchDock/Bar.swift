import SwiftUI

/// The shared bar look: used by the dock, the expanded notch shelf and the settings header,
/// so all three read as one design.
struct BarBackground: View {
    var radius: CGFloat = 18
    var body: some View {
        // Catppuccin Mocha, identical to the top bar so dock, notch and settings match.
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Mocha.base.opacity(0.82))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Mocha.surface1, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
    }
}

/// A transparent, non-activating floating panel that hosts SwiftUI content.
final class FloatingPanel: NSPanel {
    init(rect: NSRect, level: NSWindow.Level) {
        super.init(contentRect: rect, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        self.level = level
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isMovable = false
        hidesOnDeactivate = false
    }
    override var canBecomeKey: Bool { true }
    // Keep panels exactly where we put them (no pushing below the menu bar / notch).
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}
