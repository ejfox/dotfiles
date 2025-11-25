#!/bin/bash

# Get calendar events with smart display
# - Shows compact time list with INDIVIDUAL colors per meeting
# - Only shows events with attendees (real meetings, not personal blocks)
# - White: normal | Red: within 10m | Green: currently active

# Colors
COLOR_NORMAL="0xffffffff"      # White text (default)
COLOR_URGENT="0xffff0055"      # Bright red (within 10m)
COLOR_ACTIVE="0xff00ff55"      # Green (currently in meeting)

MAX_MEETINGS=5  # Maximum meetings to display

# Get events today with attendee info
EVENTS=$(icalBuddy -nc -n -iep "title,datetime,attendees" -po "datetime,title,attendees" -df "" -tf "%H:%M" -b "• " eventsToday 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

NOW=$(date +%s)
TODAY=$(date +%Y-%m-%d)

# Collect meetings with their individual states
declare -a MEETING_TIMES=()
declare -a MEETING_COLORS=()
SEEN_TIMES=""

# Parse events
CURRENT_TIME=""
CURRENT_START_TS=""
CURRENT_END_TS=""
HAS_ATTENDEES=false

process_meeting() {
  local start_time="$1"
  local start_ts="$2"
  local end_ts="$3"

  # Skip if already seen
  if echo "$SEEN_TIMES" | grep -q "$start_time"; then
    return
  fi
  SEEN_TIMES="$SEEN_TIMES $start_time"

  # Skip past events
  [ $NOW -ge $end_ts ] && return

  # Determine color for THIS meeting
  local color="$COLOR_NORMAL"
  if [ $NOW -ge $start_ts ] && [ $NOW -lt $end_ts ]; then
    color="$COLOR_ACTIVE"  # Currently in meeting
  else
    local time_diff=$((start_ts - NOW))
    if [ $time_diff -gt 0 ] && [ $time_diff -le 600 ]; then
      color="$COLOR_URGENT"  # Within 10 minutes
    fi
  fi

  # Format time for display
  local hour=$(echo "$start_time" | cut -d: -f1 | sed 's/^0//')
  local min=$(echo "$start_time" | cut -d: -f2)
  local suffix="am"

  if [ $hour -gt 12 ]; then
    hour=$((hour - 12))
    suffix="pm"
  elif [ $hour -eq 12 ]; then
    suffix="pm"
  elif [ $hour -eq 0 ]; then
    hour=12
  fi

  local display_time
  if [ "$min" = "00" ]; then
    display_time="${hour}${suffix}"
  else
    display_time="${hour}:${min}${suffix}"
  fi

  # Add prefix if currently active
  if [ "$color" = "$COLOR_ACTIVE" ]; then
    display_time="▶${display_time}"
  fi

  MEETING_TIMES+=("$display_time")
  MEETING_COLORS+=("$color")
}

while IFS= read -r LINE; do
  if [[ "$LINE" =~ ^•\  ]]; then
    # Process previous event if it had attendees
    if [ -n "$CURRENT_TIME" ] && $HAS_ATTENDEES; then
      process_meeting "$CURRENT_TIME" "$CURRENT_START_TS" "$CURRENT_END_TS"
    fi

    # Start new event
    CURRENT_TIME=$(echo "$LINE" | grep -o '[0-9][0-9]:[0-9][0-9]' | head -1)
    END_TIME=$(echo "$LINE" | grep -o '[0-9][0-9]:[0-9][0-9]' | tail -1)
    HAS_ATTENDEES=false

    if [ -n "$CURRENT_TIME" ]; then
      CURRENT_START_TS=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY $CURRENT_TIME" +%s 2>/dev/null)
      CURRENT_END_TS=$CURRENT_START_TS
      if [ -n "$END_TIME" ] && [ "$END_TIME" != "$CURRENT_TIME" ]; then
        CURRENT_END_TS=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY $END_TIME" +%s 2>/dev/null)
      fi
    fi
  elif [[ "$LINE" =~ ^[[:space:]]*attendees: ]]; then
    HAS_ATTENDEES=true
  fi
done <<< "$EVENTS"

# Process last event
if [ -n "$CURRENT_TIME" ] && $HAS_ATTENDEES; then
  process_meeting "$CURRENT_TIME" "$CURRENT_START_TS" "$CURRENT_END_TS"
fi

# Build the display - use main item for first meeting, create additional items for rest
NUM_MEETINGS=${#MEETING_TIMES[@]}

if [ $NUM_MEETINGS -eq 0 ]; then
  sketchybar --set "$NAME" drawing=off
  # Hide any extra items
  for i in $(seq 1 $MAX_MEETINGS); do
    sketchybar --set "${NAME}.${i}" drawing=off 2>/dev/null
  done
  exit 0
fi

# Build label with comma separators between colored items
# Since we can't color individually in one label, create separate items
FIRST_LABEL="${MEETING_TIMES[0]}"
FIRST_COLOR="${MEETING_COLORS[0]}"

# Set main item to first meeting
sketchybar --set "$NAME" \
  label="$FIRST_LABEL" \
  label.color="$FIRST_COLOR" \
  drawing=on

# Create/update additional items for remaining meetings
for i in $(seq 1 $((MAX_MEETINGS))); do
  idx=$i  # Array index (0-based would be i, but we start from 1)
  item_name="${NAME}.${i}"

  if [ $idx -lt $NUM_MEETINGS ]; then
    meeting_label="${MEETING_TIMES[$idx]}"
    meeting_color="${MEETING_COLORS[$idx]}"

    # Add comma prefix for visual separation
    meeting_label=", ${meeting_label}"

    # Check if item exists, if not create it
    if ! sketchybar --query "$item_name" &>/dev/null; then
      sketchybar --add item "$item_name" left \
        --set "$item_name" \
          label.font="SF Pro:Medium:12.0" \
          label.padding_left=0 \
          label.padding_right=0 \
          background.drawing=off
    fi

    sketchybar --set "$item_name" \
      label="$meeting_label" \
      label.color="$meeting_color" \
      drawing=on
  else
    # Hide unused items
    sketchybar --set "$item_name" drawing=off 2>/dev/null
  fi
done
