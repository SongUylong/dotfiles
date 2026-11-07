#!/bin/sh

# Available disk space on the data volume (what the user can actually use)
AVAIL_GB=$(df -g /System/Volumes/Data | awk 'NR==2 {print $4}')


sketchybar --set "$NAME" label="${AVAIL_GB}GB"
