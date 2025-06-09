#!/bin/bash

# Fetch MonkeyType stats from API
TYPING_STATS=$(curl -s "https://ejfox.com/api/monkeytype" | jq -r '.typingStats.bestWPM')

# Format and update sketchybar
if [ -n "$TYPING_STATS" ] && [ "$TYPING_STATS" != "null" ]; then
  sketchybar --set typing icon="" label="${TYPING_STATS}" drawing=on
else
  sketchybar --set typing drawing=off
fi