#!/bin/bash

# Get battery info from ioreg (more accurate than pmset)
BATTERY_INFO=$(ioreg -rc AppleSmartBattery)
PERCENTAGE=$(echo "$BATTERY_INFO" | grep -o '"CurrentCapacity" = [0-9]*' | awk '{print $3}')
MAX_CAPACITY=$(echo "$BATTERY_INFO" | grep -o '"MaxCapacity" = [0-9]*' | awk '{print $3}')
DESIGN_CAPACITY=$(echo "$BATTERY_INFO" | grep -o '"DesignCapacity" = [0-9]*' | awk '{print $3}')
IS_CHARGING=$(echo "$BATTERY_INFO" | grep -o '"IsCharging" = [A-Za-z]*' | awk '{print $3}')
TIME_TO_EMPTY=$(echo "$BATTERY_INFO" | grep -o '"TimeRemaining" = [0-9]*' | awk '{print $3}')
TIME_TO_FULL=$(echo "$BATTERY_INFO" | grep -o '"AvgTimeToFull" = [0-9]*' | awk '{print $3}')
AMPERAGE=$(echo "$BATTERY_INFO" | grep -o '"Amperage" = [0-9-]*' | awk '{print $3}')

# Calculate actual percentage
if [ -n "$PERCENTAGE" ] && [ -n "$MAX_CAPACITY" ] && [ "$MAX_CAPACITY" -gt 0 ]; then
  PERCENT=$((PERCENTAGE * 100 / MAX_CAPACITY))
else
  PERCENT=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
fi

# Smart time calculation
format_time() {
  local minutes=$1
  if [ "$minutes" -lt 60 ]; then
    echo "${minutes}m"
  else
    local hours=$((minutes / 60))
    local mins=$((minutes % 60))
    if [ "$mins" -eq 0 ]; then
      echo "${hours}h"
    else
      echo "${hours}h${mins}m"
    fi
  fi
}

# Get time remaining
if [ "$IS_CHARGING" = "Yes" ]; then
  if [ -n "$TIME_TO_FULL" ] && [ "$TIME_TO_FULL" -gt 0 ] && [ "$TIME_TO_FULL" -lt 65535 ]; then
    TIME_LABEL="↑$(format_time $TIME_TO_FULL)"
  else
    TIME_LABEL="charging"
  fi
  ICON=""
elif [ -n "$TIME_TO_EMPTY" ] && [ "$TIME_TO_EMPTY" -gt 0 ] && [ "$TIME_TO_EMPTY" -lt 65535 ]; then
  TIME_LABEL="$(format_time $TIME_TO_EMPTY)"
  
  # Smart icon based on percentage
  case $PERCENT in
    9[0-9]|100) ICON="" ;;
    [7-8][0-9]) ICON="" ;;
    [5-6][0-9]) ICON="" ;;
    [3-4][0-9]) ICON="" ;;
    [2][0-9]) ICON="" ;;
    1[0-9]) ICON="" ;;
    *) ICON="" ;;
  esac
else
  # Fallback calculation based on current draw
  if [ -n "$AMPERAGE" ] && [ "$AMPERAGE" -lt 0 ]; then
    # Convert to positive and calculate hours
    CURRENT_MA=${AMPERAGE#-}
    if [ "$CURRENT_MA" -gt 0 ]; then
      MINUTES_REMAINING=$((PERCENTAGE * 60 / CURRENT_MA))
      TIME_LABEL="~$(format_time $MINUTES_REMAINING)"
    else
      TIME_LABEL="calculating"
    fi
  else
    TIME_LABEL="∞"
  fi
  
  case $PERCENT in
    9[0-9]|100) ICON="" ;;
    [7-8][0-9]) ICON="" ;;
    [5-6][0-9]) ICON="" ;;
    [3-4][0-9]) ICON="" ;;
    [2][0-9]) ICON="" ;;
    1[0-9]) ICON="" ;;
    *) ICON="" ;;
  esac
fi

# Vulpes color palette - vibrant reds and pinks
# base: #f30061 (magenta), secondary: #fd0022 (red), tertiary: #ff279a (pink), accent: #ff1865
if [ "$PERCENT" -le 10 ]; then
  COLOR="0xfffd0022"  # Vulpes red - critical (<10%)
elif [ "$PERCENT" -le 20 ]; then
  COLOR="0xfff30061"  # Vulpes magenta - low (10-20%)
elif [ "$PERCENT" -le 40 ]; then
  COLOR="0xffff1865"  # Vulpes accent - getting low (20-40%)
elif [ "$IS_CHARGING" = "Yes" ]; then
  COLOR="0xffff279a"  # Vulpes pink - charging (lively!)
else
  COLOR="0xffe5dcdc"  # Vulpes muted pink - normal (subtle)
fi

# Fade bar background based on battery percentage
# Above 50% = OLED black, below 50% = gradual fade to alarming red
if [ "$IS_CHARGING" = "Yes" ]; then
  # Always black when charging
  BAR_COLOR="0xff000000"
elif [ "$PERCENT" -ge 50 ]; then
  # OLED black above 50%
  BAR_COLOR="0xff000000"
else
  # Fade from black (50%) to alarming red (0%)
  # INTENSITY: 0 at 50%, 100 at 0%
  INTENSITY=$(( (50 - PERCENT) * 100 / 50 ))

  # Fade from pure black to alarming red (#aa0011)
  RED=$(( 170 * INTENSITY / 100 ))     # 0x00 -> 0xaa (170)
  GREEN=0                               # stays black
  BLUE=$(( 17 * INTENSITY / 100 ))     # 0x00 -> 0x11 (17)

  RED_HEX=$(printf "%02x" $RED)
  GREEN_HEX=$(printf "%02x" $GREEN)
  BLUE_HEX=$(printf "%02x" $BLUE)

  BAR_COLOR="0xff${RED_HEX}${GREEN_HEX}${BLUE_HEX}"
fi

# Update bar background color
sketchybar --bar color="$BAR_COLOR"

# Always show battery status
sketchybar --set battery drawing=on icon="$ICON" label="$TIME_LABEL" icon.color="$COLOR" label.color="$COLOR"