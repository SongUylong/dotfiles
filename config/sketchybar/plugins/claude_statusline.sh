#!/bin/bash
# Claude Code status line (set in ~/.claude/settings.json -> statusLine).
# Claude Code passes JSON on stdin after each reply; its rate_limits block
# holds the account's 5-hour and weekly usage. We save that for SketchyBar's
# AI panel (no extra request to Anthropic) and print a short status line.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
CACHE="$HOME/.cache/sketchybar"; mkdir -p "$CACHE"
input=$(cat)

live=$(jq -c 'select(.rate_limits.five_hour or .rate_limits.seven_day) | {
    five: .rate_limits.five_hour.used_percentage, five_reset: .rate_limits.five_hour.resets_at,
    week: .rate_limits.seven_day.used_percentage, week_reset: .rate_limits.seven_day.resets_at }' \
  <<< "$input" 2>/dev/null)
if [ -n "$live" ]; then
  tmp="$CACHE/claude_live.json.$$"
  printf '%s' "$live" > "$tmp" && mv -f "$tmp" "$CACHE/claude_live.json"
  # repaint the panel from saved data only if it is open (never calls the API)
  [ -f "$CACHE/ai_toggle.open" ] && \
    (AI_DRAW_ONLY=1 "$HOME/.config/sketchybar/plugins/ai_usage.sh" >/dev/null 2>&1 &)
fi

jq -r '[ (.model.display_name // empty),
         (.rate_limits.five_hour.used_percentage // empty | "5h \(round)%"),
         (.rate_limits.seven_day.used_percentage // empty | "wk \(round)%") ] | join("  ·  ")' \
  <<< "$input" 2>/dev/null
