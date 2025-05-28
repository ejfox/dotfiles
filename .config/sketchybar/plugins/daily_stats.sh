#!/bin/bash

# Cache file to prevent excessive API calls
CACHE_FILE="/tmp/sketchybar_stats_cache"
CACHE_TIMEOUT=1800  # 30 minutes in seconds

# Fetch data from API endpoints
fetch_api_data() {
  local endpoint=$1
  local data=$(curl -s "https://ejfox.com/api/$endpoint" 2>/dev/null)
  echo "$data"
}

# Extract various stats from API responses using grep/cut
extract_stats() {
  # Get health data
  local health_data=$(fetch_api_data "health")
  local steps=$(echo "$health_data" | grep -o '"todayStepCount":[0-9]*' | cut -d':' -f2 || echo "0")
  local exercise=$(echo "$health_data" | grep -o '"todayExerciseMinutes":[0-9]*' | cut -d':' -f2 || echo "0")
  
  # Get general stats
  local stats_data=$(fetch_api_data "stats")
  local github_commits=$(echo "$stats_data" | grep -o '"totalCommits":[0-9]*' | cut -d':' -f2 || echo "0")
  local wpm=$(echo "$stats_data" | grep -o '"bestWpm":[0-9.]*' | cut -d':' -f2 || echo "0")
  
  # Get rescuetime data
  local rescuetime_data=$(fetch_api_data "rescuetime")
  local dev_time=$(echo "$rescuetime_data" | grep -o '"Software Development".*"seconds":[0-9]*' | grep -o '"seconds":[0-9]*' | cut -d':' -f2 | head -1 || echo "0")
  dev_time=$((dev_time / 60)) # Convert to minutes
  
  # Things data
  local completed_count=$(things-cli logtoday | wc -l | xargs)
  
  # Return stats in format: steps|exercise|commits|wpm|dev_time|tasks
  echo "$steps|$exercise|$github_commits|$wpm|$dev_time|$completed_count"
}

# Get personalized stat summary from LLM with caching
get_llm_stats_summary() {
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
  
  # Extract stats
  local stats=$(extract_stats)
  local steps=$(echo "$stats" | cut -d'|' -f1)
  local exercise=$(echo "$stats" | cut -d'|' -f2)
  local commits=$(echo "$stats" | cut -d'|' -f3)
  local wpm=$(echo "$stats" | cut -d'|' -f4)
  local dev_time=$(echo "$stats" | cut -d'|' -f5)
  local tasks=$(echo "$stats" | cut -d'|' -f6)
  
  # Build prompt for the LLM
  local prompt="Create a very short, fun video game style status update (max 50 chars) about the user's day. Make it like The Sims or an RTS game status message with character stats. Include symbols like * # +.

Today's stats:
- Tasks completed: $tasks
- Steps: $steps
- Exercise minutes: $exercise
- GitHub commits: $commits
- Coding time: $dev_time minutes
- Typing speed: $wpm WPM

Just return the message, nothing else."
  
  # Call LLM and cache result
  local response
  response=$(/opt/homebrew/Caskroom/miniconda/base/bin/llm -m gpt-4o-mini -o max_tokens 50 "$prompt" 2>/dev/null || echo "")
  
  # Fallback if LLM call fails
  if [ -z "$response" ]; then
    echo "+ Day stats: $tasks tasks, $steps steps, $commits commits"
    return
  fi
  
  # Clean up LLM response (remove quotes, etc)
  response=$(echo "$response" | tr -d '"' | xargs)
  
  # Save to cache
  echo "$response" > "$CACHE_FILE"
  
  # Return the response
  echo "$response"
}

# Get simple stats display if LLM fails
get_simple_stats() {
  local stats=$(extract_stats)
  local steps=$(echo "$stats" | cut -d'|' -f1)
  local tasks=$(echo "$stats" | cut -d'|' -f6)
  local commits=$(echo "$stats" | cut -d'|' -f3)
  
  echo "+ $tasks tasks • $steps steps • $commits commits"
}

# Main function to get stats display
get_stats_display() {
  # 80% chance of LLM, 20% chance of simple stats to preserve API calls
  if [ $((RANDOM % 5)) -eq 0 ]; then
    get_simple_stats
  else
    get_llm_stats_summary
  fi
}

# Set the sketchybar item
sketchybar --set $NAME icon="+" label="$(get_stats_display)"