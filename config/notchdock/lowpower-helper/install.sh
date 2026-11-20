#!/bin/bash
# sudo ~/dotfiles/config/notchdock/lowpower-helper/install.sh
# Lets NotchDock's battery pill switch Low Power Mode without a password prompt.
set -e
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
D="$(cd "$(dirname "$0")" && pwd)"
install -d -o root -g wheel -m 755 /usr/local/libexec
install -o root -g wheel -m 755 "$D/lowpower-helper" /usr/local/libexec/lowpower-helper
install -o root -g wheel -m 644 "$D/com.eric.lowpower-helper.plist" /Library/LaunchDaemons/
launchctl bootout system/com.eric.lowpower-helper 2>/dev/null || true
launchctl bootstrap system /Library/LaunchDaemons/com.eric.lowpower-helper.plist
echo "installed"
