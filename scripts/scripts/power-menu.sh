#!/usr/bin/env bash

# Options — icon + label (same style as app launcher entries)
shutdown="󰐥  Shutdown"
reboot="󰜉  Reboot"
lock="󰌾  Lock"
suspend="󰤄  Suspend"
hibernate="󰒲  Hibernate"
logout="󰍃  Logout"

chosen=$(echo -e "$shutdown\n$reboot\n$lock\n$suspend\n$hibernate\n$logout" |
	rofi -dmenu \
		-p "  Power" \
		-theme-str '
window { width: 220px; height: 360px; }
listview { columns: 1; lines: 6; }
inputbar { enabled: false; }
' \
		-no-custom)

case "$chosen" in
"$shutdown") systemctl poweroff ;;
"$reboot") systemctl reboot ;;
"$lock")
	sleep 0.1
	swaylock
	;;
"$suspend")
	sleep 0.1
	swaylock &
	systemctl suspend
	;;
"$hibernate")
	sleep 0.1
	swaylock &
	systemctl hibernate
	;;
"$logout") hyprctl dispatch exit ;;
esac
