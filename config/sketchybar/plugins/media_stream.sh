#!/bin/bash
# Background listener: pokes the `media` item whenever what's playing changes.
# Started (and restarted) by sketchybarrc; only one copy runs.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
PID="$HOME/.cache/sketchybar/media_stream.pid"; mkdir -p "${PID%/*}"
# stop any earlier copy (and its media-control adapter) before starting
for p in $(pgrep -f 'sketchybar/plugins/media_stream.sh'); do [ "$p" != $$ ] && kill "$p" 2>/dev/null; done
pkill -f 'media-control/mediaremote-adapter.pl' 2>/dev/null
command -v media-control >/dev/null || exit 0
echo $$ > "$PID"
media-control stream --no-artwork --debounce=300 | while IFS= read -r _; do
  sketchybar --trigger media_update
done
