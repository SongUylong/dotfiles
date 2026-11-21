#!/bin/bash
# Option+N: open WeChat, Telegram, WhatsApp and Messenger (as Brave app windows) and tile
# them 2x2 on space 2:   Telegram | WhatsApp
#                        WeChat   | Messenger
# Brave app-window titles change (chat names, loading URLs), so their window ids are
# remembered in ~/.cache/chat-ws instead of matching titles.
export PATH="/opt/homebrew/bin:$PATH"
SPACE=2
BRAVE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
STATE="$HOME/.cache/chat-ws"; mkdir -p "$STATE"

wins() { yabai -m query --windows 2>/dev/null; }
exists() { [ -n "$1" ] && wins | jq -e --argjson i "$1" 'any(.[]; .id == $i)' >/dev/null; }
app_win() { wins | jq -r --arg a "$1" '[.[] | select(.app == $a)] | first | .id // empty'; }

# Opens a Brave --app window once and remembers its id.
brave_app() { # $1 = name, $2 = url
  local id; id=$(cat "$STATE/$1" 2>/dev/null)
  if exists "$id"; then echo "$id"; return; fi
  local before; before=$(wins | jq -c '[.[] | select(.app == "Brave Browser") | .id]')
  "$BRAVE" --app="$2" >/dev/null 2>&1 &
  for _ in $(seq 1 30); do
    id=$(wins | jq -r --argjson b "$before" '[.[] | select(.app == "Brave Browser" and (.id as $x | $b | index($x) | not))] | first | .id // empty')
    [ -n "$id" ] && { echo "$id" > "$STATE/$1"; echo "$id"; return; }
    sleep 0.3
  done
}

native() { # $1 = app name
  local id; id=$(app_win "$1")
  [ -z "$id" ] && open -a "$1"
  for _ in $(seq 1 30); do id=$(app_win "$1"); [ -n "$id" ] && { echo "$id"; return; }; sleep 0.3; done
}

yabai -m space --focus "$SPACE" 2>/dev/null
tg=$(native Telegram)
wc=$(native WeChat)
wa=$(brave_app whatsapp https://web.whatsapp.com)
ms=$(brave_app messenger https://www.messenger.com)

for id in $tg $wa $wc $ms; do
  [ "$(wins | jq -r --argjson i "$id" '.[] | select(.id == $i) | ."is-floating"')" = "true" ] && yabai -m window "$id" --toggle float
  yabai -m window "$id" --space "$SPACE" 2>/dev/null
done
yabai -m space --focus "$SPACE" 2>/dev/null
yabai -m space "$SPACE" --layout bsp
sleep 0.3

if [ -n "$tg" ] && [ -n "$wa" ] && [ -n "$wc" ] && [ -n "$ms" ]; then
  # Rebuild the tiling tree in a fixed order: float all four (takes them out of the tree),
  # then re-tile one by one at chosen insertion points.
  flt() { [ "$(wins | jq -r --argjson i "$1" '.[] | select(.id == $i) | ."is-floating"')" = "$2" ] || yabai -m window "$1" --toggle float; }
  for id in $tg $wa $wc $ms; do flt "$id" true; done
  sleep 0.2
  flt "$tg" false;                                   sleep 0.2
  yabai -m window "$tg" --insert east;  flt "$wa" false; sleep 0.2
  yabai -m window "$tg" --insert south; flt "$wc" false; sleep 0.2
  yabai -m window "$wa" --insert south; flt "$ms" false; sleep 0.2
  yabai -m space "$SPACE" --balance
  yabai -m window --focus "$tg"
fi
