#!/bin/bash

DEMOS_DIR="$HOME/demos"
TODAY=$(date +"%Y-%m-%d")

# Colors
WHITE="0xffffffff"
YELLOW="0xffffc857"
RED="0xffff6b6b"

# Count only video files from today (mp4, mov, webm)
today_count=0
last_demo_date=""

find_videos() {
    find "$DEMOS_DIR" -maxdepth 2 -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.webm" \) 2>/dev/null
}

while IFS= read -r video; do
    [[ -z "$video" ]] && continue
    vdate=$(stat -f %Sm -t %Y-%m-%d "$video" 2>/dev/null)

    # Count today's
    [[ "$vdate" == "$TODAY" ]] && ((today_count++))

    # Track most recent
    if [[ -z "$last_demo_date" ]] || [[ "$vdate" > "$last_demo_date" ]]; then
        last_demo_date="$vdate"
    fi
done < <(find_videos)

# Calculate days ago
if [[ -n "$last_demo_date" ]]; then
    last_ts=$(date -j -f %Y-%m-%d "$last_demo_date" +%s 2>/dev/null)
    now_ts=$(date +%s)
    days_ago=$(( (now_ts - last_ts) / 86400 ))
else
    days_ago=-1
fi

# Display with escalating urgency
if [[ $today_count -gt 0 ]]; then
    # Recorded today - happy state
    sketchybar --set "$NAME" icon="󰕧" label="$today_count" icon.color=$WHITE label.color=$WHITE drawing=on
elif [[ $days_ago -eq 0 ]]; then
    # Today but no new ones yet (edge case)
    sketchybar --set "$NAME" icon="󰕧" label="0d" icon.color=$WHITE label.color=$WHITE drawing=on
elif [[ $days_ago -eq 1 ]]; then
    # 1 day - normal
    sketchybar --set "$NAME" icon="󰕧" label="1d" icon.color=$WHITE label.color=$WHITE drawing=on
elif [[ $days_ago -eq 2 ]]; then
    # 2 days - yellow
    sketchybar --set "$NAME" icon="󰕧" label="2d" icon.color=$YELLOW label.color=$WHITE drawing=on
elif [[ $days_ago -eq 3 ]]; then
    # 3 days - red icon
    sketchybar --set "$NAME" icon="󰕧" label="3d" icon.color=$RED label.color=$WHITE drawing=on
elif [[ $days_ago -eq 4 ]]; then
    # 4 days - red icon and text
    sketchybar --set "$NAME" icon="󰕧" label="4d" icon.color=$RED label.color=$RED drawing=on
elif [[ $days_ago -ge 5 ]]; then
    # 5+ days - exclamation, all red
    sketchybar --set "$NAME" icon="󰕧!" label="${days_ago}d" icon.color=$RED label.color=$RED drawing=on
else
    # No demos yet
    sketchybar --set "$NAME" icon="󰕧" label="--" icon.color=$WHITE label.color=$WHITE drawing=on
fi
