#!/usr/bin/env bash
# Set brightness on all DDC/CI monitors with debounce
# Usage: brightness-set [up|down] [step]
# - Updates cache immediately (waybar feels instant)
# - Debounces ddcutil: fires only once after 500ms of no activity
# - Runs monitors sequentially to avoid I2C bus contention

DIRECTION="${1:-up}"
STEP="${2:-10}"
CACHE="/tmp/brightness-cache"
PENDING="/tmp/brightness-pending"
DAEMON_PID="/tmp/brightness-daemon.pid"

# Read current value from cache (fast) or ddcutil (slow fallback)
if [[ -f "$CACHE" ]]; then
    current=$(cat "$CACHE")
else
    current=$(ddcutil getvcp 10 --display 1 --nousb --brief --sleep-multiplier 0 2> /dev/null |
        awk '{print $4}')
    [[ -z "$current" ]] && exit 1
fi

# Calculate new value (clamp 0-100)
if [[ "$DIRECTION" == "up" ]]; then
    new=$((current + STEP))
    ((new > 100)) && new=100
else
    new=$((current - STEP))
    ((new < 0)) && new=0
fi

# No change — skip entirely
[[ "$new" -eq "$current" ]] && exit 0

# Update cache immediately so waybar reflects change right away
echo "$new" > "$CACHE"
# Write pending value (latest wins)
echo "$new" > "$PENDING"

# Kill any existing debounce daemon
if [[ -f "$DAEMON_PID" ]]; then
    old_pid=$(cat "$DAEMON_PID")
    kill "$old_pid" 2> /dev/null
    rm -f "$DAEMON_PID"
fi

# Start a new debounce daemon (500ms — short enough to feel responsive)
(
    echo "$BASHPID" > "$DAEMON_PID"
    sleep 0.5
    # Check we're still the latest daemon
    [[ "$(cat "$DAEMON_PID" 2> /dev/null)" != "$BASHPID" ]] && exit 0
    final=$(cat "$PENDING" 2> /dev/null)
    [[ -z "$final" ]] && exit 0
    rm -f "$PENDING" "$DAEMON_PID"
    # Apply sequentially to avoid I2C contention; --sleep-multiplier 0 skips unnecessary waits
    ddcutil setvcp 10 "$final" --display 1 --nousb --sleep-multiplier 0 2> /dev/null
    ddcutil setvcp 10 "$final" --display 2 --nousb --sleep-multiplier 0 2> /dev/null
) &> /dev/null &
disown
