#!/bin/bash
# Now playing from any app (Spotify, Music, YouTube in a browser, ...) via
# `media-control` (brew), which still works on macOS 15.4+ where SketchyBar's
# own media_change event doesn't. Updates come from plugins/media_stream.sh.
#   click = play / pause, right-click = next track
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
source "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
command -v media-control >/dev/null || { sketchybar --set "$NAME" drawing=off; exit 0; }

if [ "$SENDER" = mouse.clicked ]; then
  if [ "$BUTTON" = right ]; then media-control next-track; else media-control toggle-play-pause; fi
  sleep 0.3
fi

IFS=$'\t' read -r playing bundle title artist <<< "$(media-control get --no-artwork 2>/dev/null |
  jq -r 'if . == null then "" else [(.playing|tostring), (.bundleIdentifier // ""), (.title // ""), (.artist // "")] | @tsv end')"

if [ -z "$title" ]; then sketchybar --set "$NAME" drawing=off; exit 0; fi

# just a short bit of the title: drop "(live)" / "[MV]" style extras, cap at 18 chars
short=$(printf '%s' "$title" | sed -E 's/ *[([][^])]*[])]//g; s/^ +| +$//g')
[ -z "$short" ] && short=$title
[ ${#short} -gt 18 ] && short="${short:0:17}…"

if [ "$playing" = true ]; then lcol=$TEXT; img=1.0; else lcol=$OVERLAY0; img=0.5; fi
sketchybar --set "$NAME" drawing=on \
  icon="" icon.width=22 icon.background.drawing=on icon.background.color=0x00000000 \
  icon.background.image="app.$bundle" icon.background.image.drawing=on icon.background.image.scale=0.5 \
  icon.background.image.border_width=0 \
  label="$short" label.color=$lcol
