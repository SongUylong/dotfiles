#!/usr/bin/env bash

wallpaper_path=$HOME/dotfiles/wallpapers
wallpapers_folder=$HOME/dotfiles/wallpapers
wallpaper_name="$(ls $wallpapers_folder | rofi -dmenu || pkill rofi)"

if [[ -f $wallpapers_folder/$wallpaper_name ]]; then
    ln -sf "$wallpapers_folder/$wallpaper_name" "$wallpaper_path/wallpaper"
    swww img -t none "$wallpaper_path/wallpaper"
else
    exit 1
fi
