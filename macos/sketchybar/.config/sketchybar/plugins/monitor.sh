#!/bin/sh

# Get connected display count
DISPLAY_COUNT=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -c "Display Type")

# Get list of external displays (excluding built-in)
EXTERNAL_DISPLAYS=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -A 2 "Display Type" | grep -v "Built-in" | grep "Display Type" | wc -l)

if [ "$EXTERNAL_DISPLAYS" -eq 0 ]; then
  ICON="󰹑"  # Single display (built-in only)
  LABEL="1"
elif [ "$EXTERNAL_DISPLAYS" -eq 1 ]; then
  ICON="󱡶"  # Two displays
  LABEL="2"
else
  ICON="󱡷"  # Multiple displays
  LABEL="$((EXTERNAL_DISPLAYS + 1))"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
