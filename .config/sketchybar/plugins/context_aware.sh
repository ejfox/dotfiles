#!/bin/bash

# Detect current context and show appropriate info
# Set NAME if not provided (for manual testing)
NAME=${NAME:-context}

# Check for video/motion apps
if pgrep -f "Final Cut Pro|After Effects|Cinema 4D" > /dev/null; then
    # Video mode - show disk space
    DISK_FREE=$(df -H / | awk 'NR==2 {print $4}')
    CURRENT_APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')
    
    sketchybar --set $NAME label="$DISK_FREE free" \
                           icon.drawing=off

# Check for design apps
elif pgrep -f "Figma|Photoshop|Illustrator|Keynote" > /dev/null; then
    # Design mode - screenshots today + hours
    SCREENSHOTS=$(find ~/Desktop -name "Screenshot*.png" -mtime -1 | wc -l | tr -d ' ')
    HOURS=$(echo "scale=1; $(pmset -g log | grep "Wake from" | tail -1 | awk '{print $2}' | cut -d: -f1)" | bc)
    
    sketchybar --set $NAME label="$SCREENSHOTS shots ${HOURS}h" \
                           icon.drawing=off

# Check if in code directory with git
elif cd ~/code 2>/dev/null && [[ -n $(find . -maxdepth 2 -name ".git" -type d | head -1) ]]; then
    # Code mode - show most recent repo
    RECENT_REPO=$(ls -td ~/code/*/.git 2>/dev/null | head -1 | xargs dirname | xargs basename)
    if [[ -n "$RECENT_REPO" ]]; then
        cd ~/code/$RECENT_REPO
        BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
        sketchybar --set $NAME label="$RECENT_REPO $BRANCH" \
                               icon.drawing=off \
                               click_script="open https://github.com/ejfox/$RECENT_REPO"
    fi

else
    # Default - show most recent git repo as fallback
    RECENT_REPO=$(ls -td ~/code/*/.git 2>/dev/null | head -1 | xargs dirname | xargs basename)
    if [[ -n "$RECENT_REPO" ]]; then
        sketchybar --set $NAME label="$RECENT_REPO" \
                               icon.drawing=off
    else
        sketchybar --set $NAME label="" \
                               icon.drawing=off
    fi
fi