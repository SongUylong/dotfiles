#!/bin/bash
# ~/dotfiles/config/port-killer/install.sh
# Builds PortKiller (menu bar list of dev-server ports with stop buttons) into ~/Applications
# and (re)starts it.
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/PortKiller.app"
mkdir -p "$APP/Contents/MacOS"
swiftc -O "$D/main.swift" -o "$APP/Contents/MacOS/PortKiller"
cp "$D/packaging/Info.plist" "$APP/Contents/Info.plist"
ID="$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/{print $2; exit}')"
codesign -s "${ID:--}" --force --timestamp=none "$APP" >/dev/null 2>&1
pkill -x PortKiller 2>/dev/null || true
sleep 0.5
open "$APP"
echo "PortKiller installed and running"
