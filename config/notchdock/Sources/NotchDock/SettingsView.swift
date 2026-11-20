import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings

    var body: some View {
        VStack(spacing: 0) {
            header
            Form {
                Section("Dock") {
                    Toggle("Show NotchDock bar", isOn: $settings.showDock)
                    Toggle("Auto-hide (reveal at bottom edge)", isOn: $settings.autoHideDock)
                    LabeledContent("Icon size") {
                        Slider(value: $settings.iconSize, in: 32...80, step: 2)
                        Text("\(Int(settings.iconSize)) pt").monospacedDigit().frame(width: 44, alignment: .trailing)
                    }
                    LabeledContent("Magnification") {
                        Slider(value: $settings.magnification, in: 1...2.2)
                        Text(String(format: "%.1f×", settings.magnification)).monospacedDigit().frame(width: 44, alignment: .trailing)
                    }
                }
                Section("Top bar") {
                    Toggle("Show top bar (replaces SketchyBar)", isOn: $settings.showTopBar)
                }
                Section("Notch shelf") {
                    Toggle("Show file shelf in the notch", isOn: $settings.showNotchShelf)
                    Text("Drag files onto the notch to park them. Hover to open the shelf, drag a file back out to use it, double-click to open.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    Text("Tip: to hide Apple's Dock, run `defaults write com.apple.dock autohide-delay -float 1000; killall Dock` (undo with `defaults delete com.apple.dock autohide-delay; killall Dock`).")
                        .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520, height: 460)
        .tint(Mocha.mauve)
        .preferredColorScheme(.dark)
    }

    /// Same material and stroke as the dock bar, so the window header and the dock match.
    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "dock.rectangle")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Mocha.surface0))
                .foregroundStyle(Mocha.mauve)
            VStack(alignment: .leading, spacing: 1) {
                Text("NotchDock").font(.system(size: 15, weight: .semibold)).foregroundStyle(Mocha.text)
                Text("Top bar, dock and notch shelf").font(.system(size: 11)).foregroundStyle(Mocha.subtext)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(BarBackground(radius: 16))
        .padding(.horizontal, 12)
        .padding(.top, 34)   // clears the traffic lights in the transparent title bar
        .padding(.bottom, 4)
    }
}
