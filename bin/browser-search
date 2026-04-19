#!/usr/bin/env bash

# Define the path to your new theme file
theme_path="~/dotfiles/scripts/scripts/browser-search.rasi"

# Prompt for search query using rofi
query=$(rofi -dmenu -p "🔎" -theme "$theme_path")

# If user entered something, search with Firefox
if [ -n "$query" ]; then
    firefox --search "$query"
fi
