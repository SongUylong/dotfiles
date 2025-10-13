#!/usr/bin/env bash

sid=$1
NAME="space.$sid"

# Hide icon briefly to avoid duplication glitch
sketchybar --set "$NAME" icon.drawing=off

# Get the first app name in the workspace
apps=$(aerospace list-windows --workspace "$sid" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

if [ -n "$apps" ]; then
  first_app=$(echo "$apps" | head -n 1)
  icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$first_app")"
else
  icon="󰘔" # default empty workspace icon
fi

# Set the workspace icon (label always off)
sketchybar --set "$NAME" icon="$icon" label.drawing=off

# Check which workspace is focused
focused_ws=$(aerospace list-workspaces --focused)

if [ "$sid" = "$focused_ws" ]; then
  # Active workspace — show icon, darker background
  sketchybar --set "$NAME" \
    background.color=0xff1e1e2e \
    background.corner_radius=14 \
    background.border_width=0 \
    background.drawing=on \
    icon.drawing=on \
    icon.color=0xff89b4fa \
    icon.shadow.drawing=on
else
  # Inactive workspace — show icon, normal background
  sketchybar --set "$NAME" \
    background.color=0xff3c3e4f \
    icon.color=0xffffffff \
    background.corner_radius=14 \
    background.border_width=0 \
    background.drawing=on \
    icon.drawing=on \
    icon.shadow.drawing=off
fi
