#!/bin/bash

# Get calendar events with smart display
# - Shows compact time list: "1pm, 3:30pm, 5pm"
# - Only shows events with attendees (real meetings, not personal blocks)
# - White: normal | Red: within 10m | Green: currently active

# Colors
COLOR_NORMAL="0xffffffff"      # White text (default)
COLOR_URGENT="0xffff0055"      # Bright red (within 10m)
COLOR_ACTIVE="0xff00ff55"      # Green (currently in meeting)
COLOR_DIM="0xff666666"         # Dim grey

# Get events today with attendee info
EVENTS=$(icalBuddy -nc -n -iep "title,datetime,attendees" -po "datetime,title,attendees" -df "" -tf "%H:%M" -b "• " eventsToday 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

if [ -z "$EVENTS" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

NOW=$(date +%s)
TODAY=$(date +%Y-%m-%d)

# Collect all upcoming events (deduplicated by start time, only with attendees)
declare -a EVENT_TIMES=()
declare -a EVENT_TIMESTAMPS=()
SEEN_TIMES=""  # Track seen start times for deduplication
IN_MEETING=false
URGENT=false

# Parse events - need to look ahead for attendees line
CURRENT_TIME=""
CURRENT_START_TS=""
CURRENT_END_TS=""
HAS_ATTENDEES=false

while IFS= read -r LINE; do
  # Time line starts with bullet
  if [[ "$LINE" =~ ^•\  ]]; then
    # Process previous event if it had attendees
    if [ -n "$CURRENT_TIME" ] && $HAS_ATTENDEES; then
      # Skip if already seen this time
      if ! echo "$SEEN_TIMES" | grep -q "$CURRENT_TIME"; then
        SEEN_TIMES="$SEEN_TIMES $CURRENT_TIME"

        # Check if currently in this meeting
        if [ $NOW -ge $CURRENT_START_TS ] && [ $NOW -lt $CURRENT_END_TS ]; then
          IN_MEETING=true
        fi

        # Skip past events
        if [ $NOW -lt $CURRENT_END_TS ]; then
          # Check if upcoming within 10 minutes
          TIME_DIFF=$((CURRENT_START_TS - NOW))
          if [ $TIME_DIFF -gt 0 ] && [ $TIME_DIFF -le 600 ]; then
            URGENT=true
          fi

          # Format time for display
          HOUR=$(echo "$CURRENT_TIME" | cut -d: -f1 | sed 's/^0//')
          MIN=$(echo "$CURRENT_TIME" | cut -d: -f2)

          if [ $HOUR -gt 12 ]; then
            HOUR=$((HOUR - 12))
            SUFFIX="pm"
          elif [ $HOUR -eq 12 ]; then
            SUFFIX="pm"
          elif [ $HOUR -eq 0 ]; then
            HOUR=12
            SUFFIX="am"
          else
            SUFFIX="am"
          fi

          if [ "$MIN" = "00" ]; then
            DISPLAY_TIME="${HOUR}${SUFFIX}"
          else
            DISPLAY_TIME="${HOUR}:${MIN}${SUFFIX}"
          fi

          EVENT_TIMES+=("$DISPLAY_TIME")
        fi
      fi
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
  # Attendees line
  elif [[ "$LINE" =~ ^[[:space:]]*attendees: ]]; then
    HAS_ATTENDEES=true
  fi
done <<< "$EVENTS"

# Process last event
if [ -n "$CURRENT_TIME" ] && $HAS_ATTENDEES; then
  if ! echo "$SEEN_TIMES" | grep -q "$CURRENT_TIME"; then
    if [ $NOW -ge $CURRENT_START_TS ] && [ $NOW -lt $CURRENT_END_TS ]; then
      IN_MEETING=true
    fi

    if [ $NOW -lt $CURRENT_END_TS ]; then
      TIME_DIFF=$((CURRENT_START_TS - NOW))
      if [ $TIME_DIFF -gt 0 ] && [ $TIME_DIFF -le 600 ]; then
        URGENT=true
      fi

      HOUR=$(echo "$CURRENT_TIME" | cut -d: -f1 | sed 's/^0//')
      MIN=$(echo "$CURRENT_TIME" | cut -d: -f2)

      if [ $HOUR -gt 12 ]; then
        HOUR=$((HOUR - 12))
        SUFFIX="pm"
      elif [ $HOUR -eq 12 ]; then
        SUFFIX="pm"
      elif [ $HOUR -eq 0 ]; then
        HOUR=12
        SUFFIX="am"
      else
        SUFFIX="am"
      fi

      if [ "$MIN" = "00" ]; then
        DISPLAY_TIME="${HOUR}${SUFFIX}"
      else
        DISPLAY_TIME="${HOUR}:${MIN}${SUFFIX}"
      fi

      EVENT_TIMES+=("$DISPLAY_TIME")
    fi
  fi
fi

# Build display string
if [ ${#EVENT_TIMES[@]} -eq 0 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Join times with comma
LABEL=$(IFS=', '; echo "${EVENT_TIMES[*]}")

# Set colors based on state
if $IN_MEETING; then
  # Currently in meeting - green
  sketchybar --set "$NAME" \
    label="▶ $LABEL" \
    label.color="$COLOR_ACTIVE" \
    background.drawing=off \
    drawing=on
elif $URGENT; then
  # Within 10 minutes - red
  sketchybar --set "$NAME" \
    label="$LABEL" \
    label.color="$COLOR_URGENT" \
    background.drawing=off \
    drawing=on
else
  # Normal upcoming events - white
  sketchybar --set "$NAME" \
    label="$LABEL" \
    label.color="$COLOR_NORMAL" \
    background.drawing=off \
    drawing=on
fi
