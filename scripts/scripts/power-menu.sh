#!/usr/bin/env bash

# Simple power menu with Rofi
# Options
shutdown=" Shutdown"
reboot=" Reboot"
lock=" Lock"
suspend=" Suspend"
logout=" Logout"

# Show menu
chosen=$(echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi -dmenu -p "Power Menu" -i)

# Execute action
case "$chosen" in
"$shutdown")
	systemctl poweroff
	;;
"$reboot")
	systemctl reboot
	;;
"$lock")
	if command -v hyprlock &>/dev/null; then
		hyprlock
	elif command -v swaylock &>/dev/null; then
		swaylock
	fi
	;;
"$suspend")
	systemctl suspend
	;;
"$logout")
	hyprctl dispatch exit
	;;
esac
