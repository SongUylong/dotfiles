#!/bin/sh

# Combine CPU and RAM into one compact item.
CPU_USAGE=$(top -l 1 -n 0 | awk '/CPU usage/ {gsub("%", "", $3); printf "%.0f", $3; exit}')
[ -n "$CPU_USAGE" ] || CPU_USAGE=0

VM_STATS=$(vm_stat)
PAGES_FREE=$(printf '%s\n' "$VM_STATS" | awk '/Pages free/ {gsub("\\.", "", $3); print $3; exit}')
PAGES_INACTIVE=$(printf '%s\n' "$VM_STATS" | awk '/Pages inactive/ {gsub("\\.", "", $3); print $3; exit}')
PAGES_ACTIVE=$(printf '%s\n' "$VM_STATS" | awk '/Pages active/ {gsub("\\.", "", $3); print $3; exit}')
PAGES_WIRED=$(printf '%s\n' "$VM_STATS" | awk '/Pages wired down/ {gsub("\\.", "", $4); print $4; exit}')

PAGES_FREE=${PAGES_FREE:-0}
PAGES_INACTIVE=${PAGES_INACTIVE:-0}
PAGES_ACTIVE=${PAGES_ACTIVE:-0}
PAGES_WIRED=${PAGES_WIRED:-0}

TOTAL_PAGES=$((PAGES_FREE + PAGES_INACTIVE + PAGES_ACTIVE + PAGES_WIRED))
USED_PAGES=$((PAGES_ACTIVE + PAGES_WIRED))

if [ "$TOTAL_PAGES" -gt 0 ]; then
    RAM_USAGE=$((USED_PAGES * 100 / TOTAL_PAGES))
else
    RAM_USAGE=0
fi

sketchybar --set "$NAME" label="${CPU_USAGE}%   ${RAM_USAGE}%"
