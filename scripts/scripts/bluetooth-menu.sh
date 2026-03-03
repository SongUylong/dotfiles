#!/usr/bin/env bash
# Bluetooth rofi dropdown — no GUI app needed
# Shows BT power toggle + all paired devices with connect/disconnect actions

# Catppuccin Mocha colors (matches power-menu style)
base="#1e1e2e"
surface="#313244"
surface1="#45475a"
text="#cdd6f4"
blue="#89b4fa"
sapphire="#74c7ec"
red="#f38ba8"
green="#a6e3a1"
overlay="#6c7086"

# ── Gather state ──────────────────────────────────────────────
bt_powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')

if [[ "$bt_powered" != "yes" ]]; then
	bt_status="󰂲  Bluetooth: OFF"
	toggle_label="󰂯  Turn On"
else
	bt_status="󰂯  Bluetooth: ON"
	toggle_label="󰂲  Turn Off"
fi

# Build device list: "icon  Name  [connected]"
declare -a device_labels
declare -A device_mac  # label → MAC
declare -A device_conn # label → yes/no

while IFS= read -r line; do
	mac=$(echo "$line" | awk '{print $2}')
	name=$(echo "$line" | cut -d' ' -f3-)
	connected=$(bluetoothctl info "$mac" 2>/dev/null | awk '/Connected:/{print $2}')

	if [[ "$connected" == "yes" ]]; then
		label="󰂱  $name  ●"
	else
		label="󰂰  $name"
	fi

	device_labels+=("$label")
	device_mac["$label"]="$mac"
	device_conn["$label"]="$connected"
done < <(bluetoothctl devices 2>/dev/null)

# ── Rofi theme (matches power-menu pill aesthetic) ────────────
rofi_theme="
* {
    font: \"Maple Mono NF Bold 13\";
    background-color: ${base};
    text-color: ${text};
}

window {
    width: 320px;
    border: 2px;
    border-radius: 14px;
    border-color: ${sapphire};
    padding: 10px;
    background-color: ${base};
    location: northeast;
    anchor: northeast;
    x-offset: -8px;
    y-offset: 48px;
}

mainbox {
    spacing: 6px;
    background-color: transparent;
}

inputbar {
    enabled: false;
}

message {
    padding: 6px 10px;
    border-radius: 8px;
    background-color: ${surface};
}

textbox {
    text-color: ${sapphire};
    background-color: transparent;
    font: \"Maple Mono NF Bold 12\";
}

listview {
    lines: 8;
    scrollbar: false;
    spacing: 4px;
    background-color: transparent;
}

element {
    padding: 8px 12px;
    border-radius: 8px;
    background-color: transparent;
    text-color: ${text};
    cursor: pointer;
}

element:hover {
    background-color: ${surface};
}

element selected {
    background-color: ${sapphire};
    text-color: ${base};
}

element-text {
    vertical-align: 0.5;
    background-color: transparent;
    text-color: inherit;
}
"

# ── Build menu ─────────────────────────────────────────────────
menu_items="$toggle_label"
if [[ ${#device_labels[@]} -gt 0 ]]; then
	menu_items+="\n──────────────────"
	for lbl in "${device_labels[@]}"; do
		menu_items+="\n$lbl"
	done
fi

# ── Show rofi ─────────────────────────────────────────────────
chosen=$(echo -e "$menu_items" |
	rofi -dmenu \
		-p "" \
		-mesg "$bt_status" \
		-theme-str "$rofi_theme" \
		-no-custom)

[[ -z "$chosen" ]] && exit 0

# ── Handle selection ──────────────────────────────────────────
if [[ "$chosen" == "$toggle_label" ]]; then
	if [[ "$bt_powered" == "yes" ]]; then
		bluetoothctl power off
	else
		bluetoothctl power on
	fi
elif [[ -n "${device_mac[$chosen]+x}" ]]; then
	mac="${device_mac[$chosen]}"
	conn="${device_conn[$chosen]}"
	if [[ "$conn" == "yes" ]]; then
		bluetoothctl disconnect "$mac"
	else
		bluetoothctl connect "$mac"
	fi
fi
