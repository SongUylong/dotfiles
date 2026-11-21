#!/bin/bash
# Keep-awake toggle.
#   Orange: never sleeps — idle, lid closed, on battery or charger — until clicked
#           off. Runs `caffeinate -dims`.
#   Grey:   normal sleep.
# Lid-closed sleep (`pmset disablesleep`) is handled by the root LaunchDaemon in
# ~/dotfiles/config/lid-sleep, which reads this pid file. Red border = orange
# but that daemon isn't installed, so closing the lid will still sleep.
source "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
PID="$HOME/.cache/sketchybar/caffeinate.pid"; mkdir -p "${PID%/*}"
g() { printf "$1"; }
G_ON=$(g '\363\260\205\266'); G_OFF=$(g '\363\260\233\212')
running() { [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null && ps -p "$(cat "$PID")" -o comm= | grep -q caffeinate; }
guard_installed() { [ -f /Library/LaunchDaemons/com.eric.lid-sleep-guard.plist ]; }

if [ "$SENDER" = mouse.clicked ]; then
  if running; then kill "$(cat "$PID")"; rm -f "$PID"
  else nohup caffeinate -dims >/dev/null 2>&1 & echo $! > "$PID"; disown; fi
fi

if running; then
  if guard_installed; then border=$PEACH; else border=$RED; fi
  sketchybar --set "$NAME" icon="$G_ON" icon.color=$PEACH background.border_color=$border background.border_width=1
else
  sketchybar --set "$NAME" icon="$G_OFF" icon.color=$OVERLAY0 background.border_width=0
fi
