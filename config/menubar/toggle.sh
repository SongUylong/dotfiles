#!/bin/bash
# Switch between this native bar and sketchybar. They both own the top strip,
# so only one can be visible at a time.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/menubar"
DOMAIN="gui/$(id -u)"
AGENT="$DOMAIN/homebrew.mxcl.sketchybar"
PLIST="$HOME/Library/LaunchAgents/homebrew.mxcl.sketchybar.plist"

stop_native() { pkill -f "$APP" 2>/dev/null || true; }
# brew services refuses this tap, drive launchd directly.
stop_sketchy() { launchctl bootout "$AGENT" 2>/dev/null || true; pkill -x sketchybar 2>/dev/null || true; }
start_sketchy() { launchctl bootstrap "$DOMAIN" "$PLIST" 2>/dev/null || true; }

case "${1:-}" in
  native)
    stop_sketchy
    stop_native
    sleep 1
    nohup "$APP" >/tmp/menubar.log 2>&1 &
    echo "native bar running (log: /tmp/menubar.log)"
    ;;
  sketchy)
    stop_native
    start_sketchy
    echo "sketchybar running"
    ;;
  *)
    if pgrep -f "$APP" >/dev/null; then "$0" sketchy; else "$0" native; fi
    ;;
esac
