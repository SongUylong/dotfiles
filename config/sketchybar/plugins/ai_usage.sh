#!/bin/bash
# AI usage: two Claude accounts (5h + weekly, from Anthropic's usage API via
# Claude Code sign-ins) and Codex (5h + weekly + free reset credits).
#   personal : default Claude Code sign-in        (~/.claude)
#   company  : CLAUDE_CONFIG_DIR=~/.claude-company (sign in: CLAUDE_CONFIG_DIR=~/.claude-company claude /login)
# Shows % used and time until reset; an expired Codex window shows "reset".
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
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

XJ="$CACHE/codex_usage.json"; XR="$CACHE/codex_resets.json"
# Claude accounts: id | keychain service | config dir
CLAUDE_ACCOUNTS=(
  "personal|Claude Code-credentials|$HOME/.claude"
  "company|Claude Code-credentials-$(printf '%s' "$HOME/.claude-company" | shasum -a 256 | cut -c1-8)|$HOME/.claude-company"
)
[ -f "$CACHE/claude_usage.json" ] && mv "$CACHE/claude_usage.json" "$CACHE/claude_personal.json"
[ -f "$CACHE/claude_renew" ] && mv "$CACHE/claude_renew" "$CACHE/claude_personal_renew"
[ -f "$CACHE/claude_backoff" ] && mv "$CACHE/claude_backoff" "$CACHE/claude_personal_backoff"
# How fresh data must be: 25s while the group is open, 2 min when collapsed.
# Opening it (ai_refresh) or clicking a logo always fetches fresh.
MAXAGE=120; [ -f "$CACHE/ai_toggle.open" ] && MAXAGE=25
case "$SENDER" in ai_refresh|mouse.clicked) FORCE=1 ;; esac
stale() { [ -n "$FORCE" ] || [ ! -f "$1" ] || [ $(( NOW - $(stat -f %m "$1") )) -ge "$MAXAGE" ]; }

fetch_claude() {   # fetch_claude <id> <keychain service> <config dir>
  # Anthropic rate-limits this endpoint hard (a 429 can mean ~1h of waiting),
  # so Claude is polled slowly: every 5 min while the panel is open, 15 min
  # otherwise, and a click only refreshes data that is at least 5 min old.
  local id=$1 svc=$2 cdir=$3
  local CJ="$CACHE/claude_$id.json" CB="$CACHE/claude_${id}_backoff" RN="$CACHE/claude_${id}_renew"
  local age=999999 min=900 tok out code ra hdr cred exp
  [ -f "$CJ" ] && age=$(( NOW - $(stat -f %m "$CJ") ))
  [ -f "$CACHE/ai_toggle.open" ] && min=300
  [ -n "$FORCE" ] && min=300
  [ "$age" -lt "$min" ] && return 0
  cred=$(security find-generic-password -s "$svc" -w 2>/dev/null)
  [ -z "$cred" ] && return 0                     # account not signed in
  # The keychain sign-in is only renewed when `claude` runs. If it has
  # expired, let Claude Code renew it with one tiny Haiku reply (at most once
  # every 30 min); an expired token otherwise gets 401/429 errors.
  exp=$(jq -r '(.claudeAiOauth.expiresAt // 0) / 1000 | floor' <<< "$cred" 2>/dev/null)
  if [ "${exp:-0}" -le $(( NOW + 120 )) ] 2>/dev/null && command -v claude >/dev/null \
     && { [ ! -f "$RN" ] || [ $(( NOW - $(stat -f %m "$RN") )) -ge 1800 ]; }; then
    touch "$RN"
    (cd "$CACHE" && CLAUDE_CONFIG_DIR="$cdir" claude -p --model haiku --max-turns 1 \
       --no-session-persistence "Reply with just: ok" >/dev/null 2>&1)
    cred=$(security find-generic-password -s "$svc" -w 2>/dev/null)
    rm -f "$CB"
  fi
  [ -f "$CB" ] && [ "$(cat "$CB")" -gt "$NOW" ] 2>/dev/null && return 0
  tok=$(jq -r '.claudeAiOauth.accessToken // empty' <<< "$cred" 2>/dev/null)
  [ -z "$tok" ] && return 0
  hdr="$CACHE/claude_hdr.$id.$$"
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
fetch_all_claude() { local a; for a in "${CLAUDE_ACCOUNTS[@]}"; do IFS='|' read -r i v d <<< "$a"; fetch_claude "$i" "$v" "$d" & done; wait; }

fetch_codex() {   # same endpoint Codex's /status uses (~/.codex/auth.json sign-in)
  stale "$XJ" || return 0
  local at acc out
  at=$(jq -r '.tokens.access_token // empty' "$HOME/.codex/auth.json" 2>/dev/null)
  acc=$(jq -r '.tokens.account_id // empty' "$HOME/.codex/auth.json" 2>/dev/null)
  if [ -n "$at" ]; then
    out=$(curl -s -m 6 https://chatgpt.com/backend-api/wham/usage \
          -H "Authorization: Bearer $at" ${acc:+-H "chatgpt-account-id: $acc"} -H "User-Agent: codex-cli")
    echo "$out" | jq -e '.rate_limit.primary_window' >/dev/null 2>&1 && printf '%s' "$out" > "$XJ"
    # free reset credits with their expiry dates (read only, never redeems)
    out=$(curl -s -m 6 https://chatgpt.com/backend-api/wham/rate-limit-reset-credits \
          -H "Authorization: Bearer $at" ${acc:+-H "chatgpt-account-id: $acc"} -H "User-Agent: codex-cli")
    echo "$out" | jq -e '.credits' >/dev/null 2>&1 && printf '%s' "$out" > "$XR"
  fi
}

if [ -z "$AI_DRAW_ONLY" ]; then
  # paint the saved numbers instantly, then fetch both providers in parallel
  [ -n "$FORCE" ] && AI_DRAW_ONLY=1 "$0"
  fetch_all_claude & fetch_codex & wait
  NOW=$(date +%s)
fi

# ---------- Claude (both accounts) ----------
claude_read() {   # claude_read <id> -> "5h|5h_reset|7d|7d_reset"
  local f="$CACHE/claude_$1.json" a b c d
  [ -f "$f" ] || { echo "|||"; return; }
  IFS='|' read -r a b c d <<< "$(jq -r '[.five_hour.utilization // "", .five_hour.resets_at // "", .seven_day.utilization // "", .seven_day.resets_at // ""] | map(tostring) | join("|")' "$f")"
  echo "$a|$(iso2epoch "$b")|$c|$(iso2epoch "$d")"
}
IFS='|' read -r c5 c5r c7 c7r <<< "$(claude_read personal)"
IFS='|' read -r w5 w5r w7 w7r <<< "$(claude_read company)"

# ---------- Codex ----------
# Live numbers from the same endpoint Codex's /status uses (your local Codex
# sign-in in ~/.codex/auth.json). Falls back to Codex's session logs, which it
# compresses (.jsonl.zst) once a session is old.
x5=""; x5r=""; x7=""; x7r=""; xres=""; xres_now=""
if [ -f "$XJ" ] && [ $(( NOW - $(stat -f %m "$XJ") )) -lt 3600 ]; then
  IFS='|' read -r x5 x5r x7 x7r <<< "$(jq -r '.rate_limit | [.primary_window.used_percent // "", .primary_window.reset_at // "",
      .secondary_window.used_percent // "", .secondary_window.reset_at // ""] | map(tostring) | join("|")' "$XJ")"
  # usage-limit reset credits: total owned, and how many can be used right now
  IFS='|' read -r xres xres_now <<< "$(jq -r '[.rate_limit_reset_credits.available_count // "", .rate_limit_reset_credits.applicable_available_count // ""] | map(tostring) | join("|")' "$XJ")"
else
  # fallback: newest session log (plain or zstd-compressed) that has limits
  for f in $(ls -t "$HOME"/.codex/sessions/*/*/*/rollout-*.jsonl* 2>/dev/null | head -10); do
    case "$f" in *.zst) rl=$(zstd -dcq "$f" 2>/dev/null | grep '"rate_limits"' | tail -1) ;;
                 *)     rl=$(grep '"rate_limits"' "$f" | tail -1) ;; esac
    [ -z "$rl" ] && continue
    rl=$(jq -c 'first(.. | objects | select(has("rate_limits")) | .rate_limits)' <<< "$rl" 2>/dev/null)
    IFS='|' read -r x5 x5r x7 x7r <<< "$(jq -r '[.primary.used_percent // "", .primary.resets_at // "", .secondary.used_percent // "", .secondary.resets_at // ""] | map(tostring) | join("|")' <<< "$rl")"
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
    # Claude's saved numbers are older than this reset: real usage is unknown
    case "$item" in ai_c*|ai_w*) printf '%s\n' --set "$item" label="$(bar 0)   waiting for data" label.color=$OVERLAY0; return ;; esac
    printf '%s\n' --set "$item" label="$(bar 0)   reset ✓" label.color=$TEAL; return; fi
  if [ -z "$r" ] && [ "$p" -eq 0 ] 2>/dev/null; then
    printf '%s\n' --set "$item" label="$(bar 0)  0%  ·  not started" label.color=$GREEN; return; fi
  t=$(left "$r")
  printf '%s\n' --set "$item" label="$(bar "$p")  ${p}%${t:+  ·  $t}" label.color="$(col "$p")"
}

max=0; for v in "$c5" "$c7" "$w5" "$w7" "$x5" "$x7"; do v=${v%.*}; [ -n "$v" ] && [ "$v" -gt "$max" ] && max=$v; done
tcol=$(col $max); [ "$max" -lt 60 ] && tcol=$MAUVE

args=()
while IFS= read -r l; do args+=("$l"); done < <(
  meter_args ai_c5 "$c5" "$c5r"; meter_args ai_c7 "$c7" "$c7r"
  meter_args ai_w5 "$w5" "$w5r"; meter_args ai_w7 "$w7" "$w7r"
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
k=0
if [ -f "$XR" ]; then
  while IFS='|' read -r title expiso; do
    [ -z "$expiso" ] && continue; k=$((k+1)); [ $k -gt 4 ] && break
    e=$(iso2epoch "$expiso"); t=$(left "$e"); d=$(date -j -f %s "$e" '+%-d %b' 2>/dev/null)
    c=$TEXT; [ -n "$e" ] && [ $(( e - NOW )) -lt 259200 ] && c=$PEACH   # < 3 days left
    args+=(--set ai_xr$k drawing=on icon="$k." label="${title%% (*}  ·  $d${t:+  ·  $t left}" label.color=$c)
  done < <(jq -r '.credits | map(select(.status == "available")) | sort_by(.expires_at) | .[] | "\(.title // "")|\(.expires_at // "")"' "$XR" 2>/dev/null)
fi
for (( j = k + 1; j <= 4; j++ )); do args+=(--set ai_xr$j drawing=off); done
plan_of() {   # keychain service -> "Pro" / "Max 5x" / ...
  security find-generic-password -s "$1" -w 2>/dev/null | jq -r '.claudeAiOauth |
    (.subscriptionType // "") as $s | (.rateLimitTier // "") as $t |
    ($s[:1] | ascii_upcase) + $s[1:] + (if ($t | test("max_[0-9]+x")) then " " + ($t | capture("max_(?<n>[0-9]+x)").n) else "" end)'
}
IFS='|' read -r _ csvc _ <<< "${CLAUDE_ACCOUNTS[0]}"; IFS='|' read -r _ wsvc _ <<< "${CLAUDE_ACCOUNTS[1]}"
cplan=$(plan_of "$csvc"); wplan=$(plan_of "$wsvc")
xplan=$(jq -r '.plan_type // empty' "$XJ" 2>/dev/null)
cap() { printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'; }
if security find-generic-password -s "$wsvc" >/dev/null 2>&1; then
  args+=(--set ai_h_claudew label="Claude Company${wplan:+   ·   $wplan}")
else
  args+=(--set ai_h_claudew label="Claude Company   ·   not signed in" --set ai_w5 label="sign in: CLAUDE_CONFIG_DIR=~/.claude-company claude" label.color=$OVERLAY0)
fi
args+=(--set ai_h_claude label="Claude Personal${cplan:+   ·   $cplan}"
       --set ai_h_codex  label="Codex${xplan:+   ·   $(cap "$xplan")}")
age=999999; for f in "$CACHE/claude_personal.json" "$CACHE/claude_company.json" "$XJ"; do [ -f "$f" ] && { a=$(( $(date +%s) - $(stat -f %m "$f") )); [ $a -lt $age ] && age=$a; }; done
if   [ $age -lt 10 ];   then ago="just now"
elif [ $age -lt 60 ];   then ago="${age}s ago"
elif [ $age -lt 3600 ]; then ago="$((age/60))m ago"
else ago="—"; fi
CB=""; for b in "$CACHE"/claude_*_backoff; do [ -f "$b" ] && [ "$(cat "$b")" -gt "$NOW" ] 2>/dev/null && CB=$b; done
if [ -n "$CB" ]; then
  who=${CB##*/claude_}; who=${who%_backoff}
  args+=(--set ai_footer label="Claude $who rate-limited · retry $(left "$(cat "$CB")")" label.color=$PEACH)
else
  args+=(--set ai_footer label="$ago  ·  click to refresh" label.color=$OVERLAY0)
fi
sketchybar "${args[@]}" --set ai_toggle icon.color=$tcol
