#!/bin/bash

# Find most recently modified git repo (same logic as git.sh)
LATEST_REPO=$(find ~/code -maxdepth 1 -type d -exec sh -c '
  if [ -d "$1/.git" ]; then
    printf "%s\t%s\n" "$(stat -f "%m" "$1")" "$1"
  fi
' sh {} \; | sort -nr | head -n 1 | cut -f2)

if [ -n "$LATEST_REPO" ] && [ -d "$LATEST_REPO/.git" ]; then
  cd "$LATEST_REPO"
  
  # Get the GitHub URL from git remote
  REMOTE_URL=$(git remote get-url origin 2>/dev/null)
  
  if [ -n "$REMOTE_URL" ]; then
    # Convert SSH URL to HTTPS if needed
    GITHUB_URL=$(echo "$REMOTE_URL" | sed -e 's|git@github.com:|https://github.com/|' -e 's|\.git$||')
    
    # Open in browser
    open "$GITHUB_URL"
  fi
fi