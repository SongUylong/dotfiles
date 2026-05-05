#!/bin/bash

# Derive the workspace id from the item name (space.<id>)
sid="${NAME#space.}"

# If FOCUSED_WORKSPACE wasn't provided by the event, detect it via yabai
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(yabai -m query --spaces --space | jq -r '.index')
fi

# Reflect focused workspace using yabai-provided state
if [ -n "$FOCUSED_WORKSPACE" ]; then
    if [ "$FOCUSED_WORKSPACE" = "$sid" ]; then
        sketchybar --set "$NAME" background.drawing=on background.color=0xff3c3e4f background.corner_radius=8 background.height=28
    else
        sketchybar --set "$NAME" background.drawing=off
    fi
fi

# Update label icons for this space when workspace changes or on any trigger
if [ -n "$sid" ]; then
    apps=$(yabai -m query --windows --space "$sid" | jq -r '.[] | select(.["is-minimized"] == false) | .app')
    if [ "${apps}" != "" ]; then
        icon_strip=" "
        while read -r app; do
            icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
        done <<< "${apps}"
        sketchybar --set "$NAME" label="$icon_strip"
    else
        sketchybar --set "$NAME" label=""
    fi
fi
