#!/usr/bin/env bash

# Get current keyboard layout from the main keyboard device and display short code

layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap')

case "$layout" in
    *"English"*|*"US"*)
        echo "US"
        ;;
    *"Khmer"*|*"Cambodia"*|*"Khmer (Cambodia)"*)
        echo "KH"
        ;;
    *)
        echo "??"
        ;;
esac
