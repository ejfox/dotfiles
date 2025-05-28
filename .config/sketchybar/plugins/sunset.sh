#!/bin/bash

# Fetch sunset time for New York City
SUNSET_TIME=$(curl -s "wttr.in/New_York?format=%s")

# Set emoji and update sketchybar
if [ -n "$SUNSET_TIME" ] && [ "$SUNSET_TIME" != "null" ]; then
  sketchybar --set $NAME icon="S" label="$SUNSET_TIME" drawing=on
else
  sketchybar --set $NAME drawing=off
fi