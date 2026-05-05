# NOT IN USE
for sid in $(yabai -m query --spaces | jq -r '.[] | select(.index <= 7) | .index'); do
    sketchybar --add item space.$sid left \
        --subscribe space.$sid yabai_space_change \
        --set space.$sid \
        background.color=0x44ffffff \
        background.corner_radius=5 \
        background.height=20 \
        background.drawing=off \
        label="$sid" \
        click_script="yabai -m space --focus $sid" \
        script="$CONFIG_DIR/plugins/yabai.sh $sid"
done
