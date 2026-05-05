#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:$PATH"

sleep 0.8  # wait for yabai to manage the window

wins=$(yabai -m query --windows --space 3 2>/dev/null)
tg=$(echo "$wins" | jq 'first(.[] | select(.app == "Telegram"))          | .id // empty')
wa=$(echo "$wins" | jq 'first(.[] | select(.app | contains("WhatsApp"))) | .id // empty')
wc=$(echo "$wins" | jq 'first(.[] | select(.app == "WeChat"))             | .id // empty')

# Only arrange when all 3 are present on space 3
# NOTE: use explicit if-then to avoid || / && precedence pitfalls
if [ -z "$tg" ] || [ -z "$wa" ] || [ -z "$wc" ]; then
  exit 0
fi

# Desired layout:
# +----------+----------+
# |          | WhatsApp |
# | Telegram +----------+
# |          |  WeChat  |
# +----------+----------+

# Step 1: put WhatsApp next to Telegram
yabai -m window "$wa" --warp "$tg"
sleep 0.3

# Ensure Telegram & WhatsApp are SIDE BY SIDE (same y, different x)
tg_x=$(yabai -m query --windows --space 3 | jq --argjson id "$tg" '.[] | select(.id==$id) | .frame.x')
wa_x=$(yabai -m query --windows --space 3 | jq --argjson id "$wa" '.[] | select(.id==$id) | .frame.x')
if [ "$tg_x" = "$wa_x" ]; then
  # They are stacked vertically — toggle split to make them side by side
  yabai -m window --focus "$tg"
  yabai -m window --toggle split
  sleep 0.3
fi

# Step 2: put WeChat next to WhatsApp
yabai -m window "$wc" --warp "$wa"
sleep 0.3

# Ensure WhatsApp & WeChat are STACKED (same x, different y)
wa_x=$(yabai -m query --windows --space 3 | jq --argjson id "$wa" '.[] | select(.id==$id) | .frame.x')
wc_x=$(yabai -m query --windows --space 3 | jq --argjson id "$wc" '.[] | select(.id==$id) | .frame.x')
if [ "$wa_x" != "$wc_x" ]; then
  # They are side by side — toggle split to stack them
  yabai -m window --focus "$wa"
  yabai -m window --toggle split
fi
