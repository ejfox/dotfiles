#!/bin/bash

# Use absolute path to ccusage
CCUSAGE="/Users/ejfox/.nvm/versions/node/v20.16.0/bin/ccusage"

# Get today's cost (no cents)
today=$(date +%Y%m%d)
cost_raw=$($CCUSAGE daily --since "$today" --until "$today" --offline 2>/dev/null | grep '2025' | head -1 | rev | cut -d'│' -f2 | rev | sed 's/\x1b\[[0-9;]*m//g' | tr -d ' ')

# Extract just the dollar amount as integer
cost_num=$(echo "$cost_raw" | sed 's/\$//g' | cut -d'.' -f1)
[[ -z "$cost_num" ]] && cost_num="0"

# Simple: ◆ for claude, $ for amount
label="◆\$${cost_num}"

# Update
sketchybar --set "$NAME" label="${label}"