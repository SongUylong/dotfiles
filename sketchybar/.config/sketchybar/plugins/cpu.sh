#!/bin/sh

# Get CPU usage percentage
CPU_USAGE=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | cut -d% -f1)

# CPU icon
ICON=""

sketchybar --set "$NAME" icon="$ICON" label="${CPU_USAGE}%"
