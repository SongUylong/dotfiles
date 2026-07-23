#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

spaces_json="$(yabai -m query --spaces 2>/dev/null)"
windows_json="$(yabai -m query --windows 2>/dev/null)"

update_space() {
  local sid="$1"
  local display_id="$2"
  local focused="$3"
  local first_app icon_path

  sketchybar --query "space.$sid" &>/dev/null || return 0

  first_app="$(jq -r --argjson sid "$sid" \
    '.[] | select(.space == $sid and .["is-minimized"] == false) | .app' \
    <<< "$windows_json" | head -n 1)"

  # Get the PNG path for this app (empty string = no icon found)
  if [ -n "$first_app" ]; then
    icon_path="$("$CONFIG_DIR/plugins/icon_map_fn.sh" "$first_app")"
  fi

  if [ -n "$icon_path" ]; then
    # Real app logo via background.image
    if [ "$focused" = "true" ]; then
      sketchybar --set "space.$sid" \
        display="$display_id" \
        icon="" \
        icon.drawing=off \
        label.drawing=off \
        background.image="$icon_path" \
        background.image.drawing=on \
        background.image.scale=1.0 \
        background.color=0xff1e1e2e \
        background.corner_radius=14 \
        background.border_width=2 \
        background.border_color=0xff89b4fa \
        background.height=28 \
        background.drawing=on
    else
      sketchybar --set "space.$sid" \
        display="$display_id" \
        icon="" \
        icon.drawing=off \
        label.drawing=off \
        background.image="$icon_path" \
        background.image.drawing=on \
        background.image.scale=1.0 \
        background.color=0xff3c3e4f \
        background.corner_radius=14 \
        background.border_width=0 \
        background.height=28 \
        background.drawing=on
    fi
  else
    # Nerd font fallback (no PNG available)
    local icon="󰘔"
    case "$first_app" in
      "Brave Browser"|"Brave")   icon="󰈹" ;;
      "Google Chrome")           icon="" ;;
      "Firefox")                 icon="󰈹" ;;
      "Safari")                  icon="" ;;
      "kitty"|"kitty"|"WezTerm")  icon="󰄛" ;;
      "iTerm2"|"Terminal")       icon="" ;;
      "Visual Studio Code")      icon="󰨞" ;;
      "Cursor")                  icon="󰅩" ;;
      "Xcode")                   icon="" ;;
      "Antigravity"|"Gemini")    icon="󱙺" ;;
      "Telegram")                icon="󰏪" ;;
      "Spotify")                 icon="󰓇" ;;
      "WhatsApp"|"WeChat")       icon="󰖣" ;;
      "Discord")                 icon="󰙯" ;;
      "Docker")                  icon="󰡨" ;;
      "Postman")                 icon="󱂛" ;;
      "Finder")                  icon="󰀶" ;;
      "")                        icon="󰘔" ;;
    esac
    if [ "$focused" = "true" ]; then
      sketchybar --set "space.$sid" \
        display="$display_id" \
        icon="$icon" \
        icon.drawing=on \
        icon.color=0xff89b4fa \
        icon.shadow.drawing=on \
        label.drawing=off \
        background.image.drawing=off \
        background.color=0xff1e1e2e \
        background.corner_radius=14 \
        background.border_width=0 \
        background.height=28 \
        background.drawing=on
    else
      sketchybar --set "space.$sid" \
        display="$display_id" \
        icon="$icon" \
        icon.drawing=on \
        icon.color=0xffffffff \
        icon.shadow.drawing=off \
        label.drawing=off \
        background.image.drawing=off \
        background.color=0xff3c3e4f \
        background.corner_radius=14 \
        background.border_width=0 \
        background.height=28 \
        background.drawing=on
    fi
  fi
}

jq -r '.[] | [.index, .display, .["has-focus"]] | @tsv' <<< "$spaces_json" | \
  while IFS=$'\t' read -r sid display_id focused; do
    update_space "$sid" "$display_id" "$focused"
  done
