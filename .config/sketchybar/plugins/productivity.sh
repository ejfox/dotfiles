#!/bin/bash

# Fetch RescueTime data
DATA=$(curl -s --max-time 2 "https://ejfox.com/api/rescuetime")

if [ -z "$DATA" ]; then
  sketchybar --set $NAME label="??"
  exit 0
fi

# Get today's hours (rounded to nearest int)
TODAY_HOURS=$(echo "$DATA" | jq -r '.week.summary.total.hoursDecimal // 0' | awk '{print int($1+0.5)}')

# Calculate productive percentage (Software Dev + Design + Reference)
DEV_PERCENT=$(echo "$DATA" | jq -r '.week.activities[] | select(.name == "Software Development").percentageOfTotal // 0')
DESIGN_PERCENT=$(echo "$DATA" | jq -r '.week.activities[] | select(.name == "Design & Composition").percentageOfTotal // 0')
REF_PERCENT=$(echo "$DATA" | jq -r '.week.activities[] | select(.name == "Reference & Learning").percentageOfTotal // 0')
PRODUCTIVE_PERCENT=$((DEV_PERCENT + DESIGN_PERCENT + REF_PERCENT))

# Choose fill character based on productivity
if [ $PRODUCTIVE_PERCENT -ge 80 ]; then
  FILL="#"  # Fully productive
elif [ $PRODUCTIVE_PERCENT -ge 60 ]; then
  FILL="+"  # Mostly productive
elif [ $PRODUCTIVE_PERCENT -ge 40 ]; then
  FILL="*"  # Half productive
elif [ $PRODUCTIVE_PERCENT -ge 20 ]; then
  FILL="."  # Some productive
else
  FILL="o"  # Not productive
fi

# Combine fill + hours
LABEL="${FILL}${TODAY_HOURS}"

sketchybar --set $NAME label="$LABEL"