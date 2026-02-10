#!/usr/bin/env bash

red='#cc241d'
green='#98971a'
blue='#458588'
yellow='#d79921'
purple='#b16286'
gray='#a89984'

shutdown="<span color='${red}'>󰐥</span>"
reboot="<span color='${green}'>󰜉</span>"
lock="<span color='${blue}'>󰌾</span>"
suspend="<span color='${yellow}'>󰤄</span>"
hibernate="<span color='${purple}'>󰒲</span>"
quit="<span color='${gray}'>✘</span>"

yes="<span color='${green}'>✔</span>"
no="<span color='${red}'>✘</span>"

theme="$HOME/.config/rofi/config.rasi"

rofi_cmd() {
	rofi -dmenu \
		-theme ${theme} \
		-markup-rows \
		-p "" \
		-mesg "" \
		-theme-str 'configuration {show-icons: false;}' \
		-theme-str 'window {width: 600px; height: 120px; border: 3px; border-color: #89b4fa; border-radius: 12px;}' \
		-theme-str 'mainbox {children: [listview]; padding: 15px;}' \
		-theme-str 'listview {lines: 1; columns: 6; spacing: 15px; cycle: false;}' \
		-theme-str 'element {padding: 15px 20px; border-radius: 10px; background-color: #313244;}' \
		-theme-str 'element selected {background-color: #89b4fa;}' \
		-theme-str 'element-text {horizontal-align: 0.5; vertical-align: 0.5; size: 40px;}' \
		-theme-str 'element-text selected {color: #1e1e2e;}'
}

run_rofi() {
	echo -e "$shutdown\n$reboot\n$lock\n$suspend\n$hibernate\n$quit" | rofi_cmd
}

confirm_cmd() {
	rofi -dmenu \
		-theme ${theme} \
		-markup-rows \
		-p "" \
		-mesg "" \
		-theme-str 'window {width: 250px; height: 120px; border: 3px; border-color: #89b4fa; border-radius: 12px;}' \
		-theme-str 'mainbox {children: [listview]; padding: 15px;}' \
		-theme-str 'listview {lines: 1; columns: 2; spacing: 15px;}' \
		-theme-str 'element {padding: 20px; border-radius: 10px; background-color: #313244;}' \
		-theme-str 'element selected {background-color: #a6e3a1;}' \
		-theme-str 'element-text {horizontal-align: 0.5; vertical-align: 0.5; size: 32px;}' \
		-theme-str 'element-text selected {color: #1e1e2e;}'
}

rofi_confirm() {
	echo -e "$yes\n$no" | confirm_cmd
}

run_cmd() {
	selected="$(rofi_confirm)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			hyprlock &
			systemctl suspend
		elif [[ $1 == '--hibernate' ]]; then
			systemctl hibernate
		fi
	else
		exit 0
	fi
}

chosen="$(run_rofi)"
case ${chosen} in
$shutdown)
	run_cmd --shutdown
	;;
$reboot)
	run_cmd --reboot
	;;
$lock)
	sleep 0.1
	swaylock
	;;
$suspend)
	sleep 0.1
	run_cmd --suspend
	;;
$hibernate)
	sleep 0.1
	run_cmd --hibernate
	;;
esac
