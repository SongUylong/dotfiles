#!/usr/bin/env bash

dir="$HOME/Pictures/Screenshots"
time=$(date +'%Y_%m_%d_at_%Hh%Mm%Ss')
file="${dir}/Screenshot_${time}.png"

if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
fi

copy() {
    GRIMBLAST_HIDE_CURSOR=0 grimblast --notify --freeze copy area
}

save() {
    GRIMBLAST_HIDE_CURSOR=0 grimblast --notify --freeze save area "$file"
}

copy_and_save() {
    # Capture once, save to file, then copy to clipboard
    GRIMBLAST_HIDE_CURSOR=0 grimblast --notify --freeze save area "$file"
    if [[ -f "$file" ]]; then
        wl-copy < "$file"
        notify-send "Screenshot" "Saved and copied to clipboard"
    fi
}

swappy_() {
    GRIMBLAST_HIDE_CURSOR=0 grimblast --notify --freeze save area "$file"
    swappy -f "$file"
}

case "$1" in
    "--copy")
        copy
        ;;
    "--save")
        save
        ;;
    "--copy-save"|"")
        copy_and_save
        ;;
    "--swappy")
        swappy_
        ;;
    *)
        echo -e "Available Options: --copy --save --copy-save --swappy"
        ;;
esac

exit 0
