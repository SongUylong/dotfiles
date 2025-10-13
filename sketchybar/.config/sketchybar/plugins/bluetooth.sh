#!/bin/sh

STATE=$(system_profiler SPBluetoothDataType 2>/dev/null | awk -F': ' '/State:/{print $2; exit}')

if [ "$STATE" = "On" ]; then
  ICON="󰂯"
  LABEL="On"
else
  ICON="󰂲"
  LABEL="Off"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"

