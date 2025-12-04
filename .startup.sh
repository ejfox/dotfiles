#!/bin/bash
################################################################################
# ~/.startup.sh - Ultra-fast terminal startup with intelligent caching
################################################################################
# FEATURES:
#   - Seamless offline/online operation (no blocking timeouts)
#   - Parallel background fetches for speed
#   - Intelligent caching (30min stats, 15min tasks, 15min calendar, 30min repos)
#   - Graceful fallbacks when tools/services unavailable
#   - LLM-powered task prioritization
#   - CIPHER ambient intelligence context insights
#   - Daily I Ching hexagram with wisdom
#
# COMPONENTS:
#   1. Network check: Quick 0.5s ping to 1.1.1.1, gates API calls
#   2. Stats: Monkeytype WPM + RescueTime productivity hours
#   3. I Ching: Daily hexagram with wisdom
#   4. Tasks: Things app tasks with LLM prioritization
#   5. Calendar: Today's events from icalBuddy
#   6. Repos: Top 3 recently modified git repos
#   7. Email: Summary from .email-summary.sh
#   8. Insights: LLM-generated pattern analysis
#
# EXECUTION TIME:
#   - Cold start (all fetches): ~3s
#   - Warm cache (instant): ~0.3s
#   - Offline fallback: instant
#
# DEPENDENCIES:
#   - things-cli (optional, for tasks)
#   - icalBuddy (optional, for calendar)
#   - jq (for JSON parsing)
#   - /opt/homebrew/bin/llm (optional, for insights)
#   - ~/.email-summary.sh (optional, for email)
#   - mystical-symbols.sh (for I Ching)
#
################################################################################

# Source mystical symbols library for I Ching
source "$HOME/.dotfiles/lib/mystical-symbols.sh" 2>/dev/null || true

# Skip if in zen mode (minimal distractions)
[ -f "/tmp/.zen-mode-state" ] && exit 0

# Allow ESC to skip startup
trap 'exit 0' INT

# Configuration
CACHE_DIR="/tmp/startup_cache"
mkdir -p "$CACHE_DIR"

# Cache TTLs (in minutes)
CACHE_STATS=30
CACHE_TASKS=15
CACHE_CALENDAR=15
CACHE_REPOS=30
CACHE_INSIGHTS=30

# Display symbols (no emojis)
SYMBOL_TASK="-"
SYMBOL_REPO="*"
SYMBOL_NOTE=">"
SYMBOL_INSIGHT=">"

# Display immediate header with date/time
echo ""
echo -e "\033[38;5;131m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[38;5;204m$(date '+%A, %B %d')\033[0m \033[2m•\033[0m \033[1m$(date '+%I:%M %p')\033[0m"
echo -e "\033[38;5;131m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Utility function: Check if cache is fresh
# Args: $1=filepath, $2=max_age_minutes
# Returns: 0 if fresh, 1 if stale
cache_fresh() {
  [[ -f "$1" ]] && [[ -z $(find "$1" -mmin +$2 2>/dev/null) ]]
}

# Network check: Fast 1.0s ping to Cloudflare DNS (cached for 1 min)
# Return code: 0=online, 1 or 124=offline
if cache_fresh "$CACHE_DIR/network.tmp" 1; then
  ONLINE=$(<"$CACHE_DIR/network.tmp")
else
  timeout 1.0 curl -fsSL -o /dev/null https://1.1.1.1 2>/dev/null
  ONLINE=$?
  # Treat timeout (124) as offline
  [ $ONLINE -eq 124 ] && ONLINE=1
  echo "$ONLINE" > "$CACHE_DIR/network.tmp"
fi

################################################################################
# COMPONENT 1: STATS (Typing speed + Productivity hours)
################################################################################
# Sources: ejfox.com/api/{monkeytype,rescuetime}
# TTL: 30 minutes
# Fallback: Shows previous stats or nothing if offline
#
fetch_stats() {
  cache_fresh "$CACHE_DIR/stats.tmp" $CACHE_STATS && return 0
  [ $ONLINE -eq 0 ] || return 0  # Skip if offline

  local mt=$(timeout 1.0 curl -fsSL https://ejfox.com/api/monkeytype 2>/dev/null | jq -r '.typingStats.bestWPM // empty' 2>/dev/null)
  local rt=$(timeout 1.0 curl -fsSL https://ejfox.com/api/rescuetime 2>/dev/null | jq -r '.week.categories[] | select(.productivity == 2) | .time.hoursDecimal' 2>/dev/null | awk '{sum+=$1} END {printf "%.1fh", sum}' 2>/dev/null)

  local stats="${mt:+$mt WPM}${mt:+ • }${rt:+$rt productive}"
  [ -n "${stats// }" ] && echo "$stats" > "$CACHE_DIR/stats.tmp"
}
fetch_stats &
STATS_PID=$!

################################################################################
# COMPONENT 2: TASKS (Things app with LLM prioritization)
################################################################################
# Source: things-cli today
# LLM: claude 4o-mini for intelligent prioritization
# TTL: 15 minutes
# Fallback: Raw tasks list if LLM unavailable or times out
#
fetch_tasks() {
  cache_fresh "$CACHE_DIR/tasks.tmp" $CACHE_TASKS && return 0
  command -v things-cli >/dev/null 2>&1 || return 0  # Skip if no things-cli

  local tasks=$(things-cli today 2>/dev/null | head -4)
  [ -z "$tasks" ] && return 0

  # Try LLM prioritization first (1.2s timeout)
  if command -v /opt/homebrew/bin/llm >/dev/null 2>&1; then
    echo "$tasks" | timeout 1.2 /opt/homebrew/bin/llm -m 4o-mini --no-log -s \
      "Prioritize these 3 tasks. Format: 1) most urgent, 2) secondary, 3) tertiary. Remove dates, strip metadata, be ultra-brief." 2>/dev/null | \
      sed 's/^/  /' > "$CACHE_DIR/tasks.tmp"
  fi

  # Fallback to raw tasks if LLM failed/timed out
  [ ! -s "$CACHE_DIR/tasks.tmp" ] && echo "$tasks" | head -3 | sed 's/^/  /' > "$CACHE_DIR/tasks.tmp"
}
fetch_tasks &
TASKS_PID=$!

################################################################################
# COMPONENT 3: CALENDAR (Today's events from icalBuddy)
################################################################################
# Source: icalBuddy eventsToday
# TTL: 15 minutes
# Fallback: Empty section if no events or tool unavailable
#
fetch_calendar() {
  cache_fresh "$CACHE_DIR/calendar.tmp" $CACHE_CALENDAR && return 0
  command -v icalBuddy >/dev/null 2>&1 || return 0  # Skip if no icalBuddy

  icalBuddy -f -nc -iep "datetime,title" -po "datetime,title" -df "%H:%M" -b "" \
    -n eventsToday 2>/dev/null | \
    sed 's/\x1b\[[0-9;]*m//g' | awk '!seen[$0]++' | head -3 | \
    sed 's/^/  /' > "$CACHE_DIR/calendar.tmp"
}
fetch_calendar &
CALENDAR_PID=$!

################################################################################
# COMPONENT 4: REPOS (Top 3 recently modified git repos)
################################################################################
# Source: git repos under ~/code
# Sort: By last commit timestamp (newest first)
# TTL: 30 minutes
# Fallback: Empty section if no repos found
#
fetch_repos() {
  cache_fresh "$CACHE_DIR/repos.tmp" $CACHE_REPOS && return 0
  [ -d ~/code ] || return 0  # Skip if ~/code doesn't exist

  find ~/code -maxdepth 2 -type d -name ".git" 2>/dev/null | while read gitdir; do
    repo=$(dirname "$gitdir")
    git -C "$repo" log -1 --format="%ct $(basename "$repo")" 2>/dev/null
  done | sort -rn | head -3 | cut -d' ' -f2- | sed 's/^/  /' > "$CACHE_DIR/repos.tmp"
}
fetch_repos &
REPOS_PID=$!

################################################################################
# COMPONENT 5: EMAIL (Summary from ~/.email-summary.sh)
################################################################################
# Source: ~/.email-summary.sh (custom script)
# TTL: None (runs fresh each time, manages own caching)
# Fallback: Empty section if script missing or fails
#
[ -x "$HOME/.email-summary.sh" ] && "$HOME/.email-summary.sh" > "$CACHE_DIR/email.tmp" 2>/dev/null &
EMAIL_PID=$!

################################################################################
# DISPLAY SECTION: Show all fetched/cached data
################################################################################

# Wait all background jobs with global timeout (5s max)
# This prevents hanging if a job crashes silently
timeout 5 wait $STATS_PID $TASKS_PID $CALENDAR_PID $REPOS_PID $EMAIL_PID 2>/dev/null || true

# Display stats (if available)
[ -s "$CACHE_DIR/stats.tmp" ] && echo -e "\033[38;5;95m$(cat "$CACHE_DIR/stats.tmp")\033[0m" && echo ""

# Display daily I Ching hexagram (always visible, fast)
if type get_daily_hexagram >/dev/null 2>&1; then
  HEX=$(get_daily_hexagram)
  HEX_NAME=$(get_daily_hexagram_name)
  WISDOM=$(get_daily_hexagram_wisdom)
  echo -e "\033[38;5;204m$HEX $HEX_NAME\033[0m"
  echo -e "  \033[2m$WISDOM\033[0m"
  echo ""
fi

# Helper function to display sections with spacing
show_section() {
  local file="$1"
  local title="$2"

  [ -s "$file" ] || return 0  # Skip if file is empty

  [ $SHOWN -eq 1 ] && echo ""  # Add spacing before section if one already shown
  echo -e "\033[38;5;204m$title\033[0m"
  cat "$file"
  SHOWN=1
}

SHOWN=0

# Display components in order (all jobs already waited for above)
show_section "$CACHE_DIR/tasks.tmp" "FOCUS"
show_section "$CACHE_DIR/calendar.tmp" "SCHEDULE"
show_section "$CACHE_DIR/repos.tmp" "ACTIVE REPOS"
show_section "$CACHE_DIR/email.tmp" "INBOX"

################################################################################
# COMPONENT 6: I CHING POETRY (Context-rich mystical insights)
################################################################################
# Source: LLM generating I Ching-style poetry from all available context
# LLM: claude 4o-mini with 150 token max for poetic generation
# TTL: 30 minutes
# Fallback: Skipped if offline or LLM unavailable
# Note: Only runs if online and at least one section was shown
#
if [ $ONLINE -eq 0 ] && command -v /opt/homebrew/bin/llm >/dev/null 2>&1; then
  # Get hexagram for display (outside subshell)
  ORACLE_HEX=$(get_daily_hexagram 2>/dev/null || echo "䷀")

  # Use cached insights if fresh, otherwise regenerate
  if ! cache_fresh "$CACHE_DIR/insights.tmp" $CACHE_INSIGHTS; then
    (
      # Gather MAXIMUM context for poetry generation
      HEX_SYMBOL=$(get_daily_hexagram 2>/dev/null || echo "䷀")
      HEX_TITLE=$(get_daily_hexagram_name 2>/dev/null || echo "Creative")
      HEX_WISDOM=$(get_daily_hexagram_wisdom 2>/dev/null || echo "Flow")
      MOON=$(get_moon_name 2>/dev/null || echo "waxing")
      TIME_NOW=$(date '+%A %I:%M %p')
      HOUR=$(date +%H)
      SEASON=$(date '+%B')

      # Git context (commits, branches, activity)
      GIT_RECENT=$(timeout 0.5 git log -3 --pretty="%s" 2>/dev/null | head -3 | tr '\n' '; ' || echo "none")
      GIT_BRANCH=$(timeout 0.5 git branch --show-current 2>/dev/null || echo "none")
      GIT_STATS=$(timeout 0.5 git log --since="24 hours ago" --oneline 2>/dev/null | wc -l | tr -d ' ')

      # Tasks context
      TASK_COUNT=$(things-cli today 2>/dev/null | wc -l | tr -d ' ')
      NEXT_TASK=$(things-cli today 2>/dev/null | head -1 | sed 's/^- //' || echo "none")

      # Calendar context
      NEXT_EVENT=$(icalBuddy -n -nc -iep "title" -po "title" -df "" eventsToday+1 2>/dev/null | head -1 | sed 's/^[•-] //' || echo "none")
      WEEKEND_DIST=$(( (6 - $(date +%u)) ))

      # System context
      UPTIME=$(uptime | sed 's/.*up //;s/, [0-9]* user.*//')
      CURRENT_DIR=$(basename "$(pwd)")
      RECENT_CMDS=$(tail -15 ~/.zsh_history 2>/dev/null | cut -d';' -f2 | tail -5 | tr '\n' '; ')

      # Active repos
      ACTIVE_REPOS=$(cat "$CACHE_DIR/repos.tmp" 2>/dev/null | head -3 | tr '\n' ', ' | sed 's/, $//')

      # Recent emails (fetch 5 most recent from inbox)
      RECENT_EMAILS=""
      if command -v mu >/dev/null 2>&1; then
        # Using mu (maildir indexer)
        RECENT_EMAILS=$(timeout 1.0 mu find maildir:/INBOX --fields="f s" --sortfield=date --reverse --maxnum=5 2>/dev/null | sed 's/^/    /' || echo "none")
      elif command -v notmuch >/dev/null 2>&1; then
        # Using notmuch
        RECENT_EMAILS=$(timeout 1.0 notmuch search --output=summary --limit=5 tag:inbox 2>/dev/null | sed 's/^/    /' || echo "none")
      elif [ -f "$HOME/.maildir/INBOX/new" ] || [ -f "$HOME/Maildir/INBOX/new" ]; then
        # Raw maildir parsing (last resort)
        RECENT_EMAILS=$(find ~/Maildir/INBOX/new ~/Maildir/INBOX/cur -type f -exec grep -m1 "^Subject:" {} \; 2>/dev/null | head -5 | sed 's/^Subject: /    /' || echo "none")
      else
        # Fallback: use cached email summary
        RECENT_EMAILS=$(cat "$CACHE_DIR/email.tmp" 2>/dev/null | head -5 | sed 's/^/    /' || echo "none")
      fi

      prompt="You are an I Ching oracle. Generate mystical poetry weaving actual data into ancient wisdom.

HEXAGRAM: $HEX_SYMBOL $HEX_TITLE - $HEX_WISDOM
TIME: $TIME_NOW, $SEASON, moon phase: $MOON
GIT: $GIT_STATS commits today on branch '$GIT_BRANCH'
RECENT COMMITS: $GIT_RECENT
TASKS: $TASK_COUNT tasks await, beginning with: $NEXT_TASK
CALENDAR: $NEXT_EVENT ($WEEKEND_DIST days until weekend)
WORKSPACE: $CURRENT_DIR directory, system uptime $UPTIME
ACTIVE: $ACTIVE_REPOS
INBOX (5 recent):
$RECENT_EMAILS

Generate 2-4 lines of I Ching poetry. Weave in specific details:
- Numbers: $GIT_STATS commits, $TASK_COUNT tasks, $WEEKEND_DIST days
- Names: branch '$GIT_BRANCH', repos like 'website2', next task, email senders/subjects
- Timing: $TIME_NOW, moon '$MOON', $SEASON
- Inbox: weave in email subjects or sender names if evocative (Supabase alerts, Apple notices, etc)

Good examples:
  $GIT_STATS commits flow like water through $GIT_BRANCH
  $TASK_COUNT tasks linger as stars, beginning with meditation
  website2 and scrapbook-core call from the digital realm
  Supabase whispers urgent warnings, Apple's gatekeeper beckons
  $WEEKEND_DIST days until rest, moon waxes toward fullness

DO NOT use quotation marks. Be poetic yet concrete. Reference real data (commit messages, task names, email subjects). Each line starts with two spaces."

      # Generate I Ching poetry via LLM (6s timeout for complex prompt)
      # Use temp file to avoid partial writes if timeout kills process
      tmp_insights="$CACHE_DIR/insights.tmp.$$"
      if echo "$prompt" | timeout 6.0 /opt/homebrew/bin/llm -m 4o-mini -o max_tokens 200 --no-log 2>&1 > "$tmp_insights"; then
        # Success: move temp file to actual cache
        mv "$tmp_insights" "$CACHE_DIR/insights.tmp"
      else
        # Timeout (124) or other error: remove partial output
        rm -f "$tmp_insights"
        # If we have old cache, keep it; otherwise create empty file
        [ ! -f "$CACHE_DIR/insights.tmp" ] && touch "$CACHE_DIR/insights.tmp"
      fi
    )
  fi

  # Display if insights available and at least one section shown
  [ -s "$CACHE_DIR/insights.tmp" ] && [ $SHOWN -eq 1 ] && \
    echo "" && echo -e "\033[38;5;204m$ORACLE_HEX ORACLE\033[0m" && cat "$CACHE_DIR/insights.tmp"
fi

# Footer separator
echo ""
echo -e "\033[38;5;131m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""