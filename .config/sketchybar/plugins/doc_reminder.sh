#!/bin/bash

# Smart documentation reminder using multiple activity signals

# Git activity - commits and file changes indicate deep work
get_git_activity() {
    local commits=0
    for repo in ~/code/*/; do
        [[ -d "$repo/.git" ]] && cd "$repo" && commits=$((commits + $(git log --since="today" --oneline 2>/dev/null | wc -l)))
    done
    echo $commits
}

# Creative work detection
get_creative_activity() {
    local obs_count=$(ls ~/Movies/$(date +%Y-%m-%d)_*.mp4 2>/dev/null | wc -l | tr -d ' ')
    local screenshots=$(ls ~/screenshots/*$(date "+%Y-%m-%d")* 2>/dev/null | wc -l | tr -d ' ')
    echo $((obs_count + screenshots))
}

# Terminal intensity (rough proxy for experimentation)
get_terminal_activity() {
    [[ -f ~/.zsh_history ]] && tail -200 ~/.zsh_history | wc -l | tr -d ' ' || echo 0
}

# Obsidian note activity - multiple files = active thinking/research
get_obsidian_activity() {
    find "/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox" -name "*.md" -mtime -1 2>/dev/null | wc -l | tr -d ' '
}

# Documentation status
is_documented() {
    local weeknote="/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox/week-notes/2025-$(date +%U).md"
    [[ -f "$weeknote" ]] && [[ $(find "$weeknote" -mtime -1 2>/dev/null) ]] && echo 1 || echo 0
}

# Main logic
git_commits=$(get_git_activity)
creative_items=$(get_creative_activity) 
terminal_intensity=$(get_terminal_activity)
obsidian_notes=$(get_obsidian_activity)
documented=$(is_documented)

# Calculate activity score (weighted)
activity_score=$((git_commits * 3 + creative_items * 2 + obsidian_notes * 2 + terminal_intensity / 20))

# Show appropriate reminder
if [[ $activity_score -gt 8 ]] && [[ $documented -eq 0 ]]; then
    # High activity, no docs = urgent
    sketchybar --set "$NAME" label="✎!" drawing=on
elif [[ $activity_score -gt 3 ]] && [[ $documented -eq 0 ]]; then
    # Moderate activity, no docs = gentle reminder  
    sketchybar --set "$NAME" label="✎${activity_score}" drawing=on
elif [[ $activity_score -eq 0 ]]; then
    # No activity = remind to capture
    sketchybar --set "$NAME" label="◉" drawing=on
else
    # All good or already documented
    sketchybar --set "$NAME" drawing=off
fi