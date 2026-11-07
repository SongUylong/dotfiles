#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"

is_hidden="$(sketchybar --query bar 2>/dev/null | jq -r '.hidden // "off"')"

if [[ "$is_hidden" == "on" ]]; then
  sketchybar --bar hidden=off
  yabai -m config external_bar all:40:0
  yabai -m config top_padding 10
else
  sketchybar --bar hidden=on
  yabai -m config external_bar off:0:0
  yabai -m config top_padding 0
fi
