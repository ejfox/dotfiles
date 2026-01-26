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
  [ "$ONLINE" -eq 124 ] 2>/dev/null && ONLINE=1
  echo "$ONLINE" > "$CACHE_DIR/network.tmp"
fi
# Ensure ONLINE is numeric (default to 1/offline if not)
[[ "$ONLINE" =~ ^[0-9]+$ ]] || ONLINE=1

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
  command -v things.sh >/dev/null 2>&1 || return 0  # Skip if no things.sh

  # things.sh format: "Area|Task|url" - extract just task names
  local tasks=$(things.sh today 2>/dev/null | cut -d'|' -f2 | head -5)
  [ -z "$tasks" ] && return 0

  # Try LLM prioritization first (2.0s timeout, using fast 3.5-turbo)
  if command -v /opt/homebrew/bin/llm >/dev/null 2>&1; then
    # Get today's hexagram for context
    local hex=$(get_daily_hexagram 2>/dev/null || echo "䷀")
    local hex_name=$(get_daily_hexagram_name 2>/dev/null || echo "Creative")
    local hex_wisdom=$(get_daily_hexagram_wisdom 2>/dev/null || echo "Flow")

    echo "$tasks" | timeout 2.0 /opt/homebrew/bin/llm -m 3.5 --no-log -s \
      "Let your response be guided by hexagram $hex $hex_name - $hex_wisdom. Prioritize these tasks. Format: 1) most urgent, 2) secondary, 3) tertiary. Remove dates, strip metadata, be ultra-brief." 2>/dev/null | \
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
# LLM INSIGHTS DISABLED FOR SPEED
# The I Ching oracle generation was adding 6+ seconds to startup
# Re-enable if you want the poetic insights (uncomment below)
# To restore, uncomment the entire section above this comment

: <<'DISABLED_LLM_INSIGHTS'
if [ $ONLINE -eq 0 ] && command -v /opt/homebrew/bin/llm >/dev/null 2>&1; then
  # ... old LLM insights code ...
fi
DISABLED_LLM_INSIGHTS

################################################################################
# CIPHER MORNING RITUAL - DISABLED FOR SPEED
################################################################################
# Was adding 5-10s overhead on startup due to osascript calls to Things3
# Run manually when you want: morning-ritual
#
# if command -v morning-ritual &>/dev/null; then
#   timeout 60 morning-ritual 2>/dev/null || true
# fi

################################################################################
# MIRROR - Automatic pattern detection from APIs and local signals
################################################################################
# Philosophy: the system infers your state from data, mirrors it back
# Uses: ejfox.com/api/*, local git, vault activity, season, time
# No manual input. Reads the shape of your life.
#
surface_mirror() {
  local wisdom=""
  local show_chance=4

  # === TIME/SEASON CONTEXT ===
  local now=$(date +%s)
  local month=$(date +%m)
  local hour=$(date +%H)
  local dow=$(date +%u)

  # Ensure numeric (strip leading zeros for arithmetic)
  hour=$((10#$hour))
  dow=$((10#$dow))
  month=$((10#$month))

  local season="spring"
  case $month in
    12|1|2) season="winter" ;;
    3|4|5) season="spring" ;;
    6|7|8) season="summer" ;;
    9|10|11) season="fall" ;;
  esac

  # === API SIGNALS (use cached data from stats fetch) ===
  local productive_week=0
  local productive_month=0
  local distracting_month=0
  local github_contributions=0

  # Read from cache if available (populated by fetch_stats)
  if [ -f "$CACHE_DIR/rescuetime.json" ]; then
    productive_week=$(jq -r '.week.summary.productive.time.hoursDecimal // 0' "$CACHE_DIR/rescuetime.json" 2>/dev/null)
    productive_month=$(jq -r '.month.summary.productive.time.hoursDecimal // 0' "$CACHE_DIR/rescuetime.json" 2>/dev/null)
    distracting_month=$(jq -r '.month.summary.distracting.time.hoursDecimal // 0' "$CACHE_DIR/rescuetime.json" 2>/dev/null)
  fi
  if [ -f "$CACHE_DIR/github.json" ]; then
    github_contributions=$(jq -r '.stats.totalContributions // 0' "$CACHE_DIR/github.json" 2>/dev/null)
  fi

  # Ensure numeric defaults (jq can return empty/null)
  [[ "$productive_week" =~ ^[0-9.]+$ ]] || productive_week=0
  [[ "$productive_month" =~ ^[0-9.]+$ ]] || productive_month=0
  [[ "$distracting_month" =~ ^[0-9.]+$ ]] || distracting_month=0
  [[ "$github_contributions" =~ ^[0-9]+$ ]] || github_contributions=0

  # === LOCAL SIGNALS (fast, no network) ===
  local vault="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
  local vault_active=$(find "$vault" -name "*.md" -type f -mtime -7 2>/dev/null | wc -l | tr -d ' ')
  [[ "$vault_active" =~ ^[0-9]+$ ]] || vault_active=0

  local days_since_publish=999
  local last_blog=$(find "$vault/blog" -name "*.md" -type f -exec stat -f "%m" {} \; 2>/dev/null | sort -rn | head -1)
  [[ "$last_blog" =~ ^[0-9]+$ ]] && days_since_publish=$(( (now - last_blog) / 86400 ))
  [ "$days_since_publish" -lt 0 ] 2>/dev/null && days_since_publish=0

  # === PHASE INFERENCE ===
  # Combine API data + local signals to infer state
  local phase="BUILD"

  # HOLD: low productive hours + high vault activity + long publish gap
  if [ "${productive_week%.*}" -lt 10 ] && [ "$vault_active" -gt 15 ] && [ "$days_since_publish" -gt 21 ]; then
    phase="HOLD"
  # REST: low everything
  elif [ "${productive_week%.*}" -lt 5 ] && [ "$vault_active" -lt 10 ]; then
    phase="REST"
  # SHIP: high productive hours + recent publish
  elif [ "${productive_week%.*}" -gt 25 ] && [ "$days_since_publish" -lt 14 ]; then
    phase="SHIP"
  # BUILD: high productive hours
  elif [ "${productive_week%.*}" -gt 15 ]; then
    phase="BUILD"
  fi

  # Weekend nudge toward REST (unless clearly in HOLD)
  [ "$dow" -ge 6 ] 2>/dev/null && [ "$phase" = "BUILD" ] && phase="REST"

  # === LLM-GENERATED OBSERVATION ===
  # Only run occasionally (1 in 4 chance) and cache result
  local mirror_cache="$CACHE_DIR/mirror_wisdom.txt"
  local show_chance=4

  # Late night = always show
  if [ "$hour" -ge 23 ] 2>/dev/null || [ "$hour" -lt 5 ] 2>/dev/null; then
    show_chance=1
  fi

  # Roll the dice
  [ $((RANDOM % show_chance)) -ne 0 ] && return 0

  # Check cache (15 min TTL)
  if cache_fresh "$mirror_cache" 15 && [ -s "$mirror_cache" ]; then
    wisdom=$(<"$mirror_cache")
  else
    # Load API key if needed
    [ -z "$ANTHROPIC_API_KEY" ] && [ -f ~/.env ] && \
      ANTHROPIC_API_KEY=$(grep ANTHROPIC_API_KEY ~/.env | cut -d'"' -f2)

    if [ -n "$ANTHROPIC_API_KEY" ]; then
      local prompt="Youre a dry, slightly amused observer. Look at this work data and make ONE observation (15-25 words). Reference specific numbers. No poetry, no metaphors, no advice. Just notice something. Data: ${productive_week}h productive this week, ${productive_month}h this month, ${distracting_month}h distracted, ${vault_active} notes modified in vault this week, ${days_since_publish} days since last blog publish, ${github_contributions} github commits this year, ${season}, hour ${hour}."

      wisdom=$(timeout 3 curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{\"model\":\"claude-3-5-haiku-latest\",\"max_tokens\":100,\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}]}" \
        2>/dev/null | jq -r '.content[0].text // empty' 2>/dev/null | tr -d '\n')

      # Cache if we got something
      [ -n "$wisdom" ] && echo "$wisdom" > "$mirror_cache"
    fi
  fi

  # Output
  if [ -n "$wisdom" ]; then
    echo -e "\033[38;5;95m(mirror) $wisdom\033[0m"
    echo ""
  fi
}

# Fetch API data for mirror (runs in background, caches results)
fetch_mirror_data() {
  [ $ONLINE -eq 0 ] || return 0

  # RescueTime (30 min cache)
  if ! cache_fresh "$CACHE_DIR/rescuetime.json" 30; then
    timeout 2.0 curl -fsSL https://ejfox.com/api/rescuetime 2>/dev/null > "$CACHE_DIR/rescuetime.json" &
  fi

  # GitHub (30 min cache)
  if ! cache_fresh "$CACHE_DIR/github.json" 30; then
    timeout 2.0 curl -fsSL https://ejfox.com/api/github 2>/dev/null > "$CACHE_DIR/github.json" &
  fi
}

# Fetch mirror data in background
fetch_mirror_data &

# Run mirror after other displays (data may be cached from previous runs)
surface_mirror

################################################################################
# TIPS - Random shortcut from tips.txt (video game loading screen style)
################################################################################
# Shows a random tip from ~/tips.txt on each terminal session
# Great for learning new shortcuts passively over time
# Disable: comment out the lines below
#
if [ -f "$HOME/tips.txt" ]; then
  TIP=$(shuf -n 1 "$HOME/tips.txt" 2>/dev/null)
  if [ ! -z "$TIP" ]; then
    echo -e "\033[38;5;240m💡 TIP: $TIP\033[0m"
    echo ""
  fi
fi

# Start appearance watcher for btop theme switching (if not already running)
if ! pgrep -f "appearance-watcher" >/dev/null 2>&1; then
  appearance-watcher &>/dev/null &
  disown
fi

# Footer separator
echo ""
echo -e "\033[38;5;131m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""