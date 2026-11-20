#!/bin/bash
# ~/dotfiles/config/notchdock/install.sh
# Builds NotchDock (native top bar + dock + notch file shelf), installs it to
# ~/Applications, starts it at login, hides Apple's Dock and turns SketchyBar off.
#   --no-system   only build/install the app; leave Apple's Dock and SketchyBar alone
#   --uninstall   remove NotchDock and restore Apple's Dock and SketchyBar
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/NotchDock.app"
AGENT="$HOME/Library/LaunchAgents/com.eric.notchdock.plist"
U="gui/$(id -u)"

if [[ "${1:-}" == "--uninstall" ]]; then
  launchctl bootout "$U/com.eric.notchdock" 2>/dev/null || true
  rm -f "$AGENT"; rm -rf "$APP"
  defaults delete com.apple.dock autohide-delay 2>/dev/null || true
  defaults write com.apple.dock autohide -bool false
  defaults delete com.apple.dock no-bouncing 2>/dev/null || true
  defaults delete com.apple.dock wvous-tr-corner 2>/dev/null || true
  defaults delete com.apple.dock wvous-tr-modifier 2>/dev/null || true
  killall Dock
  launchctl enable "$U/homebrew.mxcl.sketchybar"
  launchctl bootstrap "$U" "$HOME/Library/LaunchAgents/homebrew.mxcl.sketchybar.plist" 2>/dev/null || true
  echo "NotchDock removed; Apple Dock and SketchyBar restored"
  exit 0
fi

# 1. Build and bundle
(cd "$D" && swift build -c release)
mkdir -p "$APP/Contents/MacOS"
cp "$D/.build/release/NotchDock" "$APP/Contents/MacOS/NotchDock"
cp "$D/packaging/Info.plist" "$APP/Contents/Info.plist"
codesign -s - --force "$APP" >/dev/null 2>&1

# 2. Start at login (paths in the template are rewritten for this user)
mkdir -p "$(dirname "$AGENT")"
sed "s|/Users/[^/]*/Applications|$HOME/Applications|" "$D/packaging/com.eric.notchdock.plist" > "$AGENT"
launchctl bootout "$U/com.eric.notchdock" 2>/dev/null || true
sleep 1
launchctl bootstrap "$U" "$AGENT"

# 3. Replace Apple's Dock and SketchyBar
if [[ "${1:-}" != "--no-system" ]]; then
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 1000
  defaults write com.apple.dock no-bouncing -bool true
  # Top-right hot corner opens Notification Center (12), no modifier key.
  defaults write com.apple.dock wvous-tr-corner -int 12
  defaults write com.apple.dock wvous-tr-modifier -int 0
  killall Dock
  launchctl bootout "$U/homebrew.mxcl.sketchybar" 2>/dev/null || true
  launchctl disable "$U/homebrew.mxcl.sketchybar"
fi

echo "NotchDock installed and running"
