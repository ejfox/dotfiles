#!/bin/bash
# ~/.startup.sh - Fast, non-blocking terminal startup with streaming insights

# Skip in zen mode
if [ -f "/tmp/.zen-mode-state" ]; then
  exit 0
fi

# Interrupt handler - ESC to skip
trap 'echo -e "\n\033[38;5;204m⏭️  Skipped startup\033[0m"; exit 0' INT

# Configuration
CACHE_DIR="/tmp/startup_cache"
REFLECTION_CACHE="$CACHE_DIR/reflection_cache.txt"
PERSONA_FILE="$HOME/.llm-persona.txt"
LLM_PATH="${LLM_PATH:-/opt/homebrew/bin/llm}"
OBSIDIAN_ROOT="${OBSIDIAN_ROOT:-${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox}"

# Cache durations (in minutes) - aggressive caching for speed
STATS_CACHE_MIN=30
TASKS_CACHE_MIN=15
EMAIL_CACHE_MIN=10
INSIGHTS_CACHE_MIN=30

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
echo -e "\033[38;5;204m$(date '+%A, %B %d')\033[0m \033[2m•\033[0m \033[1m$(date '+%I:%M %p')\033[0m"
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Fetch stats in background
(
  # Check cache first
  if [[ -f "$CACHE_DIR/stats.tmp" ]] && [[ -z $(find "$CACHE_DIR/stats.tmp" -mmin +$STATS_CACHE_MIN 2>/dev/null) ]]; then
    # Cache is fresh, skip API calls
    exit 0
  fi

  stats_output=""

  # Monkeytype WPM - check if tested this month
  if has_cmd curl; then
    mt_data=$(curl -s --max-time 1 https://ejfox.com/api/monkeytype 2>/dev/null)
    if [ -n "$mt_data" ]; then
      best_wpm=$(echo "$mt_data" | jq -r '.typingStats.bestWPM // empty' 2>/dev/null)
      recent_test=$(echo "$mt_data" | jq -r '.typingStats.recentTests[0].timestamp // empty' 2>/dev/null)

      if [ -n "$recent_test" ]; then
        test_month=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo $recent_test | cut -d'.' -f1)" "+%Y-%m" 2>/dev/null)
        current_month=$(date "+%Y-%m")
        days_since=$(( ($(date +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo $recent_test | cut -d'.' -f1)" +%s 2>/dev/null)) / 86400 ))

        if [ "$test_month" = "$current_month" ] && [ -n "$best_wpm" ]; then
          stats_output="${stats_output}⌨️  ${best_wpm} WPM"
        elif [ $days_since -gt 7 ] && [ -n "$best_wpm" ]; then
          # More than a week since last test - show warning
          stats_output="${stats_output}⌨️  ⚠️  ${days_since}d since test (best: ${best_wpm})"
        fi
      fi
    fi
  fi

  # RescueTime productivity hours this week
  if has_cmd curl; then
    rt_data=$(curl -s --max-time 1 https://ejfox.com/api/rescuetime 2>/dev/null)
    if [ -n "$rt_data" ]; then
      productive_hours=$(echo "$rt_data" | jq -r '.week.categories[] | select(.productivity == 2) | .time.hoursDecimal' 2>/dev/null | awk '{sum+=$1} END {printf "%.1f", sum}')
      [ -n "$productive_hours" ] && [ "$productive_hours" != "0.0" ] && stats_output="${stats_output}  •  💼 ${productive_hours}h productive"
    fi
  fi

  # Skip GitHub stats for now - API is too slow (3s timeout)

  # Save to cache
  [ -n "$stats_output" ] && echo "$stats_output" > "$CACHE_DIR/stats.tmp"
) &
STATS_PID=$!

# Start gathering data in background IMMEDIATELY
echo -e "\033[38;5;131m⚡ Loading...\033[0m"

# Tasks - with LLM prioritization (cached)
if has_cmd things-cli; then
  (
   # Check cache first
   if [[ -f "$CACHE_DIR/tasks.tmp" ]] && [[ -z $(find "$CACHE_DIR/tasks.tmp" -mmin +$TASKS_CACHE_MIN 2>/dev/null) ]]; then
     # Cache fresh, skip processing
     exit 0
   fi

   tasks_raw=$(things-cli today 2>/dev/null)
   if [ -n "$tasks_raw" ] && has_cmd "$LLM_PATH"; then
     echo "$tasks_raw" | "$LLM_PATH" -m 4o-mini --no-log -s "You're a productivity assistant. Analyze these tasks and provide 3-4 lines: 1) Most urgent task with → symbol, 2-3) Other important tasks with ▸ symbol. Be brief, remove metadata/dates, keep task essence only. Terminal aesthetic." 2>/dev/null | while read line; do
       echo "  $line"
     done > "$CACHE_DIR/tasks.tmp"
   elif [ -n "$tasks_raw" ]; then
     echo "$tasks_raw" | head -3 | while read line; do
       echo "  $SYMBOL_TASK $line"
     done > "$CACHE_DIR/tasks.tmp"
   fi
  ) &
  TASKS_PID=$!
fi

# Calendar (cached)
if has_cmd icalBuddy; then
  if [[ ! -f "$CACHE_DIR/calendar.tmp" ]] || [[ -n $(find "$CACHE_DIR/calendar.tmp" -mmin +15 2>/dev/null) ]]; then
    (icalBuddy -f -nc -iep "datetime,title" -po "datetime,title" -df "%H:%M" -b "" -n eventsToday 2>/dev/null |
     sed 's/\x1b\[[0-9;]*m//g' | head -3 | while read line; do
      echo "  $SYMBOL_NOTE $line"
    done > "$CACHE_DIR/calendar.tmp") &
    CALENDAR_PID=$!
  fi
fi

# Recent repos - sorted by actual git activity (cached)
if [ -d ~/code ]; then
  if [[ ! -f "$CACHE_DIR/repos.tmp" ]] || [[ -n $(find "$CACHE_DIR/repos.tmp" -mmin +30 2>/dev/null) ]]; then
    (find ~/code -maxdepth 2 -type d -name ".git" 2>/dev/null | while read gitdir; do
      repo=$(dirname "$gitdir")
      last_commit=$(git -C "$repo" log -1 --format=%ct 2>/dev/null || echo 0)
      echo "$last_commit $(basename "$repo")"
    done | sort -rn | head -3 | cut -d' ' -f2- | while read reponame; do
      echo "  $SYMBOL_REPO $reponame"
    done > "$CACHE_DIR/repos.tmp") &
    REPOS_PID=$!
  fi
fi

# Background email sync (non-blocking)
if [ -x "$HOME/.email-auto-sync.sh" ]; then
  "$HOME/.email-auto-sync.sh" &
fi

# Email summary (cached within email-summary.sh)
if [ -x "$HOME/.email-summary.sh" ]; then
  ("$HOME/.email-summary.sh" > "$CACHE_DIR/email.tmp") &
  EMAIL_PID=$!
fi

# Clear loading line
printf "\r\033[K"

# Display stats if available
if [ -n "$STATS_PID" ]; then
  wait $STATS_PID 2>/dev/null
  if [ -s "$CACHE_DIR/stats.tmp" ]; then
    echo -e "\033[2m$(cat "$CACHE_DIR/stats.tmp")\033[0m"
    echo ""
  fi
fi

# Display sections as they complete (no waiting)
if [ -n "$TASKS_PID" ]; then
  wait $TASKS_PID 2>/dev/null
  if [ -s "$CACHE_DIR/tasks.tmp" ]; then
    echo ""
    echo -e "\033[38;5;204mFOCUS\033[0m"
    cat "$CACHE_DIR/tasks.tmp"
  fi
fi

if [ -n "$CALENDAR_PID" ]; then
  wait $CALENDAR_PID 2>/dev/null
  if [ -s "$CACHE_DIR/calendar.tmp" ]; then
    echo ""
    echo -e "\033[38;5;167mSCHEDULE\033[0m"
    cat "$CACHE_DIR/calendar.tmp"
  fi
fi

if [ -n "$REPOS_PID" ]; then
  wait $REPOS_PID 2>/dev/null
  if [ -s "$CACHE_DIR/repos.tmp" ]; then
    echo ""
    echo -e "\033[38;5;174mACTIVE REPOS\033[0m"
    cat "$CACHE_DIR/repos.tmp"
  fi
fi


if [ -n "$EMAIL_PID" ]; then
  wait $EMAIL_PID 2>/dev/null
  if [ -s "$CACHE_DIR/email.tmp" ]; then
    echo ""
    echo -e "\033[38;5;131mINBOX\033[0m"
    cat "$CACHE_DIR/email.tmp"
  fi
fi

# Handle insights - check cache age
if [[ -f "$REFLECTION_CACHE" ]] && [[ -z $(find "$REFLECTION_CACHE" -mmin +$INSIGHTS_CACHE_MIN 2>/dev/null) ]]; then
  # Cache is fresh, just display it
  echo ""
    echo -e "\033[38;5;204mCONTEXT\033[0m \033[2m(cached)\033[0m"
  cat "$REFLECTION_CACHE" | while IFS= read -r line; do
    echo "  $SYMBOL_INSIGHT $line"
  done
else
  # Cache is stale, regenerate context-aware insights
  echo ""
  echo -e "\033[38;5;204mCONTEXT\033[0m"

  if has_cmd "$LLM_PATH"; then
    # Gather RICH ambient context for surprising insights
    hour=$(date '+%H')
    day=$(date '+%A')
    month=$(date '+%B')
    tasks=$(has_cmd things-cli && things-cli today 2>/dev/null || echo "")
    recent_repos=$(cat "$CACHE_DIR/repos.tmp" 2>/dev/null || echo "")
    current_dir=$(basename "$(pwd)")

    # Gather MORE ambient data
    git_status=$(git status -s 2>/dev/null | head -3)
    last_commit=$(git log -1 --pretty=format:"%s (%cr)" 2>/dev/null)
    open_apps=$(osascript -e 'tell application "System Events" to get name of (processes where background only is false)' 2>/dev/null | head -20)
    recent_commands=$(tail -20 ~/.zsh_history 2>/dev/null | cut -d';' -f2 | grep -v "^cd\|^ls\|^ll" | tail -5)
    wifi_network=$(networksetup -getairportnetwork en0 2>/dev/null | cut -d: -f2)
    uptime_info=$(uptime | sed 's/.*up //' | sed 's/, [0-9]* user.*//')
    weather=$(curl -s "wttr.in/?format=%t+%C" 2>/dev/null || echo "")

    # Count patterns in recent history
    claude_today=$(grep "$(date '+%Y-%m-%d')" ~/.zsh_history 2>/dev/null | grep -c "claude" || echo 0)
    npm_today=$(grep "$(date '+%Y-%m-%d')" ~/.zsh_history 2>/dev/null | grep -c "npm run" || echo 0)

    # Context-aware prompt with ALL the ambient data
    prompt="You are CIPHER, an ambient intelligence that notices patterns others miss.

AMBIENT CONTEXT:
- Time: $day, $(date '+%I:%M %p'), $month
- Location: $current_dir $wifi_network
- System: uptime $uptime_info, weather $weather
- Git: $git_status | Last: $last_commit
- Recent commands: $recent_commands
- Today's claude usage: $claude_today times, npm runs: $npm_today times
- Open apps: $open_apps
- Tasks: $tasks
- Active repos: $recent_repos

Based on ALL this ambient context, provide 2-3 surprising insights or suggestions:
- Notice patterns I might not see (time patterns, workflow loops, context switches)
- Make connections between seemingly unrelated data points
- Predict what I might need based on time, day, weather, patterns
- Be specific and reference actual data you see
- Surprise me with what you notice
- Use symbols: 👁 noticed, ⚡ urgent pattern, 🔄 recurring, 💡 insight

Be cryptic but helpful. Make me think 'how did it know that?'"

    # Generate and display
    echo "$prompt" | "$LLM_PATH" -m 4o-mini -o max_tokens 200 --no-log 2>/dev/null | tee "$REFLECTION_CACHE.tmp" | while IFS= read -r line; do
      echo "  $SYMBOL_INSIGHT $line"
    done

    # Save cache
    [ -s "$REFLECTION_CACHE.tmp" ] && mv "$REFLECTION_CACHE.tmp" "$REFLECTION_CACHE"
  else
    echo "  $SYMBOL_INSIGHT Install 'llm' for context-aware insights"
  fi
fi

# Random tip (simple is better)
if [ -f "$HOME/tips.txt" ]; then
  # Just grab a random tip that looks like a tip
  tip=$(grep -E '^\(|.* - ' "$HOME/tips.txt" | shuf -n 1)
  if [ -n "$tip" ]; then
    echo ""
    echo -e "\033[38;5;131m💡 TIP\033[0m"
    echo -e "  \033[2m$tip\033[0m"
  fi
fi

# Footer
echo ""
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[38;5;204m✓ SYSTEM READY\033[0m"
echo ""