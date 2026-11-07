#!/usr/bin/env bash
# Fills each space pill with the icons of the apps living on it.
#  - active space: every app (up to MAX_APPS), larger, accent border
#  - other spaces: front-most app only, with "+N" for the rest
#  - empty spaces: just the number
#
# Performance:
#  - bursts of yabai events (one space switch fires 2-3) are coalesced:
#    only one run at a time, extra triggers just mark the state dirty
#  - bundle ids are cached per app name (no lsappinfo after first sight)
#  - nothing is sent to sketchybar when the result didn't change
#  - one batched sketchybar call with a short animation
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"
MAX_APPS=6

STATE_DIR="$HOME/.cache/sketchybar"; mkdir -p "$STATE_DIR"
LOCK="$STATE_DIR/ws.lock"; DIRTY="$STATE_DIR/ws.dirty"
LAST="$STATE_DIR/ws.last";  BIDS="$STATE_DIR/bundle_ids"
touch "$BIDS"

touch "$DIRTY"
if ! mkdir "$LOCK" 2>/dev/null; then
  # a run is active and will see the dirty flag; break a lock older than 3s
  [ -z "$(find "$LOCK" -maxdepth 0 -mtime -3s 2>/dev/null)" ] || exit 0
  rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

bundle_id() {   # $1=pid $2=app  -> bundle id (cached by app name)
  local b
  b="$(grep -m1 -F "$2|" "$BIDS" | cut -d'|' -f2)"
  if [ -z "$b" ]; then
    b="$(lsappinfo info -only bundleid "$1" 2>/dev/null | sed -n 's/.*="\(.*\)"/\1/p')"
    [ -n "$b" ] && printf '%s|%s\n' "$2" "$b" >> "$BIDS"
  fi
  printf '%s' "$b"
}

render() {
  local spaces_json windows_json rows
  spaces_json="$(yabai -m query --spaces 2>/dev/null)" || return
  windows_json="$(yabai -m query --windows 2>/dev/null)" || return

  # sid|display|focused|pid:app,pid:app,...  (unique apps, focused/front-most first)
  rows="$(jq -r --argjson w "$windows_json" '
    ($w | map(select(
          .["is-minimized"] == false and .["is-hidden"] == false
          and .["is-sticky"] == false
          # some apps (kitty, Electron) leave role/subrole empty for normal windows
          and ((.role // "") | IN("AXWindow", ""))
          and ((.subrole // "") | IN("AXDialog", "AXSystemDialog",
                "AXFloatingWindow", "AXSystemFloatingWindow", "AXUnknown") | not)))) as $ok
    | .[] | . as $s
    | ($ok | map(select(.space == $s.index))
           | sort_by(. as $x | [ (if $x["has-focus"] then 0 else 1 end),
                                 (($s.windows | index($x.id)) // 999) ])) as $wins
    | ($wins | reduce .[] as $x ([]; if any(.[]; .app == $x.app) then . else . + [$x] end)) as $apps
    | [ $s.index, $s.display, $s["has-focus"],
        ($apps | map("\(.pid):\(.app | gsub("[|,:]"; " "))") | join(",")) ]
    | map(tostring) | join("|")
  ' <<< "$spaces_json")" || return

  local args=() sid display focused list n show hidden scale w num_col bg border k pr item pid app b
  while IFS='|' read -r sid display focused list; do
    [ -z "$sid" ] && continue
    local bids=()
    IFS=',' read -ra items <<< "$list"
    for item in "${items[@]}"; do
      [ -z "$item" ] && continue
      pid="${item%%:*}"; app="${item#*:}"
      b="$(bundle_id "$pid" "$app")"; [ -n "$b" ] && bids+=("$b")
    done
    n=${#bids[@]}

    if [ "$focused" = "true" ]; then
      show=$(( n < MAX_APPS ? n : MAX_APPS )); scale=0.66; w=24
      num_col=$ACCENT; bg=$PILL_ACTIVE; border=2
    else
      show=$(( n < 1 ? n : 1 )); scale=0.58; w=22
      num_col=$SUBTEXT; bg=$PILL_COLOR; border=0
    fi
    hidden=$(( n - show ))

    args+=(--set "space.$sid" display="$display" icon.color=$num_col)
    if [ "$hidden" -gt 0 ]; then
      args+=(label.drawing=on label="+$hidden" label.color=$num_col)
    else
      args+=(label.drawing=off)
    fi
    if [ "$n" -eq 0 ]; then args+=(icon.padding_right=14); else args+=(icon.padding_right=8); fi

    for (( k = 1; k <= MAX_APPS; k++ )); do
      if [ "$k" -le "$show" ]; then
        pr=6; [ "$k" -eq "$show" ] && [ "$hidden" -eq 0 ] && pr=14
        args+=(--set "space.$sid.$k" drawing=on display="$display"
               icon.background.image="app.${bids[$((k-1))]}"
               icon.background.image.scale=$scale icon.width=$w
               icon.padding_left=0 icon.padding_right=0 padding_left=4 padding_right=$pr)
      else
        args+=(--set "space.$sid.$k" drawing=off)
      fi
    done
    args+=(--set "space_bg.$sid" background.color=$bg background.border_width=$border)
  done <<< "$rows"

  [ ${#args[@]} -eq 0 ] && return
  # skip redraw when nothing changed (e.g. focus moved within the same space)
  local sig="${args[*]}"
  [ -f "$LAST" ] && [ "$sig" = "$(cat "$LAST")" ] && return
  printf '%s' "$sig" > "$LAST"
  sketchybar --animate tanh 6 "${args[@]}"
}

# keep rendering until no new event arrived while we were working
while [ -f "$DIRTY" ]; do
  rm -f "$DIRTY"
  render
done
