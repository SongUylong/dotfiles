# NotchDock

Native SwiftUI replacement for SketchyBar and Apple's Dock, with a file shelf in the notch.

- **Top bar** (`TopBar.swift`, `BarData.swift`): Catppuccin Mocha pills, yabai spaces 1–5 with app icons,
  front app, now playing (`media-control`), AI usage / system / controls dropdowns, keep-awake, battery, clock.
  AI usage reuses `../sketchybar/plugins/ai_usage.sh` to fetch and reads `~/.cache/sketchybar/*.json`.
- **Dock** (`Dock.swift`): pinned + running apps, magnification, auto-hide (reveal at bottom edge).
- **Launcher** (`Launcher.swift`): ⌘Space (falls back to ⌥Space if Spotlight holds ⌘Space). Fuzzy app search ranked by use, calculator, built-in commands (yabai window actions, lock, sleep, dark mode…), clipboard history (`clip`), file search (`f name`), Google fallback.
- **Notch shelf** (`Notch.swift`): drag files toward the notch to park them; drag back out, double-click to open.
- **Settings**: menu bar icon → Settings…

```bash
~/dotfiles/config/notchdock/install.sh              # build, install, start at login, hide Apple Dock, stop SketchyBar
~/dotfiles/config/notchdock/install.sh --no-system  # just rebuild + reinstall the app
~/dotfiles/config/notchdock/install.sh --uninstall  # remove and restore Apple Dock + SketchyBar
```

## Low Power Mode without a password

Clicking the battery switches Low Power Mode. That needs root, so install the small helper once:

```bash
sudo ~/dotfiles/config/notchdock/lowpower-helper/install.sh
```

NotchDock then writes `0`/`1` to `~/.cache/notchdock/lowpower.want` and the root LaunchDaemon
`com.eric.lowpower-helper` applies it. Without the helper, macOS asks for your password each time.
