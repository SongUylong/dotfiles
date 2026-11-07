#!/bin/bash

# Update volume icon and label helper
update_icon() {
    vol="$1"
    muted="$2"

    if [ -z "$muted" ]; then
        muted=$(osascript -e "output muted of (get volume settings)" 2>/dev/null)
    fi

    if [ "$muted" = "true" ]; then
        sketchybar --set "${NAME:-volume}" icon="󰖁" icon.color=0xfff38ba8 label="Muted"
        return
    fi

    case "$vol" in
    [6-9][0-9] | 100)
        icon="󰕾"
        ;;
    [3-5][0-9])
        icon="󰖀"
        ;;
    [1-9] | [1-2][0-9])
        icon="󰕿"
        ;;
    *)
        icon="󰖁"
        ;;
    esac
    sketchybar --set "${NAME:-volume}" icon="$icon" icon.color=0xffcdd6f4 label="$vol%"
}

case "$SENDER" in
"volume_change")
    update_icon "$INFO"
    ;;
"mouse.clicked")
    # one AppleScript call: toggle mute, return the new state
    MUTED=$(osascript -e 'set m to not (output muted of (get volume settings))' \
                      -e 'set volume output muted m' -e 'm' 2>/dev/null)
    if [ "$MUTED" = "true" ]; then update_icon 0 true
    else update_icon "$(osascript -e 'output volume of (get volume settings)')" false; fi
    ;;
"mouse.scrolled")
    DELTA="${SCROLL_DELTA:-0}"
    if [ "$DELTA" -eq 0 ] && [ -n "$INFO" ]; then
        DELTA=$(echo "$INFO" | jq -r '.delta // .scroll_delta // 0' 2>/dev/null)
    fi
    STEP=5; [ "$DELTA" -lt 0 ] && STEP=-5
    # one AppleScript call: unmute + step + clamp. volume_change then updates the icon.
    osascript -e "set v to (output volume of (get volume settings)) + ($STEP)" \
              -e 'if v > 100 then set v to 100' -e 'if v < 0 then set v to 0' \
              -e 'set volume output volume v without output muted' >/dev/null 2>&1
    ;;
*)
    CURRENT_VOL=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
    update_icon "$CURRENT_VOL"
    ;;
esac
