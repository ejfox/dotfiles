#!/bin/bash

# Source mystical symbols library
source "$HOME/.dotfiles/lib/mystical-symbols.sh"

# Get daily hexagram (deterministic based on date)
HEX=$(get_daily_hexagram)
HEX_NAME=$(get_daily_hexagram_name)
WISDOM=$(get_daily_hexagram_wisdom)

# Format: hexagram + short name
# Click shows full wisdom in notification
sketchybar --set $NAME icon="$HEX" label="$HEX_NAME"
