#!/usr/bin/env bash

# Minimal mutagen status - just icon, color indicates state
# Green = synced, Yellow = syncing, Red = error

MUTAGEN_SCRIPT="/Users/ejfox/code/tmux-mutagen-indicator/mutagen-indicator.sh"

if [ ! -f "$MUTAGEN_SCRIPT" ]; then
    sketchybar --set "$NAME" icon="" icon.color="0xffff6b6b" label="err" drawing=on
    exit 0
fi

export MUTAGEN_OUTPUT_FORMAT="sketchybar"
export MUTAGEN_TMUX_SHOW_STATUS=0

STATUS_JSON=$($MUTAGEN_SCRIPT 2>/dev/null)

if [ -z "$STATUS_JSON" ]; then
    sketchybar --set "$NAME" icon="" icon.color="0xffff6b6b" label="?" drawing=on
    exit 0
fi

TEXT=$(echo "$STATUS_JSON" | grep -o '"text":"[^"]*"' | cut -d'"' -f4)
TOOLTIP=$(echo "$STATUS_JSON" | grep -o '"tooltip":"[^"]*"' | cut -d'"' -f4)
COLOR=$(echo "$STATUS_JSON" | grep -o '"color":"[^"]*"' | cut -d'"' -f4)

# Check if synced or has issues
if echo "$TOOLTIP" | grep -qi "synced"; then
    # All good - just show icon, no label
    sketchybar --set "$NAME" icon="" icon.color="$COLOR" label="" drawing=on
elif echo "$TOOLTIP" | grep -qi "error\|conflict\|problem"; then
    # Error state - show icon + warning
    sketchybar --set "$NAME" icon="" icon.color="0xffff6b6b" label="!" label.color="0xffff6b6b" drawing=on
else
    # Syncing or other state - show icon only, color indicates state
    sketchybar --set "$NAME" icon="" icon.color="$COLOR" label="" drawing=on
fi
