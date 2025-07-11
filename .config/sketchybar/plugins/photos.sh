#!/bin/bash

# Fetch photo stats from API
response=$(curl -s "https://ejfox.photos/api/stats")
PHOTO_COUNT=$(echo "$response" | jq -r '.stats.photosThisMonth')

# Format and update sketchybar
if [ -n "$PHOTO_COUNT" ] && [ "$PHOTO_COUNT" != "null" ]; then
  sketchybar --set photos icon="📸" label="${PHOTO_COUNT}" drawing=on
else
  sketchybar --set photos drawing=off
fi