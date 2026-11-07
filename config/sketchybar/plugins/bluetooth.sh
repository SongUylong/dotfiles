#!/bin/bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

POPUP_TITLE="bluetooth.popup.title"
POPUP_SETTINGS="bluetooth.popup.settings"

update_popup() {
    # Clean up previous items
    sketchybar --remove '/bluetooth\.popup\..*/' 2>/dev/null >/dev/null

    DATA=$(system_profiler SPBluetoothDataType -json 2>/dev/null)
    STATE=$(echo "$DATA" | jq -r '.SPBluetoothDataType[0].controller_properties.controller_state // "attrib_off"')

    # Header / Title
    sketchybar --add item "$POPUP_TITLE" popup.bluetooth \
        --set "$POPUP_TITLE" \
        icon="󰂯" \
        icon.font="CaskaydiaCove Nerd Font:Bold:14.0" \
        icon.color=0xff89b4fa \
        icon.padding_left=10 \
        icon.padding_right=6 \
        label="Connected Devices" \
        label.font="SF Pro:Bold:13.0" \
        label.color=0xffffffff \
        label.padding_right=10 \
        background.drawing=off

    if [ "$STATE" != "attrib_on" ]; then
        sketchybar --add item "bluetooth.popup.dev.off" popup.bluetooth \
            --set "bluetooth.popup.dev.off" \
            icon="󰂲" \
            icon.padding_left=10 \
            icon.padding_right=6 \
            icon.color=0xfff38ba8 \
            label="Bluetooth is Off" \
            label.color=0xff6c7086 \
            label.padding_right=10 \
            background.drawing=off
    else
        # Connected devices only
        CONNECTED_RAW=$(echo "$DATA" | jq -r '
            .SPBluetoothDataType[0].device_connected // [] |
            .[] | to_entries[] |
            "\(.key)|\(.value.device_minorType // "Unknown")|\(.value.device_batteryLevelMain // "")"
        ')

        idx=0
        if [ -n "$CONNECTED_RAW" ]; then
            while IFS='|' read -r dev_name dev_type dev_batt; do
                [ -z "$dev_name" ] && continue
                idx=$((idx + 1))
                item_name="bluetooth.popup.dev.c_$idx"

                case "$dev_type" in
                Keyboard*) dev_icon="󰌌" ;;
                Mouse*) dev_icon="󰍽" ;;
                Headphones* | Audio* | Headset*) dev_icon="󰋋" ;;
                *) dev_icon="󰂱" ;;
                esac

                label_text="$dev_name"
                [ -n "$dev_batt" ] && label_text="$dev_name ($dev_batt)"

                sketchybar --add item "$item_name" popup.bluetooth \
                    --set "$item_name" \
                    icon="$dev_icon" \
                    icon.font="CaskaydiaCove Nerd Font:Bold:14.0" \
                    icon.color=0xffa6e3a1 \
                    icon.padding_left=10 \
                    icon.padding_right=6 \
                    label="$label_text" \
                    label.color=0xffcdd6f4 \
                    label.padding_right=10 \
                    background.drawing=off
            done <<<"$CONNECTED_RAW"
        else
            sketchybar --add item "bluetooth.popup.dev.none" popup.bluetooth \
                --set "bluetooth.popup.dev.none" \
                icon="󰂲" \
                icon.color=0xff6c7086 \
                icon.padding_left=10 \
                icon.padding_right=6 \
                label="No Connected Devices" \
                label.color=0xff6c7086 \
                label.padding_right=10 \
                background.drawing=off
        fi
    fi

    # Settings shortcut (Clickable)
    sketchybar --add item "$POPUP_SETTINGS" popup.bluetooth \
        --set "$POPUP_SETTINGS" \
        icon="󰒓" \
        icon.font="CaskaydiaCove Nerd Font:Bold:14.0" \
        icon.color=0xff89dceb \
        icon.padding_left=10 \
        icon.padding_right=6 \
        label="Bluetooth Settings..." \
        label.font="SF Pro:Regular:12.0" \
        label.color=0xff89dceb \
        label.padding_right=10 \
        background.drawing=off \
        click_script="open 'x-apple.systempreferences:com.apple.preferences.Bluetooth'; sketchybar --set bluetooth popup.drawing=off"
}

# Click on the bar icon toggles popup
if [ "$1" = "click" ]; then
    CURRENT_STATE=$(sketchybar --query bluetooth | jq -r '.popup.drawing // "off"')
    if [ "$CURRENT_STATE" = "on" ]; then
        sketchybar --set bluetooth popup.drawing=off
    else
        update_popup
        sketchybar --set bluetooth popup.drawing=on
    fi
    exit 0
fi

# Regular periodic update for main bar icon
STATE=$(system_profiler SPBluetoothDataType 2>/dev/null | awk -F': ' '/State:/{print $2; exit}')

if [ "$STATE" = "On" ]; then
    ICON="󰂯"
    LABEL="On"
else
    ICON="󰂲"
    LABEL="Off"
fi

sketchybar --set "${NAME:-bluetooth}" icon="$ICON" label="$LABEL"
