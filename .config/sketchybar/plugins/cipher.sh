#!/bin/bash

# CIPHER - AI companion for hacker-journalists
# Generates contextual wisdom every ~15 minutes

# Set the item name
NAME="cipher"

CACHE_FILE="/tmp/cipher_message"
CACHE_TIMEOUT=900 # 15 minutes
PERSONA_FILE="$HOME/.dotfiles/.llm-persona.txt"

# Check if we should generate a new message
should_generate_message() {
  # Force generation for testing - remove this later
  # return 0

  # 20% chance every time we're called
  if [ $((RANDOM % 5)) -eq 0 ]; then
    return 0
  fi

  # Or if cache is old/missing
  if [ ! -f "$CACHE_FILE" ]; then
    return 0
  fi

  local cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE")))
  if [ "$cache_age" -gt "$CACHE_TIMEOUT" ]; then
    return 0
  fi

  return 1
}

# Gather context for the AI
gather_context() {
  local context=""

  # Current directory and recent activity
  context+="Working directory: $(basename "$PWD")\n"

  # Recent git activity
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local repo=$(basename "$(git rev-parse --show-toplevel)")
    local status=$(git status --porcelain | wc -l | tr -d ' ')
    local branch=$(git branch --show-current 2>/dev/null)
    context+="Git repo: $repo (branch: $branch, $status changes)\n"
  fi

  # Time and date context
  local hour=$(date +%H)
  local minute=$(date +%M)
  local day=$(date +%A)
  context+="Time: $day $hour:$minute\n"
  if [ "$hour" -lt 6 ]; then
    context+="Period: Very late night coding session\n"
  elif [ "$hour" -lt 12 ]; then
    context+="Period: Morning productivity\n"
  elif [ "$hour" -lt 18 ]; then
    context+="Period: Afternoon work\n"
  else
    context+="Period: Evening session\n"
  fi

  # Recent commands
  context+="Recent commands: $(tail -n 25 ~/.zsh_history | cut -d ';' -f 2- | tr '\n' ', ')\n"

  # Recent file edits
  if command -v fd &>/dev/null; then
    context+="Recent edits: $(fd -t f -e js -e ts -e py -e sh -e md . | head -3 | xargs ls -t | head -3 | tr '\n' ', ')\n"
  fi

  # System info
  local battery=$(pmset -g batt | grep -o '[0-9]*%' | head -1)
  context+="Battery: $battery\n"

  # Network activity
  local wifi=$(networksetup -getairportnetwork en0 | cut -d ' ' -f 4-)
  context+="Network: $wifi\n"

  # Running processes
  local process_count=$(ps aux | wc -l)
  context+="Running processes: $process_count\n"

  echo -e "$context"
}

# Generate AI message
generate_message() {
  local context=$(gather_context)
  local persona=$(cat "$PERSONA_FILE" 2>/dev/null || echo "You are a helpful AI assistant.")

  local prompt="$persona

Context about the user's current state:
$context

Generate a single brief message (max 35 chars) as CIPHER. Be terse and cryptic. 3-6 words. Think hacker wisdom or coding philosophy. NO symbols or special characters - just words."

  local message
  # Try LLM first, with better error handling
  if command -v /opt/homebrew/bin/llm &>/dev/null; then
    message=$(echo "$prompt" | /opt/homebrew/bin/llm -m gpt-4o-mini -o max_tokens 15 2>/dev/null)
    # Clean up message
    message=$(echo "$message" | tr -d '"' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  fi

  # Fallback messages if AI fails - 3-6 words
  if [ -z "$message" ] || [ ${#message} -lt 5 ] || [ ${#message} -gt 35 ]; then
    local fallbacks=(
      "clean code ships faster"
      "stay focused debug later"
      "ship it break things"
      "debug life one bug"
      "minimal beats maximal always"
      "keep coding stay curious"
      "think deep code deeper"
      "test everything trust nothing"
    )
    message=${fallbacks[$((RANDOM % ${#fallbacks[@]}))]}
  fi

  echo "$message" >"$CACHE_FILE"
  echo "$message"
}

# Typewriter effect function
typewriter_effect() {
  local message="$1"
  local delay=0.08 # Delay between characters (seconds)

  # Set font size based on message length
  local font_size="13.0"
  if [ ${#message} -gt 25 ]; then
    font_size="11.0"
  fi

  # Set the font size and clear the label
  sketchybar --set $NAME label.font="Monaspace Xenon:Italic:$font_size" label="" drawing=on

  # Type out each character
  for ((i = 0; i < ${#message}; i++)); do
    local partial="${message:0:$((i + 1))}"
    sketchybar --set $NAME label="$partial"
    sleep "$delay"
  done

  # Keep message visible permanently (no auto-hide)
  # Message stays until next generation
}

# Show or hide message (only if sketchybar is available)
if command -v sketchybar >/dev/null 2>&1; then
  if should_generate_message; then
    message=$(generate_message)
    # Launch typewriter effect in background
    typewriter_effect "$message" &
  elif [ -f "$CACHE_FILE" ]; then
    # Show cached message with typewriter effect
    message=$(cat "$CACHE_FILE")
    typewriter_effect "$message" &
  else
    # Hide if no message
    sketchybar --set $NAME drawing=off
  fi
fi
