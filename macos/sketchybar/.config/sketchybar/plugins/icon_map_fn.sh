#!/bin/bash
app="$1"

case "$app" in
    # Browsers
    "Safari") echo "" ;;
    "Google Chrome") echo "" ;;
    "Arc") echo "󰈹" ;;
    "Firefox") echo "󰈹" ;;

    # Terminals
    "WezTerm") echo "" ;;
    "iTerm2" | "Terminal") echo "" ;;
    "Alacritty") echo "" ;;

    # Editors
    "Visual Studio Code") echo "󰨞" ;;
    "Xcode") echo "" ;;
    "Neovide" | "Neovim") echo "" ;;

    # Chat
    "Discord") echo "󰙯" ;;
    "Slack") echo "󰒱" ;;
    "Telegram") echo "󰏪" ;;
    "Messages") echo "󰍩" ;;

    # Media
    "Spotify") echo "󰓇" ;;
    "Music") echo "󰎈" ;;
    "YouTube Music") echo "󰎇" ;;

    # Misc
    "Finder") echo "󰀶" ;;
    "Notion") echo "󰈙" ;;
    "Obsidian") echo "󰋘" ;;
    *) echo "󰘔" ;;
esac
