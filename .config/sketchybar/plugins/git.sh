#!/bin/bash

# Cache file to track repo changes
CACHE_FILE="/tmp/git_repo_cache"

# Find most recently modified git repo
LATEST_REPO=$(find ~/code -maxdepth 1 -type d -exec sh -c '
  if [ -d "$1/.git" ]; then
    printf "%s\t%s\n" "$(stat -f "%m" "$1")" "$1"
  fi
' sh {} \; | sort -nr | head -n 1 | cut -f2)

if [ -n "$LATEST_REPO" ] && git -C "$LATEST_REPO" rev-parse --is-inside-work-tree &>/dev/null; then
  REPO=$(basename "$LATEST_REPO")
  BRANCH=$(git -C "$LATEST_REPO" branch --show-current)
  
  # Count modified/staged files
  MODIFIED=$(git -C "$LATEST_REPO" status --porcelain | wc -l | tr -d ' ')
  
  # Check if ahead/behind remote
  if git -C "$LATEST_REPO" rev-parse --abbrev-ref @{upstream} &>/dev/null; then
    REMOTE_STATUS=$(git -C "$LATEST_REPO" rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)
    BEHIND=$(echo "$REMOTE_STATUS" | awk '{print $1}')
    AHEAD=$(echo "$REMOTE_STATUS" | awk '{print $2}')
  else
    BEHIND=0
    AHEAD=0
  fi
  
  # Build status indicator (only show symbols for repos that need attention)
  STATUS=""
  if [ "$MODIFIED" -gt 0 ]; then
    STATUS="◆"  # Modified files
  elif [ "$AHEAD" -gt 0 ] || [ "$BEHIND" -gt 0 ]; then
    STATUS="◇"  # Needs sync
  else
    STATUS=""   # Clean - no symbol
  fi
  
  # Minimal dark gray color for low prominence
  COLOR="0xff666666"
  
  # Truncate repo name if too long (increased limit)
  if [ ${#REPO} -gt 20 ]; then
    REPO="${REPO:0:17}..."
  fi
  
  # Check if repo changed for animation
  CURRENT_REPO="$REPO"
  if [ -f "$CACHE_FILE" ]; then
    PREV_REPO=$(cat "$CACHE_FILE")
  else
    PREV_REPO=""
  fi
  
  # If repo changed, animate the transition
  if [ "$CURRENT_REPO" != "$PREV_REPO" ] && [ -n "$PREV_REPO" ]; then
    # Slide out old repo name
    sketchybar --animate sin 15 --set git label.y_offset=10 label.color=0x00666666
    sleep 0.25
    
    # Update to new repo and slide in
    if [ -n "$STATUS" ]; then
      sketchybar --set git label="$REPO" icon="$STATUS" icon.color=$COLOR
    else
      sketchybar --set git label="$REPO" icon="" icon.color=$COLOR
    fi
    
    sketchybar --animate sin 15 --set git label.y_offset=0 label.color=$COLOR
  else
    # No animation needed, just update normally
    if [ -n "$STATUS" ]; then
      sketchybar --set git label="$REPO" icon="$STATUS" icon.color=$COLOR label.color=$COLOR
    else
      sketchybar --set git label="$REPO" icon="" icon.color=$COLOR label.color=$COLOR
    fi
  fi
  
  # Cache current repo
  echo "$CURRENT_REPO" > "$CACHE_FILE"
else
  # Fallback if no git repos found
  sketchybar --set git label="no repo" icon="" icon.color=0xff666666 label.color=0xff666666
fi
