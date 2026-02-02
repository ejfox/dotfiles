#!/bin/bash

# Creative Stats - Single item showing most relevant creative metric
# Priority: overdue demos > overdue notes > word count

WHITE="0xffffffff"
YELLOW="0xffffcc00"
RED="0xffff6b6b"
MUTED="0xff666666"

NOW=$(date +%s)

# --- DEMOS: Days since last demo (screenstudio projects or mp4s) ---
DEMO_DIR="$HOME/demos"
if [ -d "$DEMO_DIR" ]; then
  # Get most recent item (folder or file) by modification time
  LATEST_DEMO=$(ls -td "$DEMO_DIR"/*.screenstudio "$DEMO_DIR"/*.mp4 2>/dev/null | head -1)
  if [ -n "$LATEST_DEMO" ]; then
    DEMO_MTIME=$(stat -f %m "$LATEST_DEMO" 2>/dev/null)
    DEMO_AGE=$(( (NOW - DEMO_MTIME) / 86400 ))
  else
    DEMO_AGE=99
  fi
else
  DEMO_AGE=99
fi

# --- NOTES: Days since last Obsidian note ---
OBSIDIAN_VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
if [ -d "$OBSIDIAN_VAULT" ]; then
  # Find most recent .md file by modification time
  LATEST_NOTE_LINE=$(find "$OBSIDIAN_VAULT" -name "*.md" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1)
  if [ -n "$LATEST_NOTE_LINE" ]; then
    NOTE_MTIME=$(echo "$LATEST_NOTE_LINE" | cut -d' ' -f1)
    NOTE_AGE=$(( (NOW - NOTE_MTIME) / 86400 ))
  else
    NOTE_AGE=99
  fi
else
  NOTE_AGE=99
fi

# --- WORDS: Today's writing count ---
WRITING_DIR="$HOME/writing"
BLOG_DIR="$HOME/code/blog/content"

count_words_today() {
  local dir=$1
  if [ -d "$dir" ]; then
    # Files modified today (macOS: -mtime 0 means last 24h)
    for f in "$dir"/**/*.md; do
      [ -f "$f" ] && [ $(stat -f %m "$f") -gt $((NOW - 86400)) ] && cat "$f"
    done 2>/dev/null | wc -w | tr -d ' '
  else
    echo 0
  fi
}

WORDS_TODAY=$(( $(count_words_today "$WRITING_DIR") + $(count_words_today "$BLOG_DIR") ))

# --- PRIORITY LOGIC ---
# Show most urgent/relevant stat

if [ "$DEMO_AGE" -ge 4 ]; then
  # Overdue demos - you should make something!
  ICON="󰕧"
  if [ "$DEMO_AGE" -ge 7 ]; then
    LABEL="${DEMO_AGE}d"
    COLOR=$RED
  elif [ "$DEMO_AGE" -ge 4 ]; then
    LABEL="${DEMO_AGE}d"
    COLOR=$YELLOW
  fi
  CLICK="open ~/demos"

elif [ "$NOTE_AGE" -ge 3 ]; then
  # Overdue notes - document your work!
  ICON="󰎞"
  if [ "$NOTE_AGE" -ge 5 ]; then
    LABEL="${NOTE_AGE}d"
    COLOR=$RED
  else
    LABEL="${NOTE_AGE}d"
    COLOR=$YELLOW
  fi
  CLICK="open 'obsidian://open?vault=ejfox'"

else
  # Default: show word count
  ICON="󱓧"
  if [ "$WORDS_TODAY" -gt 500 ]; then
    LABEL="${WORDS_TODAY}w"
    COLOR=$WHITE
  elif [ "$WORDS_TODAY" -gt 0 ]; then
    LABEL="${WORDS_TODAY}w"
    COLOR=$MUTED
  else
    # Nothing written yet - show as subtle prompt
    LABEL="0w"
    COLOR=$MUTED
  fi
  CLICK="open https://ejfox.com/blog"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL" icon.color="$COLOR" label.color="$COLOR" click_script="$CLICK"
