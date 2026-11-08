#!/bin/bash
# Controls dropdown: volume, mic, Wi-Fi and Bluetooth in one popup.
#   bar pill   : volume glyph (scroll = volume, click = open/close)
#   cc_vol     : click = mute / unmute, scroll = volume
#   cc_mic     : click = mute / unmute input
#   cc_wifi    : click = Wi-Fi settings
#   cc_bt      : click = Bluetooth settings, connected devices listed below
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"
CACHE="$HOME/.cache/sketchybar"; mkdir -p "$CACHE"
MAX_DEV=4

g() { printf "$1"; }   # glyphs as byte escapes so they can't get lost
G_WIFI=$(g '\363\260\244\250'); G_WIFI_OFF=$(g '\363\260\244\255')
G_BT=$(g '\363\260\202\257');   G_BT_OFF=$(g '\363\260\202\262')
G_VOL3=$(g '\363\260\225\276'); G_VOL2=$(g '\363\260\226\200'); G_VOL1=$(g '\363\260\225\277')
G_MUTE=$(g '\363\260\226\201'); G_MIC=$(g '\363\260\215\254');  G_MIC_OFF=$(g '\363\260\215\255')
G_HEAD=$(g '\363\260\213\213'); G_KBD=$(g '\363\260\214\214');  G_MOUSE=$(g '\363\260\215\275')
G_DEV=$(g '\363\260\202\261')

bar() {    # pct -> ▰▰▰▱▱▱▱▱▱▱
  local p=${1:-0} f i out=""
  f=$(( (p * 10 + 50) / 100 )); [ "$p" -gt 0 ] && [ "$f" -eq 0 ] && f=1
  for ((i=0;i<10;i++)); do [ $i -lt $f ] && out+="▰" || out+="▱"; done
  printf '%s' "$out"
}

# ---------- audio (one AppleScript call) ----------
audio_args() {   # [vol muted mic] -> --set args for pill, cc_vol, cc_mic
  local vol=$1 muted=$2 mic=$3 gl col
  if [ -z "$vol" ]; then
    IFS=, read -r vol muted mic <<< "$(osascript -e 'set s to get volume settings' \
      -e 'return ((output volume of s) as text) & "," & ((output muted of s) as text) & "," & ((input volume of s) as text)' 2>/dev/null)"
  fi
  vol=${vol:-0}; mic=${mic:-0}
  if [ "$muted" = true ] || [ "$vol" -eq 0 ]; then gl=$G_MUTE col=$RED
  elif [ "$vol" -ge 60 ]; then gl=$G_VOL3 col=$TEXT
  elif [ "$vol" -ge 30 ]; then gl=$G_VOL2 col=$TEXT
  else gl=$G_VOL1 col=$TEXT; fi
  args+=(--set controls_toggle icon="$gl" icon.color=$col)
  if [ "$muted" = true ]; then
    args+=(--set cc_vol icon="$gl  Volume" icon.color=$RED label="$(bar 0)  muted" label.color=$RED)
  else
    args+=(--set cc_vol icon="$gl  Volume" icon.color=$BLUE label="$(bar "$vol")  $vol%" label.color=$TEXT)
  fi
  if [ "$mic" -eq 0 ]; then
    args+=(--set cc_mic icon="$G_MIC_OFF  Mic" icon.color=$RED label="$(bar 0)  muted" label.color=$RED)
  else
    args+=(--set cc_mic icon="$G_MIC  Mic" icon.color=$GREEN label="$(bar "$mic")  $mic%" label.color=$TEXT)
  fi
}

# ---------- Wi-Fi ----------
wifi_args() {
  local dev ssid ip
  dev=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
  [ -n "$dev" ] && ssid=$(ipconfig getsummary "$dev" 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2; exit}')
  [ -n "$dev" ] && ip=$(ipconfig getifaddr "$dev" 2>/dev/null)
  if [ -n "$ssid" ]; then
    args+=(--set cc_wifi icon="$G_WIFI  Wi-Fi" icon.color=$GREEN label="$ssid" label.color=$TEXT)
  elif [ -n "$ip" ]; then
    args+=(--set cc_wifi icon="$G_WIFI  Wi-Fi" icon.color=$GREEN label="Connected  ·  $ip" label.color=$TEXT)
  else
    args+=(--set cc_wifi icon="$G_WIFI_OFF  Wi-Fi" icon.color=$RED label="Not connected" label.color=$OVERLAY0)
  fi
}

# ---------- Bluetooth (system_profiler is slow: only when needed) ----------
bt_args() {
  local data state rows n=0 name type batt gl lab k
  data=$(system_profiler SPBluetoothDataType -json 2>/dev/null)
  state=$(jq -r '.SPBluetoothDataType[0].controller_properties.controller_state // "attrib_off"' <<< "$data")
  if [ "$state" = attrib_on ]; then
    rows=$(jq -r '.SPBluetoothDataType[0].device_connected // [] | .[] | to_entries[]
      | "\(.key | gsub("[|]"; " "))|\(.value.device_minorType // "")|\(.value.device_batteryLevelMain // .value.device_batteryLevelLeft // "")"' <<< "$data")
    while IFS='|' read -r name type batt; do
      [ -z "$name" ] && continue; n=$((n+1)); [ $n -gt $MAX_DEV ] && continue
      case "$type" in Keyboard*) gl=$G_KBD ;; Mouse*|Trackpad*) gl=$G_MOUSE ;;
        Headphones*|Headset*|Audio*|Speaker*) gl=$G_HEAD ;; *) gl=$G_DEV ;; esac
      lab="$name${batt:+  ·  $batt}"
      args+=(--set cc_bt$n drawing=on icon="$gl" label="$lab")
    done <<< "$rows"
    if [ $n -eq 0 ]; then lab="On  ·  no devices"
    elif [ $n -eq 1 ]; then lab="On  ·  1 device"
    else lab="On  ·  $n devices"; fi
    args+=(--set cc_bt icon="$G_BT  Bluetooth" icon.color=$BLUE label="$lab" label.color=$TEXT)
  else
    args+=(--set cc_bt icon="$G_BT_OFF  Bluetooth" icon.color=$RED label="Off" label.color=$OVERLAY0)
  fi
  for (( k = n + 1; k <= MAX_DEV; k++ )); do args+=(--set cc_bt$k drawing=off); done
}

args=()
case "${1:-$SENDER}" in
  vol_click)
    IFS=, read -r vol muted mic <<< "$(osascript -e 'set m to not (output muted of (get volume settings))' \
      -e 'set volume output muted m' -e 'set s to get volume settings' \
      -e 'return ((output volume of s) as text) & "," & (m as text) & "," & ((input volume of s) as text)' 2>/dev/null)"
    audio_args "$vol" "$muted" "$mic" ;;
  mic_click)
    osascript -e 'if (input volume of (get volume settings)) = 0 then' -e 'set volume input volume 100' \
      -e 'else' -e 'set volume input volume 0' -e 'end if' >/dev/null 2>&1
    audio_args ;;
  mouse.scrolled)
    STEP=5; [ "${SCROLL_DELTA:-0}" -lt 0 ] && STEP=-5
    osascript -e "set v to (output volume of (get volume settings)) + ($STEP)" \
      -e 'if v > 100 then set v to 100' -e 'if v < 0 then set v to 0' \
      -e 'set volume output volume v without output muted' >/dev/null 2>&1
    audio_args ;;            # volume_change also fires; this keeps the popup in step
  volume_change) audio_args ;;
  wifi_change)   wifi_args ;;
  controls_refresh|system_woke|forced) audio_args; wifi_args; bt_args ;;
  *)   # periodic: Bluetooth only while the popup is open
    audio_args; wifi_args; [ -f "$CACHE/controls_toggle.open" ] && bt_args ;;
esac
[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
exit 0
