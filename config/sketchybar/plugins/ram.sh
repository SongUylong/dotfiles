#!/bin/sh

# Get RAM usage in GB (Active + Wired memory)
VM_STATS=$(vm_stat)
PAGE_SIZE=$(echo "$VM_STATS" | grep "page size" | awk '{print $8}')
[ -z "$PAGE_SIZE" ] && PAGE_SIZE=4096

PAGES_ACTIVE=$(echo "$VM_STATS" | grep "Pages active" | awk '{print $3}' | tr -d '.')
PAGES_WIRED=$(echo "$VM_STATS" | grep "Pages wired down" | awk '{print $4}' | tr -d '.')

RAM_GB=$(awk -v a="$PAGES_ACTIVE" -v w="$PAGES_WIRED" -v ps="$PAGE_SIZE" 'BEGIN {
    bytes = (a + w) * ps
    printf "%.1fGB", bytes / 1073741824
}')

ICON=""

sketchybar --set "$NAME" label="$RAM_GB"
