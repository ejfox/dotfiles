#!/bin/bash

# Hyperminimalist Claude Code statusline
# Shows: $today | session_time/tokens | CLAUDE.md | gh_issues

# Get usage data
usage=$(ccusage statusline 2>/dev/null | head -1)
if [[ -z "$usage" ]]; then
    usage="$0.00"
fi

# Extract just the dollar amount (format: $X.XX)
cost=$(echo "$usage" | grep -o '\$[0-9]*\.[0-9]*' | head -1)
[[ -z "$cost" ]] && cost="$0"

# Session info from input JSON
if [[ -n "$1" ]]; then
    session_id=$(echo "$1" | jq -r '.session_id // ""' 2>/dev/null)
    # Get session duration and tokens (simplified)
    session_info=$(ccusage session "$session_id" 2>/dev/null | grep -E 'Duration:|Tokens:' | head -2 | awk '{print $2}' | tr '\n' '/' | sed 's/\/$//')
    [[ -z "$session_info" ]] && session_info="0m/0"
else
    session_info="--/--"
fi

# CLAUDE.md check (exists + line count)
claude_md=""
if [[ -f ~/CLAUDE.md ]]; then
    lines=$(wc -l < ~/CLAUDE.md | tr -d ' ')
    claude_md="✓${lines}L"
elif [[ -f ~/.dotfiles/CLAUDE.md ]]; then
    lines=$(wc -l < ~/.dotfiles/CLAUDE.md | tr -d ' ')
    claude_md="✓${lines}L"
else
    claude_md="✗"
fi

# GitHub issues count (for current repo if in one)
gh_count=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    # In a git repo, try to get issue count
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
    if [[ -n "$repo" ]]; then
        issue_count=$(gh issue list --state open --limit 100 --json id --jq 'length' 2>/dev/null)
        [[ -n "$issue_count" ]] && gh_count="◉${issue_count}"
    fi
fi

# Format: $2.50|5m/1.2k|✓42L|◉3
echo "${cost}|${session_info}|${claude_md}${gh_count:+|$gh_count}"