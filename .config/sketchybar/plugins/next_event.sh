#!/bin/bash

# Get next calendar event with time awareness

# Get events today and tomorrow
EVENTS=$(icalBuddy -nc -n -f eventsToday 2>/dev/null)

if [ -z "$EVENTS" ]; then
  # No events today, hide the widget
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Parse next event (first line)
NEXT_EVENT=$(echo "$EVENTS" | head -n 1)

if [ -z "$NEXT_EVENT" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Extract event title and time
# icalBuddy format: "• Event Title (HH:MM - HH:MM)"
EVENT_TITLE=$(echo "$NEXT_EVENT" | sed 's/^• //' | sed 's/ ([0-9].*$//')
EVENT_TIME=$(echo "$NEXT_EVENT" | grep -o '([0-9][0-9]:[0-9][0-9]' | tr -d '(')

# Calculate time until event
if [ -n "$EVENT_TIME" ]; then
  NOW=$(date +%s)
  TODAY=$(date +%Y-%m-%d)
  EVENT_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY $EVENT_TIME" +%s 2>/dev/null)

  if [ -n "$EVENT_TIMESTAMP" ]; then
    TIME_DIFF=$((EVENT_TIMESTAMP - NOW))

    if [ $TIME_DIFF -lt 0 ]; then
      # Event already started or passed, try next one
      NEXT_EVENT=$(echo "$EVENTS" | head -n 2 | tail -n 1)
      if [ -n "$NEXT_EVENT" ]; then
        EVENT_TITLE=$(echo "$NEXT_EVENT" | sed 's/^• //' | sed 's/ ([0-9].*$//')
        EVENT_TIME=$(echo "$NEXT_EVENT" | grep -o '([0-9][0-9]:[0-9][0-9]' | tr -d '(')

        if [ -n "$EVENT_TIME" ]; then
          EVENT_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY $EVENT_TIME" +%s 2>/dev/null)
          TIME_DIFF=$((EVENT_TIMESTAMP - NOW))
        fi
      else
        # No more events, hide
        sketchybar --set "$NAME" drawing=off
        exit 0
      fi
    fi

    # Format time remaining
    if [ $TIME_DIFF -lt 3600 ]; then
      # Less than an hour: show minutes
      MINS=$((TIME_DIFF / 60))
      TIME_STR="in ${MINS}m"
    elif [ $TIME_DIFF -lt 7200 ]; then
      # 1-2 hours: show "in 1h"
      TIME_STR="in 1h"
    else
      # More than 2 hours: show time (e.g., "at 3:00")
      TIME_STR="at $EVENT_TIME"
    fi

    # Use LLM to intelligently shorten/format event title
    if command -v /opt/homebrew/bin/llm &>/dev/null; then
      # Ask LLM to make it concise and add appropriate emoji
      PROMPT="Shorten this calendar event to 3-4 words max, add one relevant emoji at start. Just output the result, nothing else: \"$EVENT_TITLE\""
      FORMATTED_TITLE=$(echo "$PROMPT" | /opt/homebrew/bin/llm -m gpt-4o-mini -o max_tokens 15 2>/dev/null | tr -d '"' | head -n 1)

      if [ -n "$FORMATTED_TITLE" ] && [ ${#FORMATTED_TITLE} -lt 30 ]; then
        EVENT_TITLE="$FORMATTED_TITLE"
      elif [ ${#EVENT_TITLE} -gt 20 ]; then
        # Fallback to simple truncation
        EVENT_TITLE="${EVENT_TITLE:0:17}..."
      fi
    elif [ ${#EVENT_TITLE} -gt 20 ]; then
      EVENT_TITLE="${EVENT_TITLE:0:17}..."
    fi

    LABEL="$EVENT_TITLE $TIME_STR"
  else
    # No timestamp, just show title
    LABEL="$EVENT_TITLE"
  fi
else
  # All-day event or no time
  LABEL="$EVENT_TITLE"
fi

# Update sketchybar
sketchybar --set "$NAME" label="$LABEL" drawing=on
