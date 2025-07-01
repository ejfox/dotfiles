#!/bin/bash

# Get current month and year
CURRENT_MONTH=$(date +"%Y-%m")

# Fetch MonkeyType stats from API
API_RESPONSE=$(curl -s "https://ejfox.com/api/monkeytype")

# Get ALL recent tests from API (these are personal bests, but we can still use them)
ALL_TESTS=$(echo "$API_RESPONSE" | jq -r '.typingStats.recentTests[]')

# Find this month's best from available data
THIS_MONTH_BEST=$(echo "$API_RESPONSE" | jq -r --arg month "$CURRENT_MONTH" '
  .typingStats.recentTests[] | 
  select(.timestamp | startswith($month)) | 
  .wpm' | sort -nr | head -1)

# Current month display logic
if [ -n "$THIS_MONTH_BEST" ] && [ "$THIS_MONTH_BEST" != "" ]; then
  # We have data for this month - show it clean
  TYPING_STATS="$THIS_MONTH_BEST"
  LABEL_SUFFIX=""
else
  # No tests this month - show placeholder encouraging typing
  TYPING_STATS="--"
  LABEL_SUFFIX=""
fi

# Format and update sketchybar
if [ -n "$TYPING_STATS" ] && [ "$TYPING_STATS" != "null" ]; then
  sketchybar --set typing icon="" label="${TYPING_STATS}${LABEL_SUFFIX}" drawing=on
else
  sketchybar --set typing drawing=off
fi