#!/bin/bash

# Get all tasks from Things
TASKS=$(things-cli today)
TOP_TASK=$(echo "$TASKS" | grep -E '^\s*-\s' | head -n 1 | sed 's/^\s*-\s*//')

# Get tasks completed today count
COMPLETED_COUNT=$(things-cli logtoday | wc -l | xargs)

# Get the last completed task and its time
LAST_TASK=$(things-cli logtoday | head -1 | sed 's/^- //' | sed 's/ ([^)]*)$//')

# We don't need timestamp handling anymore - removed

# Cache file for LLM celebration (prevent excessive API calls)
CACHE_FILE="/tmp/sketchybar_celebration_cache"
CACHE_TIMEOUT=3600  # 1 hour in seconds

# Game-style status updates
CELEBRATIONS=(
  "* Achievement Unlocked: Clear Task Queue ($COMPLETED_COUNT)"
  "+ Productivity +100 • Stress -75 • Freedom +100"
  "# $COMPLETED_COUNT quests completed! Free time unlocked"
  "! Milestone reached: Inbox Zero!"
  ">> All objectives complete • Next mission available"
  "100% Daily Tasks: 100% • Energy restored!"
  "~ Save point reached • $COMPLETED_COUNT tasks archived"
  ">> NOTIFICATION: Your Sim is now in an excellent mood"
  "+ Energy: 100% • Mood: Excellent • Tasks: 0"
  ">> Daily Goal Achieved • Bonus XP Earned: $COMPLETED_COUNT"
  "^ Territory secured • All $COMPLETED_COUNT objectives complete"
  "^ Level Up! • Discipline +10 • Organized +15"
  "# Base fully upgraded • All units deployed"
  ">> Your Sim is feeling: Accomplished ✓ Energized ✓"
  "X Victory! All $COMPLETED_COUNT enemies defeated"
  "* Rare Achievement: Zero Tasks Remaining!"
)

# Get random celebration from array
get_random_celebration() {
  local idx=$((RANDOM % ${#CELEBRATIONS[@]}))
  echo "${CELEBRATIONS[$idx]}"
}

# Get personalized celebration from LLM (with caching to avoid excessive calls)
get_llm_celebration() {
  # Check if cache exists and is recent
  if [ -f "$CACHE_FILE" ]; then
    # Get age of cache file in seconds
    local cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE")))
    
    # Use cache if it's fresh enough
    if [ "$cache_age" -lt "$CACHE_TIMEOUT" ]; then
      cat "$CACHE_FILE"
      return
    fi
  fi
  
  # Get the completed tasks for context (limit to 5)
  local completed_tasks=$(things-cli logtoday | head -5)
  
  # Build prompt for the LLM
  local prompt="Create a very short, fun video game style status update (max 50 chars) about completing all tasks. Make it like The Sims or an RTS game status message, with stats, achievements, or character status. Include symbols like * # +. Reference these completed tasks if relevant: $completed_tasks. Just return the message, nothing else."
  
  # Call LLM and cache result
  local response
  response=$(/opt/homebrew/Caskroom/miniconda/base/bin/llm -m gpt-4o-mini -o max_tokens 50 "$prompt" 2>/dev/null || echo "")
  
  # Fallback to random celebration if LLM call fails
  if [ -z "$response" ]; then
    get_random_celebration
    return
  fi
  
  # Clean up LLM response (remove quotes, etc)
  response=$(echo "$response" | tr -d '"' | xargs)
  
  # Save to cache
  echo "$response" > "$CACHE_FILE"
  
  # Return the response
  echo "$response"
}

# Cache file for celebration message
CELEBRATION_CACHE="/tmp/sketchybar_final_celebration"

if [ -z "$TOP_TASK" ]; then
  # No tasks - celebration time!
  # Check if we already have a cached celebration
  if [ -f "$CELEBRATION_CACHE" ]; then
    # Use the cached celebration
    CELEBRATION=$(cat "$CELEBRATION_CACHE")
  else
    # Generate a new celebration (only once when tasks are first completed)
    if [ $((RANDOM % 5)) -eq 0 ]; then
      CELEBRATION=$(get_llm_celebration)
    else
      CELEBRATION=$(get_random_celebration)
    fi
    # Cache the celebration so it stays consistent
    echo "$CELEBRATION" > "$CELEBRATION_CACHE"
  fi
  
  sketchybar --set $NAME icon="*" label="$CELEBRATION"
else
  # We have tasks - remove the cache so next time tasks are completed we get a fresh celebration
  [ -f "$CELEBRATION_CACHE" ] && rm "$CELEBRATION_CACHE"
  
  # Remove any parentheses and their contents
  TOP_TASK=$(echo "$TOP_TASK" | sed 's/([^)]*)//g' | sed 's/  / /g' | xargs)
  sketchybar --set $NAME icon="" label="$TOP_TASK"
fi