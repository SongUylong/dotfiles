#!/bin/sh

# Power pill: intake voltage (green when charging) + system load (red).
# Runs on the pw_in item and updates both segments.

BATT_INFO=$(ioreg -r -c AppleSmartBattery)

EXTERNAL_CONNECTED=$(echo "$BATT_INFO" | awk -F'"ExternalConnected" = ' '{if (NF>1) {split($2, a, "[, \n]"); print a[1]}}')
ADAPTER_MV=$(echo "$BATT_INFO" | perl -0777 -ne 'print $1 if /"AdapterDetails".*?"AdapterVoltage"=(\d+)/s')

if [ "$EXTERNAL_CONNECTED" = "Yes" ] && [ -n "$ADAPTER_MV" ] && [ "$ADAPTER_MV" -gt 0 ] 2>/dev/null; then
    INTAKE=$(awk -v mv="$ADAPTER_MV" 'BEGIN {printf "%.1fV", mv/1000}')
    ICON="󱐋"
    ICON_COLOR=0xffa6e3a1
    LABEL_COLOR=0xffa6e3a1
else
    # On battery: not charging
    INTAKE="0.0V"
    ICON="󰚥"
    ICON_COLOR=0xffa6adc8
    LABEL_COLOR=0xffa6adc8
fi

# --- Usage watts (SystemLoad, mW) ---
POWER_MW=$(echo "$BATT_INFO" | awk -F'"SystemLoad"=' '{if (NF>1) {split($2, a, "[,}]"); print a[1]}}')

if [ -n "$POWER_MW" ] && [ "$POWER_MW" -gt 0 ] 2>/dev/null; then
    USAGE=$(awk -v mw="$POWER_MW" 'BEGIN {printf "%.1fW", mw/1000}')
else
    # Fallback: calculate from Voltage (mV) * Amperage (mA)
    VOLT=$(echo "$BATT_INFO" | awk -F'"Voltage" = ' '{if (NF>1) {split($2, a, "[, \n]"); print a[1]}}')
    AMP=$(echo "$BATT_INFO" | awk -F'"Amperage" = ' '{if (NF>1) {split($2, a, "[, \n]"); print a[1]}}')
    if [ -n "$VOLT" ] && [ -n "$AMP" ]; then
        USAGE=$(awk -v v="$VOLT" -v a="$AMP" 'BEGIN {
            w = (v * a) / 1000000;
            if (w < 0) w = -w;
            printf "%.1fW", w
        }')
    else
        USAGE="--W"
    fi
fi

sketchybar --set "$NAME" icon.color="$ICON_COLOR" label="$INTAKE" label.color="$LABEL_COLOR"
sketchybar --set "${NAME%_in}_use" label="$USAGE" label.color=0xfffab387
