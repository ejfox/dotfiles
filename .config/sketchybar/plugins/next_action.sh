#!/bin/bash

# Generate next action suggestion using LLM
generate_next_action() {
    # Get current time
    local current_time=$(date "+%H:%M")
    local hour=$(date "+%H" | sed 's/^0//')
    
    # Get top tasks
    local tasks=$(things-cli today | head -n 5)
    
    # Get recent repos
    local recent_repos=$(find ~/code -maxdepth 1 -type d -exec sh -c '
        for dir do
            if [ -d "$dir/.git" ]; then
                printf "%s\t%s\n" "$(stat -f "%m" "$dir")" "$(basename "$dir")"
            fi
        done
    ' sh {} + | sort -rn | head -n 3 | cut -f2-)
    
    # Time context
    local time_context=""
    if [ $hour -lt 12 ]; then
        time_context="morning"
    elif [ $hour -lt 17 ]; then
        time_context="afternoon"
    else
        time_context="evening"
    fi
    
    # Build prompt
    local prompt="You are a concise AI assistant. Based on the following information, suggest ONE specific next action in 4-6 words (max: 6). Be very specific, practical, prioritize important work tasks, and suggest something concrete. IMPORTANT: Your response should be ONLY the suggestion, nothing else. Create a profound yet practical suggestion that feels like a gentle nudge from the future. Don't use quotes.

Current time: $current_time ($time_context)
Day of week: $(date +%A)

Top tasks:
$tasks

Recent code projects:
$recent_repos"

    # Get suggestion from LLM
    echo "$prompt" | /opt/homebrew/Caskroom/miniconda/base/bin/llm -m gpt-4o-mini -o max_tokens 50 | tr -d '"'
}

# Get the next action
NEXT_ACTION=$(generate_next_action)

# Fallback if LLM fails
if [ -z "$NEXT_ACTION" ]; then
    NEXT_ACTION="Focus on your highest priority task"
fi

# Update sketchybar
sketchybar --set $NAME label="$NEXT_ACTION"