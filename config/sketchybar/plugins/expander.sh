#!/bin/sh
# Dropdown toggle (click to open/close, like Bluetooth). Opening one closes the other.
STATE_DIR="$HOME/.cache/sketchybar"; mkdir -p "$STATE_DIR"
. "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
ALL="stats_toggle ai_toggle controls_toggle"
case "$NAME" in
  stats_toggle) EVENT=stats_refresh ;;
  ai_toggle)    EVENT=ai_refresh ;;
  controls_toggle) EVENT=controls_refresh ;;
  *) exit 0 ;;
esac

set_state() {   # set_state <toggle> on|off
  t=$1
  if [ "$2" = on ]; then
    touch "$STATE_DIR/$t.open"
    sketchybar --set "$t" popup.drawing=on background.color=$PILL_ACTIVE \
      background.border_width=1 background.border_color=$ACCENT
  else
    rm -f "$STATE_DIR/$t.open"
    sketchybar --set "$t" popup.drawing=off background.color=$PILL_COLOR background.border_width=0
  fi
  [ "$t" = ai_toggle ] && { [ "$2" = on ] && f=30 || f=300; sketchybar --set ai_footer update_freq=$f; }
}

case "${1:-$SENDER}" in
  init)  set_state "$NAME" off ;;
  mouse.scrolled) [ "$NAME" = controls_toggle ] && exec "${CONFIG_DIR:-$HOME/.config/sketchybar}/plugins/controls.sh" ;;
  mouse.clicked)
    if [ -f "$STATE_DIR/$NAME.open" ]; then set_state "$NAME" off
    else
      for o in $ALL; do [ "$o" != "$NAME" ] && [ -f "$STATE_DIR/$o.open" ] && set_state "$o" off; done
      set_state "$NAME" on
      sketchybar --trigger "$EVENT"
    fi ;;
esac
exit 0
