#!/bin/sh

# Get battery percentage
PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

# Determine icon based on percentage and charging status
if [ -n "$CHARGING" ]; then
  ICON="󰂄"  # Charging icon
else
  if [ "$PERCENTAGE" -ge 90 ]; then
    ICON="󰁹"
  elif [ "$PERCENTAGE" -ge 70 ]; then
    ICON="󰂀"
  elif [ "$PERCENTAGE" -ge 50 ]; then
    ICON="󰁾"
  elif [ "$PERCENTAGE" -ge 30 ]; then
    ICON="󰁼"
  elif [ "$PERCENTAGE" -ge 10 ]; then
    ICON="󰁺"
  else
    ICON="󰂃"
  fi
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
