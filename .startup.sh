#!/bin/bash
################################################################################
# ~/.startup.sh - Ultra-fast terminal startup with intelligent caching
################################################################################
# Robust, fault-tolerant MOTD with graceful degradation.
# If anything fails, skip it and keep going.
#
# TIMING: Cold ~4s (5 parallel fetchers, mirror API call) | Warm ~1-2s
################################################################################

# === SAFETY & CONFIG ===
set +e  # Don't exit on error - graceful degradation
exec 2>/dev/null  # Silence all stderr (remove for debugging)

# Skip if zen mode active
[ -f "/tmp/.zen-mode-state" ] && exit 0

# Ctrl-C to skip
trap 'exit 0' INT

# Cache setup
CACHE_DIR="/tmp/startup_cache"
CIPHER_CACHE="$HOME/.cache/cipher"
mkdir -p "$CACHE_DIR" "$CIPHER_CACHE" 2>/dev/null || exit 0

# Validate cache dir is writable
[ -w "$CACHE_DIR" ] || exit 0

# Cache TTLs (minutes)
TTL_STATS=30
TTL_TASKS=15
TTL_CALENDAR=15
TTL_MIRROR=15
TTL_NETWORK=1

# Source optional libs
source "$HOME/.dotfiles/lib/mystical-symbols.sh" 2>/dev/null || true

################################################################################
# UTILITIES
################################################################################

# Check if cache file is fresh (exists, non-empty, within TTL)
cache_ok() {
  local file="$1" ttl="$2"
  [ -f "$file" ] && [ -s "$file" ] && \
    [ -z "$(find "$file" -mmin +"$ttl" 2>/dev/null)" ]
}

# Safe read - returns empty if file missing/unreadable
safe_read() {
  [ -f "$1" ] && [ -r "$1" ] && cat "$1" 2>/dev/null
}

# Safe number extraction - returns 0 if not numeric
safe_num() {
  local val="$1"
  [[ "$val" =~ ^-?[0-9]+\.?[0-9]*$ ]] && echo "$val" || echo "0"
}

# Validate JSON file before reading
json_ok() {
  [ -f "$1" ] && [ -s "$1" ] && jq empty "$1" 2>/dev/null
}

# Safe JSON extraction with default
json_get() {
  local file="$1" path="$2" default="${3:-0}"
  if json_ok "$file"; then
    local val=$(jq -r "$path // empty" "$file" 2>/dev/null)
    [ -n "$val" ] && echo "$val" || echo "$default"
  else
    echo "$default"
  fi
}

# Atomic write - write to tmp then move (prevents partial reads)
atomic_write() {
  local file="$1" content="$2"
  local tmp="${file}.tmp.$$"
  echo "$content" > "$tmp" 2>/dev/null && mv "$tmp" "$file" 2>/dev/null
  rm -f "$tmp" 2>/dev/null
}

# Cleanup stale temp files older than 1 hour
cleanup_stale() {
  find "$CACHE_DIR" -name "*.tmp.*" -mmin +60 -delete 2>/dev/null &
}
cleanup_stale

################################################################################
# HEADER
################################################################################
echo ""
echo -e "\033[38;5;204m$(date '+%A, %B %d')\033[0m \033[2m•\033[0m \033[1m$(date '+%I:%M %p')\033[0m"

################################################################################
# NETWORK CHECK (gates API calls)
################################################################################
if cache_ok "$CACHE_DIR/network" $TTL_NETWORK; then
  ONLINE=$(safe_read "$CACHE_DIR/network")
else
  timeout 1 curl -fsSL -o /dev/null https://1.1.1.1 2>/dev/null && ONLINE=0 || ONLINE=1
  atomic_write "$CACHE_DIR/network" "$ONLINE"
fi
ONLINE=$(safe_num "$ONLINE")

################################################################################
# BACKGROUND FETCHERS (parallel, non-blocking)
################################################################################

fetch_stats() {
  cache_ok "$CACHE_DIR/stats" $TTL_STATS && return 0
  [ "$ONLINE" -eq 0 ] || return 0

  local mt rt stats
  # TODO: ejfox.com/api/monkeytype returns {"typingStats":null} — upstream broken (May 2026)
  mt=$(timeout 2 curl -fsSL https://ejfox.com/api/monkeytype 2>/dev/null | jq -r '.typingStats.bestWPM // empty' 2>/dev/null)
  rt=$(timeout 2 curl -fsSL https://ejfox.com/api/rescuetime 2>/dev/null | jq -r '.week.categories[]? | select(.productivity == 2) | .time.hoursDecimal' 2>/dev/null | awk '{s+=$1} END {printf "%.1fh", s}')

  stats="${mt:+$mt WPM}${mt:+${rt:+ • }}${rt:+$rt productive}"
  [ -n "$stats" ] && atomic_write "$CACHE_DIR/stats" "$stats"
}

fetch_tasks() {
  cache_ok "$CACHE_DIR/tasks" $TTL_TASKS && return 0
  command -v things.sh >/dev/null || return 0

  local tasks=$(things.sh today 2>/dev/null | cut -d'|' -f2 | sed 's/^[^[:alnum:]]*//' | head -3)
  [ -z "$tasks" ] && return 0

  echo "$tasks" | sed 's/^/  /' > "$CACHE_DIR/tasks.tmp.$$" && \
    mv "$CACHE_DIR/tasks.tmp.$$" "$CACHE_DIR/tasks"
}

fetch_calendar() {
  cache_ok "$CACHE_DIR/calendar" $TTL_CALENDAR && return 0
  command -v icalBuddy >/dev/null || return 0

  # icalBuddy emits each event as two lines (time, then indented title).
  # Strip leading whitespace, then `paste -d ' ' - -` collapses pairs into
  # single lines like "13:30 - 14:30 Lunch". Then take top 3 events and indent.
  icalBuddy -f -nc -nrd -npn -n -iep "datetime,title" -po "datetime,title" -tf "%H:%M" -df "" -b "" \
    eventsToday 2>/dev/null | \
    LC_ALL=C sed 's/\x1b\[[0-9;]*m//g' | \
    tr -cd '\11\12\15\40-\176' | \
    grep -v '^[[:space:]]*$' | \
    sed 's/^[[:space:]]*//' | \
    paste -d ' ' - - | \
    awk '!seen[$0]++' | head -3 | \
    sed 's/^/  /' > "$CACHE_DIR/calendar.tmp.$$" && \
    mv "$CACHE_DIR/calendar.tmp.$$" "$CACHE_DIR/calendar"
}


fetch_email() {
  [ -x "$HOME/.email-summary.sh" ] || return 0
  timeout 5 "$HOME/.email-summary.sh" > "$CACHE_DIR/email.tmp.$$" 2>/dev/null && \
    [ -s "$CACHE_DIR/email.tmp.$$" ] && mv "$CACHE_DIR/email.tmp.$$" "$CACHE_DIR/email"
  rm -f "$CACHE_DIR/email.tmp.$$" 2>/dev/null
}

fetch_mirror_data() {
  [ "$ONLINE" -eq 0 ] || return 0

  if ! cache_ok "$CACHE_DIR/rescuetime.json" 30; then
    timeout 3 curl -fsSL https://ejfox.com/api/rescuetime > "$CACHE_DIR/rescuetime.json.tmp.$$" 2>/dev/null && \
      json_ok "$CACHE_DIR/rescuetime.json.tmp.$$" && \
      mv "$CACHE_DIR/rescuetime.json.tmp.$$" "$CACHE_DIR/rescuetime.json"
    rm -f "$CACHE_DIR/rescuetime.json.tmp.$$" 2>/dev/null
  fi

  if ! cache_ok "$CACHE_DIR/github.json" 30; then
    timeout 3 curl -fsSL https://ejfox.com/api/github > "$CACHE_DIR/github.json.tmp.$$" 2>/dev/null && \
      json_ok "$CACHE_DIR/github.json.tmp.$$" && \
      mv "$CACHE_DIR/github.json.tmp.$$" "$CACHE_DIR/github.json"
    rm -f "$CACHE_DIR/github.json.tmp.$$" 2>/dev/null
  fi
}

# Launch all fetchers in parallel
fetch_stats &
fetch_tasks &
fetch_calendar &
fetch_email &
fetch_mirror_data &

# Bounded wait: poll children until done or 5s deadline, then kill stragglers.
# (Plain `timeout 5 wait` is a no-op — `wait` runs in a child shell with no jobs.)
deadline=$(($(date +%s) + 5))
while [ -n "$(jobs -rp)" ]; do
  [ "$(date +%s)" -ge "$deadline" ] && {
    kill $(jobs -rp) 2>/dev/null
    break
  }
  sleep 0.1
done
wait 2>/dev/null || true

################################################################################
# DISPLAY
################################################################################

# Stats
[ -s "$CACHE_DIR/stats" ] && {
  echo -e "\033[38;5;95m$(safe_read "$CACHE_DIR/stats")\033[0m"
  echo ""
}

# Sections helper
SHOWN=0
show_section() {
  local file="$1" title="$2"
  [ -s "$file" ] || return 0
  [ $SHOWN -eq 1 ] && echo ""
  echo -e "\033[38;5;204m$title\033[0m"
  safe_read "$file"
  SHOWN=1
}

show_section "$CACHE_DIR/tasks" "FOCUS"
show_section "$CACHE_DIR/calendar" "SCHEDULE"
show_section "$CACHE_DIR/email" "INBOX"

################################################################################
# MIRROR - Ambient observation (25% chance, always late night)
################################################################################
surface_mirror() {
  local hour=$(date +%H)
  hour=$((10#$hour))

  # Probability: 25% normally, 100% late night
  local chance=4
  [ "$hour" -ge 23 ] || [ "$hour" -lt 5 ] && chance=1
  [ $((RANDOM % chance)) -ne 0 ] && return 0

  # Check cache first
  if cache_ok "$CACHE_DIR/mirror" $TTL_MIRROR; then
    echo -e "\033[38;5;95m(mirror) $(safe_read "$CACHE_DIR/mirror")\033[0m"
    echo ""
    return 0
  fi

  # Need rich context (cipher-daily caches it as a side effect of running).
  # Skip if context is stale — cipher-daily runs daily, so >24h means something
  # failed and the mirror would otherwise riff on yesterday's reality.
  local cipher_context_file="$CIPHER_CACHE/context.txt"
  [ -s "$cipher_context_file" ] || return 0
  local context_age=$(( ($(date +%s) - $(stat -f %m "$cipher_context_file" 2>/dev/null || echo 0)) / 3600 ))
  [ "$context_age" -gt 24 ] && return 0

  # Need API key
  [ -z "$ANTHROPIC_API_KEY" ] && [ -f ~/.env ] && \
    ANTHROPIC_API_KEY=$(grep -m1 'ANTHROPIC_API_KEY' ~/.env 2>/dev/null | cut -d'"' -f2)
  [ -z "$ANTHROPIC_API_KEY" ] && return 0

  local rich_context=$(safe_read "$cipher_context_file")
  local prompt="You are CIPHER, the ambient voice in this terminal. Think Spider Jerusalem with a Unix shell: gonzo, observant, allergic to bullshit, weirdly affectionate toward the human at the keyboard.

The user is a hacker-journalist. Below is a snapshot of his digital life right now. Surface ONE specific weird true observation. 8-12 words. Plain text only (no markdown, no asterisks, no backticks).

The good ones notice something OTHERS would miss — a contradiction, a small pattern, a juxtaposition between two unrelated signals. Specific beats clever. No fortune cookies. No moralizing. No advice. No invented trends.

$rich_context

ONE line. Land it."

  local wisdom=$(timeout 5 curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n --arg p "$prompt" '{model:"claude-haiku-4-5",max_tokens:80,messages:[{role:"user",content:$p}]}')" \
    2>/dev/null | jq -r '.content[0].text // empty' 2>/dev/null | head -1 | sed 's/\*\*//g; s/`//g; s/[[:space:]]*$//')

  [ -n "$wisdom" ] && {
    atomic_write "$CACHE_DIR/mirror" "$wisdom"
    echo -e "\033[38;5;95m(mirror) $wisdom\033[0m"
    echo ""
  }
}
surface_mirror

################################################################################
# CIPHER DAILY - Morning priorities (launchd at 7am, fallback here)
################################################################################
today=$(date +%Y-%m-%d)
cipher_file="$CIPHER_CACHE/daily.txt"
cipher_date="$CIPHER_CACHE/daily.date"

# Generate if missing (laptop was asleep at 7am)
if [ "$(safe_read "$cipher_date")" != "$today" ]; then
  command -v cipher-daily >/dev/null && cipher-daily &>/dev/null &
fi

# Display if available
if [ -s "$cipher_file" ] && [ "$(safe_read "$cipher_date")" = "$today" ]; then
  echo -e "\033[38;5;131m◆ CIPHER\033[0m"
  while IFS= read -r line; do
    [ -n "$line" ] && echo -e "\033[38;5;245m  $line\033[0m"
  done < "$cipher_file"
  echo ""
fi

################################################################################
# TIP
################################################################################
[ -f "$HOME/tips.txt" ] && {
  TIP=$(shuf -n 1 "$HOME/tips.txt" 2>/dev/null)
  [ -n "$TIP" ] && echo -e "\033[38;5;240m TIP: $TIP\033[0m" && echo ""
}

################################################################################
# BACKGROUND SERVICES
################################################################################
# Start appearance watcher if not running
pgrep -qf "appearance-watcher" || { appearance-watcher &>/dev/null & disown; }

echo ""
