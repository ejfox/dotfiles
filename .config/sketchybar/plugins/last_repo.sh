#!/bin/bash

# Find most recently modified git repo
LATEST_REPO=$(find ~/code -maxdepth 1 -type d -exec sh -c '
  if [ -d "$1/.git" ]; then
    printf "%s\t%s\n" "$(stat -f "%m" "$1")" "$1"
  fi
' sh {} \; | sort -nr | head -n 1 | cut -f2)

if [ -n "$LATEST_REPO" ]; then
  REPO_NAME=$(basename "$LATEST_REPO")
  sketchybar --set $NAME icon="R" label="$REPO_NAME"
else
  sketchybar --set $NAME icon="R" label="No repo"
fi