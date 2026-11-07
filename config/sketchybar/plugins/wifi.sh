#!/bin/sh
. "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
SSID=""
[ -n "$DEVICE" ] && SSID=$(ipconfig getsummary "$DEVICE" 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2; exit}')
if [ -n "$SSID" ]; then
  sketchybar --set "$NAME" icon="󰤨" icon.color=$GREEN label="$SSID" label.drawing=on
elif [ -n "$DEVICE" ] && ipconfig getifaddr "$DEVICE" >/dev/null 2>&1; then
  # Connected but SSID hidden by macOS privacy
  sketchybar --set "$NAME" icon="󰤨" icon.color=$GREEN label.drawing=off
else
  sketchybar --set "$NAME" icon="󰤭" icon.color=$RED label.drawing=off
fi
