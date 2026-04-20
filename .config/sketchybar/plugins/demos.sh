#!/bin/bash
# Demos widget: 4-week dot matrix of recordings in ~/demos.
# Hidden when any macOS Focus mode is active.

. "$(dirname "$0")/_lib.sh"

if focus_active; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

DEMO_DIR="$HOME/demos"
WS=$(week_start_monday)

W0=0; W1=0; W2=0; W3=0
LATEST=0

if [ -d "$DEMO_DIR" ]; then
  # Collect mtimes of demo artifacts (screenstudio projects or mp4 files).
  while IFS= read -r ts; do
    [ -z "$ts" ] && continue
    [ "$ts" -gt "$LATEST" ] && LATEST=$ts
    b=$(bucket_for "$ts" "$WS")
    case "$b" in
      0) W0=1 ;;
      1) W1=1 ;;
      2) W2=1 ;;
      3) W3=1 ;;
    esac
  done < <(
    find "$DEMO_DIR" -maxdepth 2 \( -name "*.screenstudio" -o -name "*.mp4" \) \
      -exec stat -f "%m" {} \; 2>/dev/null
  )
fi

LABEL=$(render_matrix "$W0" "$W1" "$W2" "$W3" "$LATEST")

sketchybar --set "$NAME" \
  drawing=on \
  label="$LABEL" \
  label.color="$DEFAULT" \
  click_script="open -a 'Screen Studio'"
