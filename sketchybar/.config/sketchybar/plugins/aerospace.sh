#!/usr/bin/env bash

# Render workspaces as circles
# - Inactive: gray filled circle
# - Active: macOS blue filled circle
# The parent config hides labels; we also hide icons to keep clean dots.
#
# This script is invoked with a single argument: the workspace id (sid)
# It self-detects the currently focused workspace using the Aerospace CLI
# so it does not rely on external environment variables.

sid="$1"
focused_sid="$(aerospace list-workspaces --format "%{id} %{workspace-is-focused}" | awk '$2=="true" {print $1; exit}')"

if [ "$sid" = "$focused_sid" ]; then
  sketchybar --set "$NAME" \
    icon.drawing=off \
    background.drawing=on \
    background.height=18 \
    background.width=18 \
    background.corner_radius=9 \
    background.color=0xff007aff \
    background.border_width=0 \
    label.shadow.drawing=off \
    icon.shadow.drawing=off
else
  sketchybar --set "$NAME" \
    icon.drawing=off \
    background.drawing=on \
    background.height=18 \
    background.width=18 \
    background.corner_radius=9 \
    background.color=0x663c3e4f \
    background.border_width=0 \
    label.shadow.drawing=off \
    icon.shadow.drawing=off
fi