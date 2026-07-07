#!/bin/bash
# Foundations widget: count of open 🌞 Foundation dailies + oldest staleness.
# Visible only outside work hours (before 9:30am, after 5:30pm).
# Hidden when any macOS Focus mode is active.

. "$(dirname "$0")/_lib.sh"

# --- Work-hours gate ---
# 9:30 = 570 min; 17:30 = 1050 min
HOUR=$(date +%H)
MIN=$(date +%M)
NOW_MIN=$((10#$HOUR * 60 + 10#$MIN))
if [ "$NOW_MIN" -ge 570 ] && [ "$NOW_MIN" -lt 1050 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# --- Focus-mode gate (same behavior as demos/posts) ---
if focus_active; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# --- Query Things for the single oldest open 🌞 daily ---
# Returns: "<days_old>|<task_name>"; "0|" if nothing matches or Things is off.
RESULT=$(osascript -e '
try
  tell application "Things3"
    set oldestName to ""
    set oldest to (current date)
    set hasAny to false
    repeat with t in (to dos of list "Today")
      set tname to name of t
      if tname starts with "🌞" then
        try
          set ad to activation date of t
          if not hasAny or ad < oldest then
            set oldest to ad
            set oldestName to tname
            set hasAny to true
          end if
        end try
      end if
    end repeat
    if hasAny then
      set daysOld to (((current date) - oldest) / 86400) as integer
      return (daysOld as text) & "|" & oldestName
    else
      return "0|"
    end if
  end tell
on error
  return "0|"
end try
' 2>/dev/null)

DAYS="${RESULT%%|*}"
NAME_RAW="${RESULT#*|}"
NAME_CLEAN="${NAME_RAW#🌞}"
NAME_CLEAN="${NAME_CLEAN# }"

# Hide when there's nothing to nudge
if [ -z "$NAME_CLEAN" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Staleness suffix
if [ "$DAYS" -le 0 ]; then
  STALE=""
elif [ "$DAYS" -lt 14 ]; then
  STALE=" · ${DAYS}d"
elif [ "$DAYS" -lt 365 ]; then
  STALE=" · $((DAYS / 7))w"
else
  STALE=" · $((DAYS / 30))mo"
fi

sketchybar --set "$NAME" \
  drawing=on \
  label="${NAME_CLEAN}${STALE}" \
  label.color="$DEFAULT" \
  click_script="open 'things:///show?id=today'"
