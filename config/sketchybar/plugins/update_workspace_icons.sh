#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

spaces_json="$(yabai -m query --spaces 2>/dev/null)"
windows_json="$(yabai -m query --windows 2>/dev/null)"

update_space() {
  local sid="$1"
  local display_id="$2"
  local focused="$3"
  local first_app icon

  first_app="$(jq -r --argjson sid "$sid" '.[] | select(.space == $sid and ."is-minimized" == false) | .app' <<< "$windows_json" | head -n 1)"

  if [ -n "$first_app" ]; then
    icon="$("$CONFIG_DIR/plugins/icon_map_fn.sh" "$first_app")"
  else
    icon="󰘔"
  fi

  if [ "$focused" = "true" ]; then
    sketchybar --set "space.$sid" \
      display="$display_id" \
      icon="$icon" \
      label.drawing=off \
      background.color=0xff1e1e2e \
      background.corner_radius=14 \
      background.border_width=0 \
      background.drawing=on \
      icon.drawing=on \
      icon.color=0xff89b4fa \
      icon.shadow.drawing=on
  else
    sketchybar --set "space.$sid" \
      display="$display_id" \
      icon="$icon" \
      label.drawing=off \
      background.color=0xff3c3e4f \
      background.corner_radius=14 \
      background.border_width=0 \
      background.drawing=on \
      icon.drawing=on \
      icon.color=0xffffffff \
      icon.shadow.drawing=off
  fi
}

jq -r '.[] | select(.index <= 7) | [.index, .display, ."has-focus"] | @tsv' <<< "$spaces_json" | while IFS=$'\t' read -r sid display_id focused; do
  update_space "$sid" "$display_id" "$focused"
done
