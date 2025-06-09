#!/bin/bash

# Fetch words written this month from API
WORDS_DATA=$(curl -s "https://ejfox.com/api/words-this-month")
WORD_COUNT=$(echo "$WORDS_DATA" | jq -r '.totalWords')
MONTH=$(echo "$WORDS_DATA" | jq -r '.month')

# Format and update sketchybar
if [ -n "$WORD_COUNT" ] && [ "$WORD_COUNT" != "null" ]; then
  sketchybar --set words icon="📝" label="${WORD_COUNT}" drawing=on
else
  sketchybar --set words drawing=off
fi