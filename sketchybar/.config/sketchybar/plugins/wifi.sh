#!/bin/sh

NAME="wifi"
# Find WiFi device
DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

if [ -z "$DEVICE" ]; then
  # No WiFi device
  ICON="󰤭"
  LABEL=""
  ICON_COLOR="0xffe06c75" # red
else
  INFO=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}' | xargs networksetup -getairportnetwork | sed 's/Current Wi-Fi Network: //')
  if [ -z "$INFO" ] || [ "$INFO" = "Off" ] || printf "%s" "$INFO" | grep -q "^You are not associated"; then
    ALT_INFO=$(ipconfig getsummary "$DEVICE" | awk -F ' SSID : ' '/ SSID : / {print $2}')
    [ -n "$ALT_INFO" ] && INFO="$ALT_INFO"
  fi
  SSID="$INFO"
  case "$SSID" in
    ""|"Off"|"You are not associated"*)
      ICON="󰤭"
      LABEL=""
      ICON_COLOR="0xffe06c75" # red
      ;;
    *)
      ICON="󰤨"
      LABEL="$SSID"
      ICON_COLOR="0xff98c379" # green
      ;;
  esac
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL" icon.color=$ICON_COLOR

