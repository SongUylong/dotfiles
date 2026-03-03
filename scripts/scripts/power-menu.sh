#!/usr/bin/env bash

# Catppuccin Mocha colors
base="#1e1e2e"
surface="#313244"
text="#cdd6f4"
blue="#89b4fa"
red="#f38ba8"
green="#a6e3a1"
yellow="#f9e2af"
peach="#fab387"
mauve="#cba6f7"

# Options - icons only
shutdown="󰐥"
reboot="󰜉"
lock="󰌾"
suspend="󰤄"
logout="󰍃"

# Inline rofi theme
rofi_theme="
* {
    font: \"Maple Mono NF Bold 48\";
    background-color: ${base};
    text-color: ${text};
    fg-col: ${text};
    fg-col2: ${base};
    selected-col: ${blue};
    green: ${green};
    border-col: ${blue};
    grey: #6c7086;
    element-bg: ${surface};
    element-alternate-bg: ${base};
}

window {
    border: 2px;
    border-color: @border-col;
    background-color: ${base};
    location: center;
    anchor: center;
    width: 600px;
    height: 140px;
}

mainbox {
    background-color: ${base};
    padding: 12px;
}

inputbar {
    enabled: false;
}

listview {
    columns: 5;
    lines: 1;
    spacing: 12px;
    background-color: transparent;
    fixed-height: true;
    fixed-columns: true;
    cycle: true;
}

element {
    padding: 20px 16px;
    background-color: @element-bg;
    text-color: @fg-col;
    orientation: vertical;
    cursor: pointer;
    border-radius: 8px;
}

element selected {
    background-color: @selected-col;
    text-color: @fg-col2;
}

element-text {
    horizontal-align: 0.5;
    vertical-align: 0.5;
    background-color: transparent;
    text-color: inherit;
}
"

chosen=$(echo -e "$shutdown\n$reboot\n$lock\n$suspend\n$logout" |
	rofi -dmenu \
		-p "" \
		-theme-str "${rofi_theme}" \
		-no-custom)

case "$chosen" in
"$shutdown")
	systemctl poweroff
	;;
"$reboot")
	systemctl reboot
	;;
"$lock")
	sleep 0.1
	swaylock
	;;
"$suspend")
	sleep 0.1
	swaylock &
	systemctl suspend
	;;
"$logout")
	hyprctl dispatch exit
	;;
esac
