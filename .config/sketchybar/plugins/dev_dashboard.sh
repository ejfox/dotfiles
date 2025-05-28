#!/bin/bash

# Dev Dashboard - RPG-style metrics for your dev activity

generate_dev_metrics() {
    # Get date info
    local current_time=$(date "+%H:%M")
    local day=$(date "+%A")
    
    # Git metrics from recent repos
    local recent_repos=$(find ~/code -maxdepth 1 -type d -exec sh -c '
        for dir do
            if [ -d "$dir/.git" ]; then
                printf "%s\t%s\n" "$(stat -f "%m" "$dir")" "$dir"
            fi
        done
    ' sh {} + | sort -rn | head -n 3)
    
    # Get today's commit count across recent repos
    local commit_count=0
    local today=$(date "+%Y-%m-%d")
    
    while IFS=$'\t' read -r _ repo_path; do
        if [ -n "$repo_path" ]; then
            local repo_commits=$(git -C "$repo_path" log --since="$today 00:00:00" --until="$today 23:59:59" --oneline | wc -l | tr -d ' ')
            commit_count=$((commit_count + repo_commits))
        fi
    done <<< "$recent_repos"
    
    # Get completed tasks
    local completed_tasks=$(things-cli completed | wc -l | tr -d ' ')
    local total_tasks=$(things-cli today | grep -E '^\s*-\s' | wc -l | tr -d ' ')
    
    # Active coding time estimation (basic implementation)
    # In a real implementation, you might use something like WakaTime or a custom time tracker
    local coding_hours=0
    # If a time tracking file exists, use it
    if [ -f ~/.coding_time_today ]; then
        coding_hours=$(cat ~/.coding_time_today)
    else
        # Simple estimation based on git activity
        if [ "$commit_count" -gt 5 ]; then
            coding_hours=4
        elif [ "$commit_count" -gt 2 ]; then
            coding_hours=2
        elif [ "$commit_count" -gt 0 ]; then
            coding_hours=1
        fi
    fi
    
    # Determine appropriate icon based on metrics and time of day
    local hour=$(date "+%H" | sed 's/^0//')
    local icon=""
    
    # Morning (growth/potential)
    if [ "$hour" -lt 12 ]; then
        if [ "$commit_count" -gt 0 ] || [ "$completed_tasks" -gt 0 ]; then
            icon="󰠳" # Sprout with leaf
        else
            icon="󰴋" # Seed/sprout
        fi
    # Afternoon (active work)
    elif [ "$hour" -lt 17 ]; then
        if [ "$commit_count" -gt 3 ] || [ "$completed_tasks" -gt 3 ]; then
            icon="󰴌" # Flourishing tree
        elif [ "$commit_count" -gt 0 ] || [ "$completed_tasks" -gt 0 ]; then
            icon="󰃜" # Growing tree
        else
            icon="󰃛" # Small tree
        fi
    # Evening (harvest/reflection)
    else
        if [ "$commit_count" -gt 3 ] || [ "$completed_tasks" -gt 3 ]; then
            icon="󰴏" # Tree with fruits
        else
            icon="󰴎" # Evening tree
        fi
    fi
    
    # Determine color based on productivity
    local color="0xffffffff" # Default white
    
    # High productivity
    if [ "$commit_count" -gt 5 ] || [ "$completed_tasks" -gt 5 ]; then
        color="0xff83c746" # Green
    # Medium productivity
    elif [ "$commit_count" -gt 0 ] || [ "$completed_tasks" -gt 1 ]; then
        color="0xffE0AF68" # Amber/gold
    # Low/no productivity yet
    else
        # Softer color, not negative
        color="0xff7dcfff" # Light blue
    fi
    
    # Check for streaks (simple implementation)
    local streak_msg=""
    
    # In a real implementation, you'd store and retrieve streak data
    if [ -f ~/.commit_streak ]; then
        local streak_days=$(cat ~/.commit_streak)
        if [ "$streak_days" -gt 1 ] && [ "$commit_count" -gt 0 ]; then
            streak_msg="$streak_days-day commit streak"
        fi
    elif [ "$commit_count" -gt 0 ]; then
        streak_msg="Started commit streak"
    fi
    
    # Constructing the label
    local label=""
    
    # If morning, focus on goals
    if [ "$hour" -lt 12 ]; then
        if [ "$total_tasks" -gt 0 ]; then
            label="$total_tasks tasks planned"
        else
            label="Plan your day"
        fi
    # If workday, show progress
    elif [ "$hour" -lt 17 ]; then
        if [ "$commit_count" -gt 0 ] && [ "$completed_tasks" -gt 0 ]; then
            label="$commit_count commits, $completed_tasks tasks done"
        elif [ "$commit_count" -gt 0 ]; then
            label="$commit_count commits today"
        elif [ "$completed_tasks" -gt 0 ]; then
            label="$completed_tasks tasks completed"
        else
            label="Dev dashboard"
        fi
    # Evening summary
    else
        if [ -n "$streak_msg" ]; then
            label="$streak_msg"
        elif [ "$commit_count" -gt 0 ] || [ "$completed_tasks" -gt 0 ]; then
            label="$commit_count commits, $completed_tasks tasks today"
        else
            label="Rest & recharge"
        fi
    fi
    
    # Return the formatted output
    echo "$icon|$label|$color"
}

# Get metrics
IFS='|' read -r ICON LABEL COLOR <<< "$(generate_dev_metrics)"

# Update sketchybar
sketchybar --set $NAME icon="$ICON" label="$LABEL" icon.color="$COLOR" label.color="$COLOR"