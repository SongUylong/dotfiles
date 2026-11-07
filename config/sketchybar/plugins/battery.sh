#!/bin/sh
. "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
BATT=$(pmset -g batt)
PCT=$(echo "$BATT" | grep -Eo "[0-9]+%" | cut -d% -f1)
[ -z "$PCT" ] && { sketchybar --set "$NAME" drawing=off; exit 0; }
if echo "$BATT" | grep -q 'AC Power'; then
  ICON="󰂄"; COLOR=$GREEN
elif [ "$PCT" -ge 90 ]; then ICON="󰁹"; COLOR=$GREEN
elif [ "$PCT" -ge 70 ]; then ICON="󰂀"; COLOR=$GREEN
elif [ "$PCT" -ge 50 ]; then ICON="󰁾"; COLOR=$YELLOW
elif [ "$PCT" -ge 30 ]; then ICON="󰁼"; COLOR=$PEACH
elif [ "$PCT" -ge 10 ]; then ICON="󰁺"; COLOR=$RED
else ICON="󰂃"; COLOR=$RED
fi
sketchybar --set "$NAME" icon="$ICON" icon.color=$COLOR label="${PCT}%"
