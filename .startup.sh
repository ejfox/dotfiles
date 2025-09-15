#!/bin/bash
# ~/.startup.sh - Fast, non-blocking terminal startup with streaming insights

# Skip in zen mode
if [ -f "/tmp/.zen-mode-state" ]; then
  exit 0
fi

# Interrupt handler - ESC to skip
trap 'echo -e "\n\033[33m⏭️  Skipped startup\033[0m"; exit 0' INT

# Configuration
CACHE_DIR="/tmp/startup_cache"
REFLECTION_CACHE="$CACHE_DIR/reflection_cache.txt"
PERSONA_FILE="$HOME/.dotfiles/.llm-persona.txt"
LLM_PATH="${LLM_PATH:-/opt/homebrew/bin/llm}"
OBSIDIAN_ROOT="${OBSIDIAN_ROOT:-${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox}"

# Symbols
SYMBOL_TASK="◆"
SYMBOL_REPO="◇"
SYMBOL_NOTE="○"
SYMBOL_INSIGHT="▪"

# Create cache dir
mkdir -p "$CACHE_DIR"

# Helper function to check commands
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# IMMEDIATELY show header (no clear, no delay)
echo ""
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1m$(date '+%A, %B %d - %I:%M %p')\033[0m"
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Start gathering data in background IMMEDIATELY
echo -e "\033[36m◆ Loading...\033[0m"

# Tasks
if has_cmd things-cli; then
  (things-cli today | head -n 3 | while read line; do
    echo "  $SYMBOL_TASK $line"
  done > "$CACHE_DIR/tasks.tmp") &
  TASKS_PID=$!
fi

# Calendar
if has_cmd icalBuddy; then
  (icalBuddy -f -nc -iep "datetime,title" -po "datetime,title" -df "%H:%M" -b "" -n eventsToday 2>/dev/null | 
   sed 's/\x1b\[[0-9;]*m//g' | head -3 | while read line; do
    echo "  $SYMBOL_NOTE $line"
  done > "$CACHE_DIR/calendar.tmp") &
  CALENDAR_PID=$!
fi

# Recent repos
if [ -d ~/code ]; then
  (find ~/code -maxdepth 2 -type d -name ".git" 2>/dev/null | head -3 | while read gitdir; do
    repo=$(dirname "$gitdir")
    echo "  $SYMBOL_REPO $(basename "$repo")"
  done > "$CACHE_DIR/repos.tmp") &
  REPOS_PID=$!
fi

# Recent notes
if [ -d "$OBSIDIAN_ROOT" ]; then
  (find "$OBSIDIAN_ROOT" -type f -name "*.md" 2>/dev/null | head -3 | while read note; do
    echo "  $SYMBOL_NOTE $(basename "$note" .md)"
  done > "$CACHE_DIR/notes.tmp") &
  NOTES_PID=$!
fi

# Background email sync (non-blocking)
if [ -x "$HOME/.email-auto-sync.sh" ]; then
  "$HOME/.email-auto-sync.sh" &
fi

# Email summary
if [ -x "$HOME/.email-summary.sh" ]; then
  ("$HOME/.email-summary.sh" > "$CACHE_DIR/email.tmp") &
  EMAIL_PID=$!
fi

# Clear loading line
printf "\r\033[K"

# Display sections as they complete (no waiting)
if [ -n "$TASKS_PID" ]; then
  wait $TASKS_PID 2>/dev/null
  if [ -s "$CACHE_DIR/tasks.tmp" ]; then
    echo -e "\n\033[1mTODAY'S MISSION\033[0m"
    cat "$CACHE_DIR/tasks.tmp"
  fi
fi

if [ -n "$CALENDAR_PID" ]; then
  wait $CALENDAR_PID 2>/dev/null
  if [ -s "$CACHE_DIR/calendar.tmp" ]; then
    echo -e "\n\033[1mSCHEDULE\033[0m"
    cat "$CACHE_DIR/calendar.tmp"
  fi
fi

if [ -n "$REPOS_PID" ]; then
  wait $REPOS_PID 2>/dev/null
  if [ -s "$CACHE_DIR/repos.tmp" ]; then
    echo -e "\n\033[1mRECENT WORK\033[0m"
    cat "$CACHE_DIR/repos.tmp"
  fi
fi

if [ -n "$NOTES_PID" ]; then
  wait $NOTES_PID 2>/dev/null
  if [ -s "$CACHE_DIR/notes.tmp" ]; then
    echo -e "\n\033[1mRECENT NOTES\033[0m"
    cat "$CACHE_DIR/notes.tmp"
  fi
fi

if [ -n "$EMAIL_PID" ]; then
  wait $EMAIL_PID 2>/dev/null
  if [ -s "$CACHE_DIR/email.tmp" ]; then
    echo -e "\n\033[1mEMAIL\033[0m"
    cat "$CACHE_DIR/email.tmp"
  fi
fi

# Handle insights - check cache age
if [[ -f "$REFLECTION_CACHE" ]] && [[ -z $(find "$REFLECTION_CACHE" -mmin +180 2>/dev/null) ]]; then
  # Cache is fresh, just display it
  echo -e "\n\033[1mINSIGHTS\033[0m \033[2m(cached)\033[0m"
  cat "$REFLECTION_CACHE" | while IFS= read -r line; do
    echo "  $SYMBOL_INSIGHT $line"
  done
else
  # Cache is stale, regenerate with streaming
  echo -e "\n\033[1mINSIGHTS\033[0m"
  echo -e "\033[36m◆ Generating fresh insights...\033[0m"
  
  if has_cmd "$LLM_PATH" && [ -f "$PERSONA_FILE" ]; then
    # Gather context quickly
    tasks=$(has_cmd things-cli && things-cli today | head -5 2>/dev/null || echo "No tasks")
    
    # Build minimal prompt
    prompt="$(cat "$PERSONA_FILE")

Context:
- Time: $(date '+%A, %B %d, %I:%M %p')
- Tasks: $tasks
- Directory: $(pwd)

Provide 2-3 brief, actionable insights. Use symbols like → ▸ ▪ ◆ • ⚡.
Keep it punchy. Terminal aesthetic. NO markdown."

    # Stream output directly
    echo "$prompt" | "$LLM_PATH" -m 4o-mini -o max_tokens 150 --no-log 2>/dev/null | tee "$REFLECTION_CACHE.tmp" | while IFS= read -r line; do
      echo "  $SYMBOL_INSIGHT $line"
      sleep 0.01  # Tiny delay for effect
    done
    
    # Save cache
    if [ -s "$REFLECTION_CACHE.tmp" ]; then
      mv "$REFLECTION_CACHE.tmp" "$REFLECTION_CACHE"
    fi
  else
    echo "  $SYMBOL_INSIGHT Configure LLM for personalized insights"
  fi
fi

# Footer
echo -e "\n\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1mSYSTEM READY\033[0m"
echo ""