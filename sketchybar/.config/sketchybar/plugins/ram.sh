#!/bin/sh

# Get RAM usage percentage
# Using vm_stat to calculate memory usage
VM_STATS=$(vm_stat)
PAGE_SIZE=$(vm_stats | grep "page size" | awk '{print $8}')
if [ -z "$PAGE_SIZE" ]; then
  PAGE_SIZE=4096
fi

PAGES_FREE=$(echo "$VM_STATS" | grep "Pages free" | awk '{print $3}' | tr -d '.')
PAGES_INACTIVE=$(echo "$VM_STATS" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
PAGES_ACTIVE=$(echo "$VM_STATS" | grep "Pages active" | awk '{print $3}' | tr -d '.')
PAGES_WIRED=$(echo "$VM_STATS" | grep "Pages wired down" | awk '{print $4}' | tr -d '.')

# Calculate used and total memory
USED_PAGES=$((PAGES_ACTIVE + PAGES_WIRED))
TOTAL_PAGES=$((PAGES_FREE + PAGES_INACTIVE + PAGES_ACTIVE + PAGES_WIRED))

# Calculate percentage
RAM_USAGE=$(echo "scale=0; $USED_PAGES * 100 / $TOTAL_PAGES" | bc)

# RAM icon
ICON=""

sketchybar --set "$NAME" icon="$ICON" label="${RAM_USAGE}%"
