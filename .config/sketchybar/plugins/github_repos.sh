#!/bin/bash

# Fetch GitHub repo count from API
REPO_COUNT=$(curl -s "https://ejfox.com/api/stats" | jq -r '.github.stats.totalRepos')

# Set emoji and update sketchybar
if [ -n "$REPO_COUNT" ] && [ "$REPO_COUNT" != "null" ]; then
  sketchybar --set $NAME icon="R" label="$REPO_COUNT" drawing=on
else
  sketchybar --set $NAME drawing=off
fi