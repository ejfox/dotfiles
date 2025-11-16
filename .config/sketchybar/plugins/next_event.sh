#!/bin/bash

# Get next calendar event with time awareness
# Skips all-day events and shows only upcoming timed events

# Cache file for CIPHER messages to avoid excessive LLM calls
CACHE_FILE="/tmp/sketchybar_cipher_cache"

# Get events today (strip ANSI codes)
EVENTS=$(icalBuddy -nc -n -f eventsToday 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')

if [ -z "$EVENTS" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Loop through events to find next timed event
NOW=$(date +%s)
TODAY=$(date +%Y-%m-%d)
FOUND=false

while IFS= read -r EVENT_LINE; do
  # Skip empty lines
  [ -z "$EVENT_LINE" ] && continue

  # Extract title and time
  EVENT_TITLE=$(echo "$EVENT_LINE" | sed 's/^• //' | sed 's/ ([0-9].*$//')
  EVENT_TIME=$(echo "$EVENT_LINE" | grep -o '([0-9][0-9]:[0-9][0-9]' | tr -d '(')

  # Skip all-day events (no time)
  [ -z "$EVENT_TIME" ] && continue

  # Calculate timestamp
  EVENT_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY $EVENT_TIME" +%s 2>/dev/null)
  [ -z "$EVENT_TIMESTAMP" ] && continue

  # Skip past events
  TIME_DIFF=$((EVENT_TIMESTAMP - NOW))
  [ $TIME_DIFF -lt 0 ] && continue

  # Found next event!
  FOUND=true

  # Format time remaining
  if [ $TIME_DIFF -lt 3600 ]; then
    MINS=$((TIME_DIFF / 60))
    TIME_STR="in ${MINS}m"
  elif [ $TIME_DIFF -lt 7200 ]; then
    TIME_STR="in 1h"
  else
    TIME_STR="at $EVENT_TIME"
  fi

  # Use LLM to intelligently shorten/format event title
  if command -v /opt/homebrew/bin/llm &>/dev/null; then
    PROMPT="Shorten this calendar event to 3-4 words max, add one relevant emoji at start. Just output the result, nothing else: \"$EVENT_TITLE\""
    FORMATTED_TITLE=$(echo "$PROMPT" | /opt/homebrew/bin/llm -m gpt-4o-mini -o max_tokens 15 2>/dev/null | tr -d '"' | head -n 1)

    if [ -n "$FORMATTED_TITLE" ] && [ ${#FORMATTED_TITLE} -lt 30 ]; then
      EVENT_TITLE="$FORMATTED_TITLE"
    elif [ ${#EVENT_TITLE} -gt 20 ]; then
      EVENT_TITLE="${EVENT_TITLE:0:17}..."
    fi
  elif [ ${#EVENT_TITLE} -gt 20 ]; then
    EVENT_TITLE="${EVENT_TITLE:0:17}..."
  fi

  LABEL="$EVENT_TITLE $TIME_STR"
  break
done <<< "$EVENTS"

if [ "$FOUND" = true ]; then
  # Check if event is more than 4 hours away
  if [ $TIME_DIFF -gt 14400 ]; then
    # More than 4 hours - show cipher message instead
    if command -v /opt/homebrew/bin/llm &>/dev/null; then
      HOUR=$(date +%H)

      # Get Things context
      TODAY_TASKS=$(osascript -e 'tell application "Things3" to get name of to dos of list "Today"' 2>/dev/null)
      COMPLETED_TODAY=$(osascript -e 'tell application "Things3" to get name of to dos whose status is completed and completion date is (current date)' 2>/dev/null)
      TASK_COUNT=$(echo "$TODAY_TASKS" | grep -o ',' | wc -l | xargs)
      COMPLETED_COUNT=$(echo "$COMPLETED_TODAY" | grep -o ',' | wc -l | xargs)

      # Create state hash from actual task content (not just count)
      TASKS_HASH=$(echo "$TODAY_TASKS" | md5)
      STATE_HASH="${HOUR}_${TASKS_HASH}_${COMPLETED_COUNT}_far"

      # Check cache
      if [ -f "$CACHE_FILE" ]; then
        CACHED_STATE=$(head -n 1 "$CACHE_FILE")
        if [ "$CACHED_STATE" = "$STATE_HASH" ]; then
          # State unchanged, use cached message
          CIPHER_MSG=$(tail -n 1 "$CACHE_FILE")
        fi
      fi

      # Generate new message if no cache hit
      if [ -z "$CIPHER_MSG" ]; then
        PROMPT="You are CIPHER, a supportive coach (not a taskmaster). Here are today's tasks: $TODAY_TASKS

Pick the most joyful/appealing one and highlight it in a brief, encouraging way (~10 words max). Focus on what makes it interesting or rewarding. No generic motivation - be specific to the task. Just output the message, nothing else."
        CIPHER_MSG=$(echo "$PROMPT" | /opt/homebrew/bin/llm -m gpt-4o-mini -o max_tokens 25 2>/dev/null | head -n 1)

        # Cache the result
        if [ -n "$CIPHER_MSG" ]; then
          echo "$STATE_HASH" > "$CACHE_FILE"
          echo "$CIPHER_MSG" >> "$CACHE_FILE"
        fi
      fi

      if [ -n "$CIPHER_MSG" ]; then
        sketchybar --set "$NAME" label="$CIPHER_MSG" drawing=on
      else
        sketchybar --set "$NAME" drawing=off
      fi
    else
      sketchybar --set "$NAME" drawing=off
    fi
  else
    # Event within 4 hours - show normally
    sketchybar --set "$NAME" label="$LABEL" drawing=on
  fi
else
  # No upcoming timed events at all - cipher message
  if command -v /opt/homebrew/bin/llm &>/dev/null; then
    HOUR=$(date +%H)

    # Get Things context
    TODAY_TASKS=$(osascript -e 'tell application "Things3" to get name of to dos of list "Today"' 2>/dev/null)
    COMPLETED_TODAY=$(osascript -e 'tell application "Things3" to get name of to dos whose status is completed and completion date is (current date)' 2>/dev/null)
    TASK_COUNT=$(echo "$TODAY_TASKS" | grep -o ',' | wc -l | xargs)
    COMPLETED_COUNT=$(echo "$COMPLETED_TODAY" | grep -o ',' | wc -l | xargs)

    # Create state hash from actual task content (not just count)
    TASKS_HASH=$(echo "$TODAY_TASKS" | md5)
    STATE_HASH="${HOUR}_${TASKS_HASH}_${COMPLETED_COUNT}_none"

    # Check cache
    if [ -f "$CACHE_FILE" ]; then
      CACHED_STATE=$(head -n 1 "$CACHE_FILE")
      if [ "$CACHED_STATE" = "$STATE_HASH" ]; then
        # State unchanged, use cached message
        CIPHER_MSG=$(tail -n 1 "$CACHE_FILE")
      fi
    fi

    # Generate new message if no cache hit
    if [ -z "$CIPHER_MSG" ]; then
      PROMPT="You are CIPHER, a supportive coach (not a taskmaster). Here are today's tasks: $TODAY_TASKS

Pick the most joyful/appealing one and highlight it in a brief, encouraging way (~10 words max). Focus on what makes it interesting or rewarding. No generic motivation - be specific to the task. Just output the message, nothing else."
      CIPHER_MSG=$(echo "$PROMPT" | /opt/homebrew/bin/llm -m gpt-4o-mini -o max_tokens 25 2>/dev/null | head -n 1)

      # Cache the result
      if [ -n "$CIPHER_MSG" ]; then
        echo "$STATE_HASH" > "$CACHE_FILE"
        echo "$CIPHER_MSG" >> "$CACHE_FILE"
      fi
    fi

    if [ -n "$CIPHER_MSG" ]; then
      sketchybar --set "$NAME" label="$CIPHER_MSG" drawing=on
    else
      sketchybar --set "$NAME" drawing=off
    fi
  else
    sketchybar --set "$NAME" drawing=off
  fi
fi
