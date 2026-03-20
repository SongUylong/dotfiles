#!/usr/bin/env bash

# Define options
shutdown="  Shutdown"
reboot="  Reboot"
lock="  Lock"
suspend="  Suspend"
logout="  Logout"

# Compile the menu options
options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

# Show menu using the custom RASI theme
chosen=$(echo -e "$options" | rofi -dmenu -theme ~/dotfiles/scripts/scripts/power-menu.rasi)

# Execute action based on choice
case "$chosen" in
    "$shutdown") systemctl poweroff ;;
    "$reboot") systemctl reboot ;;
    "$suspend") systemctl suspend ;;
    "$logout") hyprctl dispatch exit ;;
    "$lock")
        if command -v hyprlock &> /dev/null; then
            hyprlock
        elif command -v swaylock &> /dev/null; then
            swaylock
        fi
        ;;
    *) exit 1 ;;
esac
