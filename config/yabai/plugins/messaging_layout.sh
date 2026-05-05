#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:$PATH"

sleep 0.8  # wait for yabai to manage the window

wins=$(yabai -m query --windows --space 3 2>/dev/null)
tg=$(echo "$wins" | jq 'first(.[] | select(.app == "Telegram"))             | .id // empty')
wa=$(echo "$wins" | jq 'first(.[] | select(.app | contains("WhatsApp")))    | .id // empty')
wc=$(echo "$wins" | jq 'first(.[] | select(.app == "WeChat"))               | .id // empty')

# Only arrange when all 3 are present
[ -z "$tg" ] || [ -z "$wa" ] || [ -z "$wc" ] && exit 0

# Desired layout:
# +----------+----------+
# |          | WhatsApp |
# | Telegram +----------+
# |          |  WeChat  |
# +----------+----------+

# Step 1: Warp WhatsApp adjacent to Telegram
yabai -m window "$wa" --warp "$tg"
sleep 0.2

# Ensure Telegram & WhatsApp are side-by-side (vertical split line)
tg_x=$(yabai -m query --windows --space 3 | jq --argjson id "$tg" '.[] | select(.id==$id) | .frame.x')
wa_x=$(yabai -m query --windows --space 3 | jq --argjson id "$wa" '.[] | select(.id==$id) | .frame.x')
if [ "$tg_x" = "$wa_x" ]; then
  yabai -m window --focus "$tg"
  yabai -m window --toggle split
  sleep 0.2
fi

# Step 2: Warp WeChat adjacent to WhatsApp
yabai -m window "$wc" --warp "$wa"
sleep 0.2

# Ensure WhatsApp & WeChat are stacked (horizontal split line)
wa_x=$(yabai -m query --windows --space 3 | jq --argjson id "$wa" '.[] | select(.id==$id) | .frame.x')
wc_x=$(yabai -m query --windows --space 3 | jq --argjson id "$wc" '.[] | select(.id==$id) | .frame.x')
if [ "$wa_x" != "$wc_x" ]; then
  yabai -m window --focus "$wa"
  yabai -m window --toggle split
fi
