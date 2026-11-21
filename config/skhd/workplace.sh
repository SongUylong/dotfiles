#!/bin/bash
# Option+W: Workplace in its own Brave app window (no tabs or address bar).
# Focuses the existing window if it's already open; the window id is remembered in
# ~/.cache/chat-ws/workplace because the page title can change.
export PATH="/opt/homebrew/bin:$PATH"
URL="https://workplace.uylonglab.xyz/"
BRAVE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
STATE="$HOME/.cache/chat-ws"; mkdir -p "$STATE"
wins() { yabai -m query --windows 2>/dev/null; }

id=$(cat "$STATE/workplace" 2>/dev/null)
if [ -n "$id" ] && wins | jq -e --argjson i "$id" 'any(.[]; .id == $i)' >/dev/null; then
  yabai -m window --focus "$id" && exit 0
fi

before=$(wins | jq -c '[.[] | select(.app == "Brave Browser") | .id]')
"$BRAVE" --app="$URL" >/dev/null 2>&1 &
for _ in $(seq 1 30); do
  id=$(wins | jq -r --argjson b "$before" '[.[] | select(.app == "Brave Browser" and (.id as $x | $b | index($x) | not))] | first | .id // empty')
  [ -n "$id" ] && { echo "$id" > "$STATE/workplace"; yabai -m window --focus "$id"; exit 0; }
  sleep 0.3
done
