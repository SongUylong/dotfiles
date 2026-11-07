#!/bin/sh
# Sum of per-process CPU / core count — far cheaper than `top -l 1`
. "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
NCPU=$(sysctl -n hw.logicalcpu)
CPU=$(ps -A -o %cpu= | awk -v n="$NCPU" '{s+=$1} END {v=s/n; if (v>100) v=100; printf "%d", v}')
COLOR=$TEXT
[ "$CPU" -ge 50 ] && COLOR=$YELLOW
[ "$CPU" -ge 80 ] && COLOR=$RED
sketchybar --set "$NAME" label="${CPU}%" label.color=$COLOR
sketchybar --set stats_toggle icon.color=$( [ "$COLOR" = "$TEXT" ] && echo $GREEN || echo $COLOR )
