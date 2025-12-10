#!/bin/sh

# The $NAME variable is provided by SketchyBar and contains the invoking item name.
# Example output: Mon 13 Oct 14:05 (24h)
sketchybar --set "$NAME" label="$(date '+%a %d %b %I:%M %p')"
