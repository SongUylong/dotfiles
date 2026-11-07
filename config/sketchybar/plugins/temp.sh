#!/bin/sh

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
HELPER="$CONFIG_DIR/plugins/helpers/mac_temp"

# If helper binary doesn't exist, compile it on the fly
if [ ! -x "$HELPER" ]; then
    mkdir -p "$CONFIG_DIR/plugins/helpers"
    if [ -f "$CONFIG_DIR/plugins/helpers/mac_temp.c" ]; then
        clang -O3 "$CONFIG_DIR/plugins/helpers/mac_temp.c" -framework CoreFoundation -framework IOKit -o "$HELPER" 2>/dev/null
    fi
fi

if [ -x "$HELPER" ]; then
    TEMP_VAL=$("$HELPER")
else
    # Fallback to AppleSmartBattery Temperature if available
    BATT_TEMP=$(ioreg -r -c AppleSmartBattery | awk -F'"Temperature" = ' '{if (NF>1) {split($2, a, "[, \n]"); printf "%d°C", (a[1]/100)+0.5}}')
    TEMP_VAL="${BATT_TEMP:---°C}"
fi

# Icon
ICON="󰔏"

sketchybar --set "$NAME" label="$TEMP_VAL"
