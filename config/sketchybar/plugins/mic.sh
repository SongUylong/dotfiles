#!/bin/bash

# If clicked or invoked with "toggle", switch input volume
if [ "$1" = "toggle" ] || [ "$SENDER" = "mouse.clicked" ]; then
    CURRENT_VOL=$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo 0)
    if [ "$CURRENT_VOL" -eq 0 ]; then
        # Restore mic volume to 100%
        osascript -e 'set volume input volume 100'
        sketchybar --set "${NAME:-mic}" \
            icon="󰍬" \
            icon.color=0xffa6e3a1 \
            label="ON" \
            label.color=0xffa6e3a1
    else
        # Mute mic
        osascript -e 'set volume input volume 0'
        sketchybar --set "${NAME:-mic}" \
            icon="󰍭" \
            icon.color=0xfff38ba8 \
            label="OFF" \
            label.color=0xfff38ba8
    fi
    exit 0
fi

# Periodic update / mic_update event
INPUT_VOLUME=$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo 0)

if [ "$INPUT_VOLUME" -eq 0 ]; then
    sketchybar --set "${NAME:-mic}" \
        icon="󰍭" \
        icon.color=0xfff38ba8 \
        label="OFF" \
        label.color=0xfff38ba8
else
    sketchybar --set "${NAME:-mic}" \
        icon="󰍬" \
        icon.color=0xffa6e3a1 \
        label="ON" \
        label.color=0xffa6e3a1
fi
