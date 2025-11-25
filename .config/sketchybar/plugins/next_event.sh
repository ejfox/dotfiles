#!/bin/bash

# Get calendar events with smart display
# - Shows compact time list: "1pm, 3:30pm, 5pm"
# - Red glow if within 15 minutes
# - Inverted (red bg, black text) if currently happening

# Vulpes colors
COLOR_NORMAL="0xfff5d0dc"      # Light pink text
COLOR_URGENT="0xffff0055"      # Bright red (within 15m)
COLOR_ACTIVE_BG="0xffff0055"   # Red background when in meeting
COLOR_ACTIVE_FG="0xff0d0d0d"   # Black text when in meeting
COLOR_DIM="0xff73264a"         # Muted mauve

# Get events today in parseable format
EVENTS=$(icalBuddy -nc -n -iep "title,datetime" -po "datetime,title" -df "" -tf "%H:%M" -b "• " eventsToday 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

if [ -z "$EVENTS" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

NOW=$(date +%s)
TODAY=$(date +%Y-%m-%d)

# Collect all upcoming events
declare -a EVENT_TIMES=()
declare -a EVENT_TIMESTAMPS=()
IN_MEETING=false
URGENT=false

while IFS= read -r EVENT_LINE; do
  [ -z "$EVENT_LINE" ] && continue
  [[ ! "$EVENT_LINE" =~ ^•\  ]] && continue

  # Extract start and end time
  START_TIME=$(echo "$EVENT_LINE" | grep -o '[0-9][0-9]:[0-9][0-9]' | head -1)
  END_TIME=$(echo "$EVENT_LINE" | grep -o '[0-9][0-9]:[0-9][0-9]' | tail -1)

  [ -z "$START_TIME" ] && continue

  # Calculate timestamps
  START_TS=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY $START_TIME" +%s 2>/dev/null)
  [ -z "$START_TS" ] && continue

  END_TS=$START_TS
  if [ -n "$END_TIME" ] && [ "$END_TIME" != "$START_TIME" ]; then
    END_TS=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY $END_TIME" +%s 2>/dev/null)
  fi

  # Check if currently in this meeting
  if [ $NOW -ge $START_TS ] && [ $NOW -lt $END_TS ]; then
    IN_MEETING=true
  fi

  # Skip past events (that have ended)
  [ $NOW -ge $END_TS ] && continue

  # Check if upcoming within 15 minutes
  TIME_DIFF=$((START_TS - NOW))
  if [ $TIME_DIFF -gt 0 ] && [ $TIME_DIFF -le 900 ]; then
    URGENT=true
  fi

  # Format time for display (convert 24h to 12h, strip leading zero)
  HOUR=$(echo "$START_TIME" | cut -d: -f1 | sed 's/^0//')
  MIN=$(echo "$START_TIME" | cut -d: -f2)

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
  EVENT_TIMESTAMPS+=("$START_TS")

done <<< "$EVENTS"

# Build display string
if [ ${#EVENT_TIMES[@]} -eq 0 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Join times with comma
LABEL=$(IFS=', '; echo "${EVENT_TIMES[*]}")

# Set colors based on state
if $IN_MEETING; then
  # Currently in meeting - inverted red
  sketchybar --set "$NAME" \
    label="▶ $LABEL" \
    label.color="$COLOR_ACTIVE_FG" \
    background.color="$COLOR_ACTIVE_BG" \
    background.drawing=on \
    background.corner_radius=4 \
    background.padding_left=6 \
    background.padding_right=6 \
    drawing=on
elif $URGENT; then
  # Within 15 minutes - red glow
  sketchybar --set "$NAME" \
    label="$LABEL" \
    label.color="$COLOR_URGENT" \
    background.drawing=off \
    drawing=on
else
  # Normal upcoming events
  sketchybar --set "$NAME" \
    label="$LABEL" \
    label.color="$COLOR_NORMAL" \
    background.drawing=off \
    drawing=on
fi
