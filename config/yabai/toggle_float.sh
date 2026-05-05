#!/usr/bin/env bash
set -euo pipefail

window_json="$(yabai -m query --windows --window)"
is_floating="$(jq -r '."is-floating"' <<< "$window_json")"

if [[ "$is_floating" == "true" ]]; then
  yabai -m window --toggle float
  yabai -m space --balance >/dev/null 2>&1 || true
  exit 0
fi

yabai -m window --toggle float

# Center the floating window instead of keeping yabai's previous/odd frame.
yabai -m window --grid 10:10:2:1:6:8
