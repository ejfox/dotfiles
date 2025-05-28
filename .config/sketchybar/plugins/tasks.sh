#!/bin/bash

# Get tasks for today, filtering for actual tasks
TASKS=$(things-cli today | grep -E '^\s*-\s' | grep -v '✓')
COMPLETED=$(things-cli today | grep -c '✓')
TOTAL=$(echo "$TASKS" | wc -l | tr -d ' ')

# Handle edge cases
if [ -z "$TASKS" ]; then
  sketchybar --set $NAME label="0/0" icon="0"
else
  # Ensure we don't go negative or exceed total
  COMPLETED=$(( COMPLETED > TOTAL ? TOTAL : COMPLETED ))
  sketchybar --set $NAME label="$COMPLETED/$TOTAL" icon="T"
fi
