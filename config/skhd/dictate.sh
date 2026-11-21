#!/bin/bash
# Ctrl+Space dictation: first press shows a floating waveform pill and records,
# second press transcribes locally with whisper.cpp, copies to the clipboard
# and pastes at the cursor (DICTATE_PASTE=0 to only copy).
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
DIR="$HOME/.cache/dictate"; mkdir -p "$DIR"
MODEL="${DICTATE_MODEL:-$HOME/.local/share/whisper/ggml-large-v3-turbo-q5_0.bin}"
[ -f "$MODEL" ] || MODEL="$HOME/.local/share/whisper/ggml-base.en.bin"
HUD="$DIR/dictate-hud"; PID="$DIR/hud.pid"; WAV="$DIR/rec.wav"

note() { osascript -e "display notification \"$1\" with title \"Dictation\"" >/dev/null 2>&1; }

# (re)build the HUD when the source is newer than the binary
if [ ! -x "$HUD" ] || [ "$HERE/dictate-hud.swift" -nt "$HUD" ]; then
  swiftc -O "$HERE/dictate-hud.swift" -o "$HUD" 2>"$DIR/build.log" || { note "HUD build failed"; exit 1; }
fi

if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then
  hud=$(cat "$PID"); rm -f "$PID"
  kill -USR1 "$hud"                                   # stop recording, show dots
  for _ in $(seq 50); do [ -f "$WAV.done" ] && break; sleep 0.05; done
  if [ -f "$MODEL" ]; then
    text=$(whisper-cli -m "$MODEL" -f "$WAV" -l auto -nt -np 2>/dev/null \
           | sed 's/^[[:space:]]*//' | tr '\n' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  else text=""; note "No whisper model in ~/.local/share/whisper"; fi
  kill -TERM "$hud" 2>/dev/null
  if [ -n "$text" ]; then
    printf '%s' "$text" | pbcopy                       # stays on the clipboard too
    [ "${DICTATE_PASTE:-1}" = 1 ] && osascript -e 'tell application "System Events" to keystroke "v" using command down' >/dev/null 2>&1
  fi
else
  rm -f "$WAV" "$WAV.done"
  "$HUD" "$WAV" >/dev/null 2>&1 &
  echo $! > "$PID"
fi
