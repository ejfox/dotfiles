#!/bin/bash
# ~/.startup.sh - EJ Fox's terminal startup with personalized MOTD

# Skip in zen mode
if [ -f "/tmp/.zen-mode-state" ]; then
  exit 0
fi

OBSIDIAN_ROOT="${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
LLM_PATH="/Users/ejfox/.local/bin/llm"
CACHE_DIR="/tmp/startup_cache"
REFLECTION_CACHE="$CACHE_DIR/reflection_cache.txt"
PERSONA_FILE="$HOME/.dotfiles/.llm-persona.txt"

# Geometric symbols matching your aesthetic
SYMBOL_TASK="◆"
SYMBOL_REPO="◇"
SYMBOL_NOTE="○"
SYMBOL_INSIGHT="▪"

# Create cache dir if it doesn't exist
mkdir -p "$CACHE_DIR" 2>/dev/null

# Update reflection cache if it doesn't exist or is older than 20 minutes
if [[ ! -f "$REFLECTION_CACHE" || $(find "$REFLECTION_CACHE" -mmin +20 2>/dev/null) ]]; then
  # Gather all context
  today_tasks=$(command -v things-cli >/dev/null && things-cli today | head -n 5 || echo "No tasks available")
  
  # Get calendar events for today using icalBuddy
  calendar_events=""
  if command -v icalBuddy >/dev/null 2>&1; then
    calendar_events=$(icalBuddy -f -nc -iep "datetime,title" -po "datetime,title" -df "%H:%M" -b "" -n eventsToday 2>/dev/null || echo "")
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
    if command -v gh &> /dev/null; then
      pr_count=$(gh pr list --search "review-requested:@me" --json number 2>/dev/null | jq length 2>/dev/null || echo 0)
      if [ "$pr_count" -gt 0 ]; then
        git_context="${git_context}${repo_name} has ${pr_count} PRs needing review. "
      fi
    fi
  done
  cd - >/dev/null 2>&1
  
  cmd_history=$(tail -n 24 ~/.zsh_history | cut -d ';' -f 2-)
  latest_mastodon_posts=$(curl -s --max-time 3 https://mastodon-posts.ejfox.tools)
  historical_tweets=$(curl -s --max-time 3 https://twitter-posts.ejfox.tools/today | cut -c 1-1000)
  
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

  echo "$reflection_prompt" | "$LLM_PATH" -m gpt-4o-mini -o max_tokens 200 >"$REFLECTION_CACHE" 2>/dev/null || echo "AI reflection unavailable" >"$REFLECTION_CACHE"
fi

# Clear screen for clean display
clear

# Header with time context
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1m$(date '+%A, %B %d - %I:%M %p')\033[0m"
echo -e "\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Today's mission with better formatting
if command -v things-cli >/dev/null 2>&1; then
  echo -e "\n\033[1mTODAY'S MISSION\033[0m"
  things-cli today | head -n 3 | while read task; do
    echo -e "  $SYMBOL_TASK $task"
  done
fi

# Calendar events if available
if command -v icalBuddy >/dev/null 2>&1; then
  events=$(icalBuddy -f -nc -iep "datetime,title" -po "datetime,title" -df "%H:%M" -b "" -n eventsToday 2>/dev/null | head -3)
  if [ ! -z "$events" ]; then
    echo -e "\n\033[1mSCHEDULE\033[0m"
    echo "$events" | while read event; do
      echo -e "  $SYMBOL_NOTE $event"
    done
  fi
fi

# Recently accessed with cleaner format
echo -e "\n\033[1mRECENT WORK\033[0m"
find ~/code -maxdepth 1 -type d -exec test -d "{}/.git" \; -print |
  xargs -I{} bash -c 'printf "%s\t%s\n" "$(stat -f "%m" "{}")" "$(basename "{}")"' |
  sort -rn | head -n 3 | cut -f2- | while read repo; do
    echo -e "  $SYMBOL_REPO $repo"
  done

# Recent notes
notes=$(find "${OBSIDIAN_ROOT}" -type f -name "*.md" -mtime -1 -not -path '*/\.*' | head -3)
if [ ! -z "$notes" ]; then
  echo -e "\n\033[1mRECENT NOTES\033[0m"
  echo "$notes" | while read note; do
    note_name=$(basename "$note" .md)
    echo -e "  $SYMBOL_NOTE $note_name"
  done
fi

# AI Insights
echo -e "\n\033[1mINSIGHTS\033[0m"
cat "$REFLECTION_CACHE" | fold -s -w 70 | while read line; do
  echo -e "  $SYMBOL_INSIGHT $line"
done

echo -e "\n\033[2m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1mSYSTEM READY\033[0m\n"