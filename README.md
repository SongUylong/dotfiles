# dotfiles

Eric's macOS setup (MacBook, macOS 15). `./install.sh` symlinks `config/*` into `~/.config` and links editor settings. Agents: read this first, then the README inside the folder you touch. Commit/push only when Eric asks.

## Desktop shell

Eric replaced the macOS menu bar, Dock, Raycast and Cmd+Tab with his own tools:

| Folder | What | Notes |
|---|---|---|
| `config/notchdock` | **NotchDock**: native SwiftUI top bar, dock, notch shelf, ⌘Space launcher (apps, files, System Settings panes, calc, clipboard), Cmd+Tab window switcher | Build + install: `cd config/notchdock && ./install.sh --no-system`. Runs from `~/Applications/NotchDock.app` via LaunchAgent `com.eric.notchdock` (KeepAlive). Signed with the Apple Development identity so permissions persist. Debug log: `~/.cache/notchdock/wifi.log`. See its README. |
| `config/yabai` | Tiling WM, spaces 1–5 | Binary is `/usr/local/bin/yabai`. `menubar_opacity 0.0` hides the macOS menu bar completely; NotchDock's bar sits above it (level mainMenu+1) and a 2 s watchdog keeps it on top and clickable. |
| `config/skhd` | Hotkeys | `alt-n` chat workspace (Telegram, WeChat, WhatsApp + Messenger as Brave app windows, 2×2 on space 5, `chat.sh`); `alt-w` Workplace app window (`workplace.sh`); `alt-shift-'` restarts NotchDock if the bar stops responding. Reload: `skhd --reload`. |
| `config/port-killer` | Menu-bar popover listing dev ports with kill/open | Own `install.sh`. |
| `config/claude/skills` | Claude Code skills (symlinked into `~/.claude/skills`) | `disk-cleanup`: Mole-based scan → ask → clean. |
| `config/lid-sleep`, `config/menubar` | Lid-sleep guard, older menu bar helper | |
| `config/sketchybar`, `aerospace`, `borders` | Older/alternative setups | Not the active shell. |

## NotchDock gotchas (macOS 15)

- Option-only hotkeys are ignored by `RegisterEventHotKey` → CGEvent tap (needs Accessibility).
- Cmd+Tab: Apple's switcher is disabled via private `CGSSetSymbolicHotKeyEnabled` and re-enabled when NotchDock quits. Window previews need **Screen Recording** permission.
- Wi-Fi join: CoreWLAN/networksetup fail with -3900, so joins click the network in Control Center's Wi-Fi menu via AX.
- DND toggles with `/usr/bin/shortcuts run 'Toggle DND'`.
- Menu-bar tray icons: when the macOS bar is hidden the snapshots are blank, so app icons are used.

## Battery notes

NotchDock is event-driven to save battery (2026-11-23): yabai pings it with `notifyutil -p com.eric.notchdock.yabai` on window events, battery/volume/Wi-Fi come from IOPowerSources/CoreAudio/NWPathMonitor, CPU/RAM/temp are only sampled while the stats dropdown is open, and the auto-hide dock uses a 2 px bottom-edge strip instead of a global mouse-move monitor. Don't add fast timers or global `mouseMoved` monitors back. Power Nap is off on battery. Biggest draws are usually WindowServer (Claude app, video) and stray processes (an old ffmpeg recording once burned ~4 W). Check with `top -o power` and `pmset -g assertions`.

## Other

`editors/` shared Cursor/VS Code/Antigravity settings · `scripts/`, `codeUtility/` helpers · `wallpapers/`.
