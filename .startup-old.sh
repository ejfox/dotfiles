#!/bin/bash
# ~/.startup.sh - EJ Fox's terminal startup with personalized MOTD

# Skip in zen mode
if [ -f "/tmp/.zen-mode-state" ]; then
  exit 0
fi

# Interrupt handler - ESC to skip
trap 'echo -e "\n\033[33m⏭️  Skipped startup\033[0m"; printf "\033[?25h"; exit 0' INT

# Check for instant mode
INSTANT_MODE=${STARTUP_INSTANT:-false}
if [ "$1" = "--instant" ] || [ "$1" = "--no-animations" ]; then
  INSTANT_MODE=true
fi

# Validate and sanitize environment variables
OBSIDIAN_ROOT="${OBSIDIAN_ROOT:-${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox}"
LLM_PATH="${LLM_PATH:-/opt/homebrew/bin/llm}"
CACHE_DIR="/tmp/startup_cache"
REFLECTION_CACHE="$CACHE_DIR/reflection_cache.txt"
PERSONA_FILE="$HOME/.dotfiles/.llm-persona.txt"

# Validate paths - prevent directory traversal
if [[ "$OBSIDIAN_ROOT" != "$HOME"* ]]; then
    echo "Error: OBSIDIAN_ROOT must be within user home directory" >&2
    exit 1
fi

# Function to safely create cache directory
create_cache_dir() {
    if ! mkdir -p "$CACHE_DIR" 2>/dev/null; then
        echo "Error: Cannot create cache directory $CACHE_DIR" >&2
        exit 1
    fi
    if [ ! -w "$CACHE_DIR" ]; then
        echo "Error: Cache directory $CACHE_DIR is not writable" >&2
        exit 1
    fi
}

# Function to safely write to cache with atomic operations
safe_write() {
    local file="$1"
    local content="$2"
    local temp_file="${file}.tmp.$$"
    
    if echo "$content" > "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$file" 2>/dev/null || {
            rm -f "$temp_file" 2>/dev/null
            return 1
        }
    else
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
}

# Function to check if dependency exists and is executable
check_dependency() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 && [ -x "$(command -v "$cmd")" ]
}

# Bulk dependency check
DEPS_AVAILABLE=""
check_dependency things-cli && DEPS_AVAILABLE="${DEPS_AVAILABLE}things-cli "
check_dependency icalBuddy && DEPS_AVAILABLE="${DEPS_AVAILABLE}icalBuddy "
check_dependency find && DEPS_AVAILABLE="${DEPS_AVAILABLE}find "
check_dependency "$LLM_PATH" && DEPS_AVAILABLE="${DEPS_AVAILABLE}llm "

# Helper functions to check specific dependencies
has_things() { [[ "$DEPS_AVAILABLE" =~ "things-cli" ]]; }
has_icalbuddy() { [[ "$DEPS_AVAILABLE" =~ "icalBuddy" ]]; }
has_find() { [[ "$DEPS_AVAILABLE" =~ "find" ]]; }
has_llm() { [[ "$DEPS_AVAILABLE" =~ "llm" ]]; }

# Geometric symbols matching your aesthetic
SYMBOL_TASK="◆"
SYMBOL_REPO="◇"
SYMBOL_NOTE="○"
SYMBOL_INSIGHT="▪"

# Loading animation characters
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPINNER_PID=""

# Function to show spinner with message
start_spinner() {
    local msg="$1"
    (
        i=0
        while true; do
            printf "\r\033[36m${SPINNER_CHARS:i:1} %s\033[0m" "$msg"
            i=$(( (i+1) % ${#SPINNER_CHARS} ))
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

stop_spinner() {
    if [ -n "$SPINNER_PID" ]; then
        kill $SPINNER_PID 2>/dev/null
        wait $SPINNER_PID 2>/dev/null
        printf "\r\033[K"  # Clear the line
    fi
}

# Create cache dir if it doesn't exist
create_cache_dir

# Mark if we need to regenerate cache
NEED_REGEN=false
if [[ ! -f "$REFLECTION_CACHE" || $(find "$REFLECTION_CACHE" -mmin +180 2>/dev/null) ]]; then
  NEED_REGEN=true
fi

    # Get calendar events for today using icalBuddy
    calendar_events=""
    if has_icalbuddy; then
      calendar_events=$(icalBuddy -f -nc -iep "datetime,title" -po "datetime,title" -df "%H:%M" -b "" -n eventsToday 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || echo "")
    fi

  # Get more detailed git status
  git_context=""
  for repo in $(find ~/code -maxdepth 1 -type d -exec test -d "{}/.git" \; -print | head -5); do
    repo_name=$(basename "$repo")
    cd "$repo" 2>/dev/null
    if [[ -n $(git status -s 2>/dev/null) ]]; then
      git_context="${git_context}${repo_name} has uncommitted changes. "
    fi
    # Check for PRs if gh is installed
    if command -v gh &>/dev/null; then
      pr_count=$(gh pr list --search "review-requested:@me" --json number 2>/dev/null | jq length 2>/dev/null || echo 0)
      if [ -n "$pr_count" ] && [ "$pr_count" -gt 0 ]; then
        git_context="${git_context}${repo_name} has ${pr_count} PRs needing review. "
      fi
    fi
  done
  cd - >/dev/null 2>&1

  cmd_history=$(tail -n 24 ~/.zsh_history | cut -d ';' -f 2-)
  
  # Run network calls in parallel
  curl -s --max-time 3 https://mastodon-posts.ejfox.tools > /tmp/mastodon_posts.tmp &
  curl -s --max-time 3 https://twitter-posts.ejfox.tools/today > /tmp/twitter_posts.tmp &
  
  # Wait for both to complete
  wait
  
  latest_mastodon_posts=$(cat /tmp/mastodon_posts.tmp 2>/dev/null || echo "")
  historical_tweets=$(cat /tmp/twitter_posts.tmp 2>/dev/null | cut -c 1-1000)

  # Get recent notes with their content preview
  recent_notes=""
  while IFS= read -r note; do
    if [ -f "$note" ]; then
      note_name=$(basename "$note" .md)
      # Get first non-empty line that isn't a header
      preview=$(grep -v '^#' "$note" | grep -v '^$' | head -1 | cut -c 1-50)
      recent_notes="${recent_notes}${note_name}: ${preview}... "
    fi
  done < <(find "${OBSIDIAN_ROOT}" -type f -name "*.md" -mtime -1 -not -path '*/\.*' | head -3)

  # Enhanced prompt that asks for connections and insights
  reflection_prompt="$(cat $PERSONA_FILE)
  
Current context:
- Working Directory: $(pwd)
- Time: $(date '+%A, %B %d, %I:%M %p')
- Today's Tasks: $today_tasks
- Calendar Events: ${calendar_events:-No events today}
- Git Status: ${git_context:-All repos clean}
- Recent Terminal Commands: $cmd_history
- Recent Notes: ${recent_notes:-No recent notes}
- Latest Mastodon Posts: $latest_mastodon_posts
- Historical Tweets (Today in History): ${historical_tweets:-No historical tweets}

Based on this context, provide 2-3 specific, actionable insights:
1. What connections do you see between current work and scheduled time?
2. What's the most important thing to focus on right now?
3. Any patterns or opportunities you notice?

Keep it concise and practical. Use a calm, focused tone.
IMPORTANT: Output plain text only. NO markdown formatting.
Use unicode symbols like → ▸ ▪ ◆ • ⚡ ⚠ ✓ ✗ instead of markdown.
Format as short, punchy lines. Think terminal aesthetic."

    # Generate reflection using LLM if available
    if has_llm && [ -f "$PERSONA_FILE" ]; then
      # Check if cache is being regenerated
      echo -e "\n\033[1mINSIGHTS\033[0m"
      echo -e "\033[36m◆ Analyzing context and generating insights...\033[0m"
      
      # Stream LLM output directly to terminal AND cache file
      TEMP_CACHE="${REFLECTION_CACHE}.tmp.$$"
      
      # Use tee to show output while saving
      echo "$reflection_prompt" | "$LLM_PATH" -m gpt-4o-mini -o max_tokens 200 --no-log 2>/dev/null | while IFS= read -r line; do
        # Print each line with the insight symbol and slight delay for typing effect
        echo "  $SYMBOL_INSIGHT $line" | tee -a "$TEMP_CACHE"
        sleep 0.02  # Small delay for typing effect
      done
      
      # Move temp to actual cache
      if [ -s "$TEMP_CACHE" ]; then
        mv "$TEMP_CACHE" "$REFLECTION_CACHE"
      else
        safe_write "$REFLECTION_CACHE" "AI reflection unavailable"
      fi
    else
      safe_write "$REFLECTION_CACHE" "AI reflection unavailable"
    fi
  else
    # Another process is generating, wait briefly then continue
    sleep 0.1
  fi
fi

# Progressive display functions
current_line=4

show_section() {
    local section_name="$1"
    local -a lines=("${@:2}")
    
    if [ "$INSTANT_MODE" = "true" ]; then
        echo -e "\n\033[1m$section_name\033[0m"
        for line in "${lines[@]}"; do
            echo -e "$line"
        done
        return
    fi
    
    # Progressive mode: show section header immediately
    echo -e "\n\033[1m$section_name\033[0m"
    
    # Then show lines with typing effect only for insights
    for line in "${lines[@]}"; do
        echo -e "$line"
        # Only animate the insights section (longest section)
        if [[ "$section_name" == "INSIGHTS" ]]; then
            sleep 0.01  # 10ms for insights only
        fi
    done
}

# Don't clear screen - just add space
echo ""
echo ""

# Show header immediately
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1m$(date '+%A, %B %d - %I:%M %p')\033[0m"
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Show gathering status
echo -e "\033[36m◆ Gathering system context...\033[0m"

# Start background jobs for data fetching - only if dependencies are available
{
  if has_things; then
    things-cli today | head -n 3 > /tmp/startup_cache/tasks.txt 2>/dev/null
  else
    rm -f /tmp/startup_cache/tasks.txt 2>/dev/null
  fi
} &
TASKS_PID=$!

{
  if has_icalbuddy; then
    icalBuddy -f -nc -iep "datetime,title" -po "datetime,title" -df "%H:%M" -b "" -n eventsToday 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' > /tmp/startup_cache/calendar.txt
  else
    rm -f /tmp/startup_cache/calendar.txt 2>/dev/null
  fi
} &
CALENDAR_PID=$!

{
  if has_find && [ -d ~/code ]; then
    find ~/code -maxdepth 1 -type d -exec test -d "{}/.git" \; -print 2>/dev/null |
      xargs -I{} bash -c 'printf "%s\t%s\n" "$(stat -f "%m" "{}")" "$(basename "{}")"' 2>/dev/null |
      sort -rn | head -n 3 | cut -f2- > /tmp/startup_cache/repos.txt 2>/dev/null
  else
    rm -f /tmp/startup_cache/repos.txt 2>/dev/null
  fi
} &
REPOS_PID=$!

{
  if has_find && [ -d "${OBSIDIAN_ROOT}" ]; then
    find "${OBSIDIAN_ROOT}" -type f -name "*.md" -mtime -1 -not -path '*/\.*' 2>/dev/null | head -3 > /tmp/startup_cache/notes.txt 2>/dev/null
  else
    rm -f /tmp/startup_cache/notes.txt 2>/dev/null
  fi
} &
NOTES_PID=$!

# Show sections as they complete - no artificial delays!
# Tasks (usually fastest)
wait $TASKS_PID
if [ -f /tmp/startup_cache/tasks.txt ] && [ -s /tmp/startup_cache/tasks.txt ]; then
  task_lines=()
  while IFS= read -r task; do
    task_lines+=("  $SYMBOL_TASK $task")
  done < /tmp/startup_cache/tasks.txt
  show_section "TODAY'S MISSION" "${task_lines[@]}"
fi

# Calendar
wait $CALENDAR_PID  
if [ -f /tmp/startup_cache/calendar.txt ] && [ -s /tmp/startup_cache/calendar.txt ]; then
  calendar_lines=()
  while IFS= read -r event; do
    # Trim leading/trailing whitespace
    event=$(echo "$event" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    calendar_lines+=("  $SYMBOL_NOTE $event")
  done < <(head -3 /tmp/startup_cache/calendar.txt)
  show_section "SCHEDULE" "${calendar_lines[@]}"
fi

# Recent work
wait $REPOS_PID
if [ -f /tmp/startup_cache/repos.txt ] && [ -s /tmp/startup_cache/repos.txt ]; then
  repo_lines=()
  while IFS= read -r repo; do
    repo_lines+=("  $SYMBOL_REPO $repo")
  done < /tmp/startup_cache/repos.txt
  show_section "RECENT WORK" "${repo_lines[@]}"
fi

# Recent notes  
wait $NOTES_PID
if [ -f /tmp/startup_cache/notes.txt ] && [ -s /tmp/startup_cache/notes.txt ]; then
  note_lines=()
  while IFS= read -r note; do
    note_name=$(basename "$note" .md)
    note_lines+=("  $SYMBOL_NOTE $note_name")
  done < /tmp/startup_cache/notes.txt
  show_section "RECENT NOTES" "${note_lines[@]}"
fi

# AI Insights - show from cache if available and fresh
if [[ -f "$REFLECTION_CACHE" && ! $(find "$REFLECTION_CACHE" -mmin +180 2>/dev/null) ]]; then
  # Cache is fresh, just display it
  insights_text=$(cat "$REFLECTION_CACHE" | fold -s -w 70)
  if [ ! -z "$insights_text" ]; then
    insight_lines=()
    while IFS= read -r line; do
      insight_lines+=("  $SYMBOL_INSIGHT $line")
    done <<< "$insights_text"
    show_section "INSIGHTS (cached)" "${insight_lines[@]}"
  fi
else
  # Cache is stale or missing - it will be regenerated above with streaming
  # The streaming happens in the cache generation block, so nothing to show here
  :
fi

# Footer
echo -e "\n\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1mSYSTEM READY\033[0m"

# Show cursor again
if [ "$INSTANT_MODE" = "false" ]; then
    printf "\033[?25h"  # Show cursor
fi

# Add whitespace at the end
echo
echo
echo

