#!/bin/bash
# sudo ~/dotfiles/config/lid-sleep/install.sh
set -e
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D="$(cd "$(dirname "$0")" && pwd)"
install -d -o root -g wheel -m 755 /usr/local/libexec
install -o root -g wheel -m 755 "$D/lid-sleep-guard" /usr/local/libexec/lid-sleep-guard
install -o root -g wheel -m 644 "$D/com.eric.lid-sleep-guard.plist" /Library/LaunchDaemons/
launchctl bootout system/com.eric.lid-sleep-guard 2>/dev/null || true
launchctl bootstrap system /Library/LaunchDaemons/com.eric.lid-sleep-guard.plist
sleep 1; pmset -g | grep -E "SleepDisabled|^ sleep"
echo "installed"
