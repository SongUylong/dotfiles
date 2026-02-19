#!/bin/bash

# Network speed monitor using netstat or ifconfig
# Get current network interface
IFACE=$(route -n get default | grep interface | awk '{print $2}')

if [ -z "$IFACE" ]; then
  sketchybar --set "$NAME" icon="󰲛" label="0/0 KB/s"
  exit 0
fi

# Get initial bytes
RX1=$(netstat -ib | grep -E "^$IFACE" | awk '{print $7}' | head -1)
TX1=$(netstat -ib | grep -E "^$IFACE" | awk '{print $10}' | head -1)

# Wait 1 second
sleep 1

# Get bytes again
RX2=$(netstat -ib | grep -E "^$IFACE" | awk '{print $7}' | head -1)
TX2=$(netstat -ib | grep -E "^$IFACE" | awk '{print $10}' | head -1)

# Calculate difference
RX_DIFF=$((RX2 - RX1))
TX_DIFF=$((TX2 - TX1))

# Convert to KB/s
RX_KB=$((RX_DIFF / 1024))
TX_KB=$((TX_DIFF / 1024))

# Format with appropriate units
format_speed() {
  local speed=$1
  if [ "$speed" -ge 1024 ]; then
    echo "$(echo "scale=1; $speed/1024" | bc)M"
  else
    echo "${speed}K"
  fi
}

RX_FMT=$(format_speed $RX_KB)
TX_FMT=$(format_speed $TX_KB)

# Network icon
ICON="󰀂"

sketchybar --set "$NAME" icon="$ICON" label="${TX_FMT}↑ ${RX_FMT}↓"
