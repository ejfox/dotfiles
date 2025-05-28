#!/bin/bash

# Fetch MonkeyType stats from API
TYPING_STATS=$(curl -s "https://ejfox.com/api/stats" | jq -r '.monkeyType.typingStats.bestWPM')

# Format and update sketchybar
if [ -n "$TYPING_STATS" ] && [ "$TYPING_STATS" != "null" ]; then
  sketchybar --set $NAME icon="" label="${TYPING_STATS}" drawing=on
else
  sketchybar --set $NAME drawing=off
fi