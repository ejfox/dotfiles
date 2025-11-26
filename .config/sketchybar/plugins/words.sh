#!/bin/bash

# Fetch words written this month from API
WORDS_DATA=$(curl -s "https://ejfox.com/api/words-this-month")
MONTH_COUNT=$(echo "$WORDS_DATA" | jq -r '.totalWords')

# Calculate today's words by filtering posts for today's date
TODAY=$(date +"%Y-%m-%d")
TODAY_COUNT=$(echo "$WORDS_DATA" | jq -r --arg today "$TODAY" '
  [.posts[] | select(.date | startswith($today)) | .words] | add // 0
')

# Format and update sketchybar
if [ -n "$MONTH_COUNT" ] && [ "$MONTH_COUNT" != "null" ]; then
  sketchybar --set words icon="󱓧" label="${TODAY_COUNT}/${MONTH_COUNT}" drawing=on
else
  sketchybar --set words drawing=off
fi
