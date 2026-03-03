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

# Options
shutdown="󰐥  Shutdown"
reboot="󰜉  Reboot"
lock="󰌾  Lock"
suspend="󰤄  Suspend"
logout="󰍃  Logout"

# Inline rofi theme
rofi_theme="
* {
    font: \"Maple Mono NF Bold 13\";
    background-color: ${base};
    text-color: ${text};
}

window {
    width: 100%;
    border: 2px;
    border-radius: 14px;
    border-color: ${blue};
    padding: 12px;
    background-color: ${base};
    location: center;
    anchor: center;
}

mainbox {
    spacing: 8px;
    background-color: transparent;
}

inputbar {
    enabled: false;
}

listview {
    columns: 6;
    lines: 1;
    spacing: 8px;
    background-color: transparent;
    fixed-height: true;
    fixed-columns: true;
}

element {
    padding: 16px 4px;
    border-radius: 10px;
    background-color: ${surface};
    text-color: ${text};
    orientation: vertical;
    cursor: pointer;
}

element selected {
    background-color: ${blue};
    text-color: ${base};
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
