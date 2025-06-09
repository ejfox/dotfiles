#!/bin/bash

# CIPHER - AI companion for hacker-journalists
# Generates contextual wisdom every ~15 minutes

# Set the item name
NAME="cipher"

CACHE_FILE="/tmp/cipher_message"
CACHE_TIMEOUT=900 # 15 minutes
PERSONA_FILE="$HOME/.dotfiles/.llm-persona.txt"

# Check if we should generate a new message based on actual context changes
should_generate_message() {
  # Generate if cache is missing
  if [ ! -f "$CACHE_FILE" ]; then
    return 0
  fi

  # Or if cache is old (still keep timeout as fallback)
  local cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE")))
  if [ "$cache_age" -gt "$CACHE_TIMEOUT" ]; then
    return 0
  fi

  # TODO: Add context change detection here
  # - Git state changes
  # - Semantic state transitions
  # - Command pattern shifts

  return 1
}

# Enhanced semantic context gathering for I Ching wisdom
gather_context() {
  local context=""
  local semantic_state=""

  # === CREATIVE STATE ANALYSIS ===
  local hour=$(date +%H)
  local day=$(date +%A)
  
  # Energy/flow state based on time patterns
  if [ "$hour" -lt 6 ]; then
    semantic_state="liminal-deep"
    context+="Energy: Night owl in liminal space, deep work possible\n"
  elif [ "$hour" -lt 10 ]; then
    semantic_state="morning-clarity"
    context+="Energy: Morning clarity, fresh perspective available\n"
  elif [ "$hour" -lt 14 ]; then
    semantic_state="peak-focus"
    context+="Energy: Peak focus hours, maximum creative potential\n"
  elif [ "$hour" -lt 18 ]; then
    semantic_state="afternoon-flow"
    context+="Energy: Afternoon momentum, steady progress mode\n"
  else
    semantic_state="evening-reflection"
    context+="Energy: Evening reflection, synthesis and completion\n"
  fi

  # === PROJECT SEMANTIC ANALYSIS ===
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local repo=$(basename "$(git rev-parse --show-toplevel)")
    local status_files=$(git status --porcelain | wc -l | tr -d ' ')
    local branch=$(git branch --show-current 2>/dev/null)
    
    # Analyze recent commit themes for creative patterns
    local recent_commit_themes=""
    if git log --oneline -5 &>/dev/null; then
      recent_commit_themes=$(git log --oneline -5 | grep -oE '\b(feat|fix|refactor|docs|style|test|chore)\b' | sort | uniq -c | sort -nr | head -2 | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    fi
    
    # Determine creative phase from git state
    if [ "$status_files" -gt 10 ]; then
      context+="Project: $repo - Chaos phase, many changes in motion ($branch)\n"
    elif [ "$status_files" -gt 3 ]; then
      context+="Project: $repo - Active development, creative flow ($branch)\n"
    elif [ "$status_files" -gt 0 ]; then
      context+="Project: $repo - Focused refinement, polishing details ($branch)\n"
    else
      context+="Project: $repo - Clean state, planning or completion phase ($branch)\n"
    fi
    
    if [ -n "$recent_commit_themes" ]; then
      context+="Recent work patterns: $recent_commit_themes\n"
    fi
  else
    context+="Location: Non-git directory - exploration or personal work\n"
  fi

  # === SEMANTIC COMMAND ANALYSIS ===
  # Analyze recent commands for creative patterns, not just noise
  local command_themes=""
  if [ -f ~/.zsh_history ]; then
    command_themes=$(tail -n 50 ~/.zsh_history | cut -d ';' -f 2- | grep -oE '\b(nvim|code|git|npm|yarn|cargo|python|node|docker|ssh|cd)\b' | sort | uniq -c | sort -nr | head -3 | awk '$1 > 2 {print $2}' | tr '\n' ',' | sed 's/,$//')
  fi
  
  if [[ "$command_themes" == *"nvim"* || "$command_themes" == *"code"* ]]; then
    context+="Mode: Deep editing session, in the flow\n"
  elif [[ "$command_themes" == *"git"* ]]; then
    context+="Mode: Version control focus, organizing thoughts\n"
  elif [[ "$command_themes" == *"npm"* || "$command_themes" == *"yarn"* ]]; then
    context+="Mode: Dependency management, foundation building\n"
  else
    context+="Mode: Mixed activities, exploring possibilities\n"
  fi

  # === SYSTEM ENERGY STATE ===
  local battery=$(pmset -g batt | grep -o '[0-9]*%' | head -1 | tr -d '%')
  if [ "$battery" -lt 20 ]; then
    context+="System: Low battery - urgency and focus needed\n"
  elif [ "$battery" -lt 50 ]; then
    context+="System: Mid battery - steady work mode\n"
  else
    context+="System: High battery - full creative potential available\n"
  fi

  # === CREATIVE MOMENTUM INDICATOR ===
  local process_count=$(ps aux | grep -E "(nvim|code|node|python)" | grep -v grep | wc -l | tr -d ' ')
  if [ "$process_count" -gt 3 ]; then
    context+="Momentum: High - multiple creative tools active\n"
  elif [ "$process_count" -gt 0 ]; then
    context+="Momentum: Engaged - focused work in progress\n"
  else
    context+="Momentum: Contemplative - planning or reflection phase\n"
  fi

  # === SHARED STARTUP CACHE DATA ===
  local startup_cache="/tmp/startup_cache"
  
  # Use startup.sh reflection cache for rich context
  if [ -f "$startup_cache/reflection_cache.txt" ]; then
    local reflection_preview=$(head -n 2 "$startup_cache/reflection_cache.txt" | tr '\n' ' ')
    if [ ${#reflection_preview} -gt 10 ]; then
      context+="Recent insight: ${reflection_preview:0:80}...\n"
    fi
  fi
  
  # Extract today's tasks from Things CLI (if startup ran recently)
  if command -v things-cli &>/dev/null; then
    local today_tasks=$(things-cli today 2>/dev/null | head -n 2 | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$today_tasks" ]; then
      context+="Today's focus: $today_tasks\n"
    fi
  fi
  
  # Get calendar context if available
  if command -v icalBuddy &>/dev/null; then
    local next_event=$(icalBuddy -f -nc -n eventsToday 2>/dev/null | head -n 1)
    if [ -n "$next_event" ]; then
      context+="Schedule: $next_event\n"
    fi
  fi

  echo -e "$context"
}

# Generate I Ching-style wisdom message
generate_message() {
  local context=$(gather_context)
  local persona=$(cat "$PERSONA_FILE" 2>/dev/null || echo "You are CIPHER, an I Ching-influenced AI wisdom companion.")

  # Detached I Ching observer - ancient wisdom meets modern patterns  
  local prompt="$context

You are an ancient I Ching oracle observing modern human work patterns with detached wisdom. Make a dry observation about their current reality in 3-6 words, using subtle I Ching concepts (cycles, hexagrams, change, flow, stagnation). Examples:
- 'same function enters endless loop'
- 'git commits accumulate like sediment'  
- 'focus scatters in forty directions'
- 'creative force meets tired flesh'
- 'order emerges from chaotic branches'
- 'energy drains while mind persists'

Blend ancient perspective with honest modern observation. Reflect patterns, not prescriptions."

  local message
  # Try LLM with increased token limit for I Ching wisdom
  if command -v /opt/homebrew/bin/llm &>/dev/null; then
    message=$(echo "$prompt" | /opt/homebrew/bin/llm -m gpt-4o-mini -o max_tokens 25 2>/dev/null)
    # Clean up message
    message=$(echo "$message" | tr -d '"' | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  fi

  # Show nothing if AI fails - silence is wisdom
  if [ -z "$message" ] || [ ${#message} -lt 5 ] || [ ${#message} -gt 35 ]; then
    message=""
  fi

  echo "$message" >"$CACHE_FILE"
  echo "$message"
}

# Enhanced typewriter effect for I Ching wisdom
typewriter_effect() {
  local message="$1"
  local base_delay=0.12 # Slower, more contemplative
  
  # Adaptive font sizing for artistic impact
  local font_size="13.0"
  if [ ${#message} -gt 30 ]; then
    font_size="11.0"
  elif [ ${#message} -lt 20 ]; then
    font_size="14.0"
  fi

  # Set contemplative styling
  sketchybar --set $NAME \
    label.font="Monaspace Xenon:Italic:$font_size" \
    label="" \
    drawing=on

  # Slow reveal with wisdom-appropriate timing
  for ((i = 0; i < ${#message}; i++)); do
    local char="${message:$i:1}"
    local partial="${message:0:$((i + 1))}"
    
    # Pause longer after spaces for natural rhythm
    local delay="$base_delay"
    if [[ "$char" == " " ]]; then
      delay=$(echo "$base_delay * 2.5" | bc)
    elif [[ "$char" == "." ]] || [[ "$char" == ";" ]] || [[ "$char" == ":" ]]; then
      delay=$(echo "$base_delay * 3" | bc)
    fi
    
    sketchybar --set $NAME label="$partial"
    sleep "$delay"
  done

  # Final pause for contemplation
  sleep 1
}

# Show or hide message (only if sketchybar is available)
if command -v sketchybar >/dev/null 2>&1; then
  # Kill any existing typewriter processes to prevent chaos
  pkill -f "typewriter_effect" 2>/dev/null || true
  
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
    sketchybar --set cipher drawing=off
  fi
fi
