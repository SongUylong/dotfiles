#!/usr/bin/env bash
# Outputs brightness for waybar — reads from cache, never blocks on ddcutil

CACHE="/tmp/brightness-cache"

# If no cache yet, show placeholder and seed it in background
if [[ ! -f "$CACHE" ]]; then
	echo '{"text": "󰃟 --", "tooltip": "Loading...", "class": ""}'
	# --brief output: "VCP 10 C <current> <max>" — awk grabs field 4
	ddcutil getvcp 10 --display 1 --nousb --brief --sleep-multiplier 0 2>/dev/null |
		awk '{print $4}' >"$CACHE" &
	exit 0
fi

val=$(cat "$CACHE")

if [[ "$val" -ge 67 ]]; then
	icon="󰃠"
elif [[ "$val" -ge 34 ]]; then
	icon="󰃟"
else
	icon="󰃞"
fi

echo "{\"text\": \"${icon} ${val}%\", \"tooltip\": \"Brightness: ${val}%\", \"class\": \"\"}"
