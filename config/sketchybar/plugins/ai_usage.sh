#!/bin/bash
# AI usage: Claude (5h + weekly, from Anthropic's usage API via your local
# Claude Code sign-in) and Codex (5h + weekly, from Codex's own session logs).
# Shows % used and time until reset; an expired Codex window shows "reset".
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"
CACHE="$HOME/.cache/sketchybar"; mkdir -p "$CACHE"
NOW=$(date +%s)

left() {   # epoch -> "2h05m" / "3d4h" / "" if past
  local d=$(( $1 - NOW ))
  [ "$d" -le 0 ] && return
  if   [ "$d" -ge 86400 ]; then printf '%dd%dh' $((d/86400)) $((d%86400/3600))
  elif [ "$d" -ge 3600 ];  then printf '%dh%02dm' $((d/3600)) $((d%3600/60))
  else printf '%dm' $((d/60)); fi
}
col() { local p=${1%.*}; [ -z "$p" ] && { echo $SUBTEXT; return; }
  if [ "$p" -ge 85 ]; then echo $RED; elif [ "$p" -ge 60 ]; then echo $YELLOW; else echo $GREEN; fi; }
iso2epoch() { date -j -u -f '%Y-%m-%dT%H:%M:%S' "${1%%.*}" +%s 2>/dev/null; }
seg() {    # pct reset_epoch -> "29% 1h12m" | "reset"
  local p=${1%.*} r=$2 t
  [ -z "$p" ] && { printf '%s' "--"; return; }
  t=$(left "$r")
  if [ -n "$r" ] && [ -z "$t" ]; then printf 'reset'; else printf '%s%%%s' "$p" "${t:+ $t}"; fi
}

CJ="$CACHE/claude_usage.json"; CL="$CACHE/claude_live.json"; XJ="$CACHE/codex_usage.json"
# How fresh data must be: 25s while the group is open, 2 min when collapsed.
# Opening it (ai_refresh) or clicking a logo always fetches fresh.
MAXAGE=120; [ -f "$CACHE/ai_toggle.open" ] && MAXAGE=25
case "$SENDER" in ai_refresh|mouse.clicked) FORCE=1 ;; esac
stale() { [ -n "$FORCE" ] || [ ! -f "$1" ] || [ $(( NOW - $(stat -f %m "$1") )) -ge "$MAXAGE" ]; }

CB="$CACHE/claude_backoff"   # epoch until which Anthropic told us to wait (HTTP 429)
fetch_claude() {
  # Main source is Claude Code's status line (claude_statusline.sh), which
  # saves the numbers after every reply at no cost. Anthropic's usage API
  # rate-limits hard (a 429 can mean ~1h of waiting), so it is only a
  # fallback for when Claude Code hasn't run lately: data older than
  # 15 min, at most every 15 min (5 min when you click refresh).
  local age=999999 min=900 tok out code ra hdr
  [ -f "$CL" ] && [ $(( NOW - $(stat -f %m "$CL") )) -lt 900 ] && return 0
  [ -f "$CJ" ] && age=$(( NOW - $(stat -f %m "$CJ") ))
  [ -n "$FORCE" ] && min=300
  [ "$age" -lt "$min" ] && return 0
  [ -f "$CB" ] && [ "$(cat "$CB")" -gt "$NOW" ] 2>/dev/null && return 0
  tok=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
  [ -z "$tok" ] && tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
  [ -z "$tok" ] && return 0
  hdr="$CACHE/claude_hdr.$$"
  out=$(curl -s -m 6 -D "$hdr" -w '\n%{http_code}' https://api.anthropic.com/api/oauth/usage \
        -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" -H "User-Agent: claude-code")
  code=${out##*$'\n'}; out=${out%$'\n'*}
  if [ "$code" = 429 ]; then
    ra=$(awk -F': ' 'tolower($1)=="retry-after"{print $2+0}' "$hdr")
    [ "${ra:-0}" -lt 300 ] 2>/dev/null && ra=300
    echo $(( NOW + ra )) > "$CB"
  elif echo "$out" | jq -e '.five_hour' >/dev/null 2>&1; then
    printf '%s' "$out" > "$CJ"; rm -f "$CB"
  fi
  rm -f "$hdr"
}

fetch_codex() {   # same endpoint Codex's /status uses (~/.codex/auth.json sign-in)
  stale "$XJ" || return 0
  local at acc out
  at=$(jq -r '.tokens.access_token // empty' "$HOME/.codex/auth.json" 2>/dev/null)
  acc=$(jq -r '.tokens.account_id // empty' "$HOME/.codex/auth.json" 2>/dev/null)
  if [ -n "$at" ]; then
    out=$(curl -s -m 6 https://chatgpt.com/backend-api/wham/usage \
          -H "Authorization: Bearer $at" ${acc:+-H "chatgpt-account-id: $acc"} -H "User-Agent: codex-cli")
    echo "$out" | jq -e '.rate_limit.primary_window' >/dev/null 2>&1 && printf '%s' "$out" > "$XJ"
  fi
}

if [ -z "$AI_DRAW_ONLY" ]; then
  # paint the saved numbers instantly, then fetch both providers in parallel
  [ -n "$FORCE" ] && AI_DRAW_ONLY=1 "$0"
  fetch_claude & fetch_codex & wait
  NOW=$(date +%s)
fi

# ---------- Claude ----------
c5=""; c5r=""; c7=""; c7r=""
# newest of: status-line numbers (epoch resets) or API response (ISO resets)
if [ -f "$CL" ] && { [ ! -f "$CJ" ] || [ "$CL" -nt "$CJ" ]; }; then
  IFS='|' read -r c5 c5r c7 c7r <<< "$(jq -r '[.five // "", .five_reset // "", .week // "", .week_reset // ""] | map(tostring) | join("|")' "$CL")"
  c5r=${c5r%.*}; c7r=${c7r%.*}
elif [ -f "$CJ" ]; then
  read -r c5 c5iso c7 c7iso <<< "$(jq -r '[.five_hour.utilization // "", .five_hour.resets_at // "", .seven_day.utilization // "", .seven_day.resets_at // ""] | map(tostring) | join(" ")' "$CJ")"
  c5r=$(iso2epoch "$c5iso"); c7r=$(iso2epoch "$c7iso")
fi

# ---------- Codex ----------
# Live numbers from the same endpoint Codex's /status uses (your local Codex
# sign-in in ~/.codex/auth.json). Falls back to Codex's session logs, which it
# compresses (.jsonl.zst) once a session is old.
x5=""; x5r=""; x7=""; x7r=""; xres=""; xres_now=""
if [ -f "$XJ" ] && [ $(( NOW - $(stat -f %m "$XJ") )) -lt 3600 ]; then
  read -r x5 x5r x7 x7r <<< "$(jq -r '.rate_limit | [.primary_window.used_percent // "", .primary_window.reset_at // "",
      .secondary_window.used_percent // "", .secondary_window.reset_at // ""] | map(tostring) | join(" ")' "$XJ")"
  # usage-limit reset credits: total owned, and how many can be used right now
  read -r xres xres_now <<< "$(jq -r '[.rate_limit_reset_credits.available_count // "", .rate_limit_reset_credits.applicable_available_count // ""] | map(tostring) | join(" ")' "$XJ")"
else
  # fallback: newest session log (plain or zstd-compressed) that has limits
  for f in $(ls -t "$HOME"/.codex/sessions/*/*/*/rollout-*.jsonl* 2>/dev/null | head -10); do
    case "$f" in *.zst) rl=$(zstd -dcq "$f" 2>/dev/null | grep '"rate_limits"' | tail -1) ;;
                 *)     rl=$(grep '"rate_limits"' "$f" | tail -1) ;; esac
    [ -z "$rl" ] && continue
    rl=$(jq -c 'first(.. | objects | select(has("rate_limits")) | .rate_limits)' <<< "$rl" 2>/dev/null)
    read -r x5 x5r x7 x7r <<< "$(jq -r '[.primary.used_percent // "", .primary.resets_at // "", .secondary.used_percent // "", .secondary.resets_at // ""] | map(tostring) | join(" ")' <<< "$rl")"
    break
  done
fi

# ---------- draw ----------
bar() {    # pct -> ▰▰▰▱▱▱▱▱▱▱ (10 cells)
  local p=${1%.*} f i out=""; [ -z "$p" ] && p=0
  f=$(( (p * 10 + 50) / 100 )); [ "$p" -gt 0 ] && [ "$f" -eq 0 ] && f=1
  for ((i=0;i<10;i++)); do [ $i -lt $f ] && out+="▰" || out+="▱"; done
  printf '%s' "$out"
}
meter_args() {   # item pct reset_epoch -> sketchybar --set args
  local item=$1 p=${2%.*} r=$3 t
  if [ -z "$p" ]; then
    printf '%s\n' --set "$item" label="—" label.color=$OVERLAY0; return; fi
  if [ -n "$r" ] && [ "$r" -le "$NOW" ]; then
    printf '%s\n' --set "$item" label="$(bar 0)   reset ✓" label.color=$TEAL; return; fi
  t=$(left "$r")
  printf '%s\n' --set "$item" label="$(bar "$p")  ${p}%${t:+  ·  $t}" label.color="$(col "$p")"
}

max=0; for v in "$c5" "$c7" "$x5" "$x7"; do v=${v%.*}; [ -n "$v" ] && [ "$v" -gt "$max" ] && max=$v; done
tcol=$(col $max); [ "$max" -lt 60 ] && tcol=$MAUVE

args=()
while IFS= read -r l; do args+=("$l"); done < <(
  meter_args ai_c5 "$c5" "$c5r"; meter_args ai_c7 "$c7" "$c7r"
  meter_args ai_x5 "$x5" "$x5r"; meter_args ai_x7 "$x7" "$x7r")
# Codex usage-limit resets: hidden when you have none
if [ -n "$xres" ] && [ "$xres" -gt 0 ] 2>/dev/null; then
  word=resets; [ "$xres" -eq 1 ] && word=reset
  if [ "${xres_now:-0}" -gt 0 ] 2>/dev/null; then
    args+=(--set ai_xreset label="$xres available · $xres_now usable now" label.color=$GREEN icon.color=$GREEN)
  else
    args+=(--set ai_xreset label="$xres available" label.color=$TEAL icon.color=$TEAL)
  fi
else
  args+=(--set ai_xreset label="none" label.color=$OVERLAY0 icon.color=$OVERLAY0)
fi
cplan=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.subscriptionType // empty')
xplan=$(jq -r '.plan_type // empty' "$XJ" 2>/dev/null)
cap() { printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'; }
args+=(--set ai_h_claude label="Claude${cplan:+   ·   $(cap "$cplan")}"
       --set ai_h_codex  label="Codex${xplan:+   ·   $(cap "$xplan")}")
age=999999; for f in "$CJ" "$CL" "$XJ"; do [ -f "$f" ] && { a=$(( $(date +%s) - $(stat -f %m "$f") )); [ $a -lt $age ] && age=$a; }; done
if   [ $age -lt 10 ];   then ago="just now"
elif [ $age -lt 60 ];   then ago="${age}s ago"
elif [ $age -lt 3600 ]; then ago="$((age/60))m ago"
else ago="—"; fi
live_ok=; [ -f "$CL" ] && [ $(( NOW - $(stat -f %m "$CL") )) -lt 900 ] && live_ok=1
if [ -z "$live_ok" ] && [ -f "$CB" ] && [ "$(cat "$CB")" -gt "$NOW" ] 2>/dev/null; then
  args+=(--set ai_footer label="Claude rate-limited · retry $(left "$(cat "$CB")")" label.color=$PEACH)
else
  args+=(--set ai_footer label="$ago  ·  click to refresh" label.color=$OVERLAY0)
fi
sketchybar "${args[@]}" --set ai_toggle icon.color=$tcol
