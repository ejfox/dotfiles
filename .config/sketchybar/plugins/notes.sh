#!/bin/bash

VAULT="/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
TODAY=$(date +"%Y-%m-%d")

# Colors
WHITE="0xffffffff"
YELLOW="0xffffc857"
RED="0xffff6b6b"

# Count human-written notes modified today
today_count=0
last_note_date=""

# Find notes excluding robots, .obsidian, .trash, templates, week-notes
find_notes() {
    find "$VAULT" -name "*.md" -type f \
        -not -path "*/robots/*" \
        -not -path "*/.obsidian/*" \
        -not -path "*/.trash/*" \
        -not -path "*/templates/*" \
        -not -path "*/week-notes/*" \
        2>/dev/null
}

while IFS= read -r note; do
    [[ -z "$note" ]] && continue
    ndate=$(stat -f %Sm -t %Y-%m-%d "$note" 2>/dev/null)

    # Count today's
    [[ "$ndate" == "$TODAY" ]] && ((today_count++))

    # Track most recent
    if [[ -z "$last_note_date" ]] || [[ "$ndate" > "$last_note_date" ]]; then
        last_note_date="$ndate"
    fi
done < <(find_notes)

# Calculate days ago
if [[ -n "$last_note_date" ]]; then
    last_ts=$(date -j -f %Y-%m-%d "$last_note_date" +%s 2>/dev/null)
    now_ts=$(date +%s)
    days_ago=$(( (now_ts - last_ts) / 86400 ))
else
    days_ago=-1
fi

# Display with escalating urgency
if [[ $today_count -gt 0 ]]; then
    sketchybar --set "$NAME" icon="󰎞" label="$today_count" icon.color=$WHITE label.color=$WHITE drawing=on
elif [[ $days_ago -eq 0 ]]; then
    sketchybar --set "$NAME" icon="󰎞" label="0d" icon.color=$WHITE label.color=$WHITE drawing=on
elif [[ $days_ago -eq 1 ]]; then
    sketchybar --set "$NAME" icon="󰎞" label="1d" icon.color=$WHITE label.color=$WHITE drawing=on
elif [[ $days_ago -eq 2 ]]; then
    sketchybar --set "$NAME" icon="󰎞" label="2d" icon.color=$YELLOW label.color=$WHITE drawing=on
elif [[ $days_ago -eq 3 ]]; then
    sketchybar --set "$NAME" icon="󰎞" label="3d" icon.color=$RED label.color=$WHITE drawing=on
elif [[ $days_ago -eq 4 ]]; then
    sketchybar --set "$NAME" icon="󰎞" label="4d" icon.color=$RED label.color=$RED drawing=on
elif [[ $days_ago -ge 5 ]]; then
    sketchybar --set "$NAME" icon="󰎞!" label="${days_ago}d" icon.color=$RED label.color=$RED drawing=on
else
    sketchybar --set "$NAME" icon="󰎞" label="--" icon.color=$WHITE label.color=$WHITE drawing=on
fi
