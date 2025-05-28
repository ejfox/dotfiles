#!/bin/bash
# ~/.startup.sh - EJ Fox's terminal startup with personalized MOTD

# Skip in zen mode
if [ -f "/tmp/.zen-mode-state" ]; then
  exit 0
fi

OBSIDIAN_ROOT="${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
LLM_PATH="/opt/homebrew/bin/llm"
CACHE_DIR="/tmp/startup_cache"
REFLECTION_CACHE="$CACHE_DIR/reflection_cache.txt"

PERSONA_FILE="$HOME/.dotfiles/.llm-persona.txt"
# Create cache dir if it doesn't exist
mkdir -p "$CACHE_DIR" 2>/dev/null

# Update reflection cache if it doesn't exist or is older than 4 hours
if [[ ! -f "$REFLECTION_CACHE" || $(find "$REFLECTION_CACHE" -mmin +20 2>/dev/null) ]]; then
  today_tasks=$(things-cli today | head -n 3)
  cmd_history=$(tail -n 24 ~/.zsh_history | cut -d ';' -f 2-)
  latest_mastodon_posts=$(curl https://mastodon-posts.ejfox.tools)

  reflection_prompt="$(cat $PERSONA_FILE) 

Working Directory: $(pwd)
Today's Tasks: $today_tasks
Terminal History: $cmd_history
Latest Mastodon Posts: $latest_mastodon_posts
Current Time: $(date)"

  echo "$reflection_prompt" | "$LLM_PATH" -m anthropic/claude-sonnet-4-0 -o max_tokens 164 >"$REFLECTION_CACHE"
fi

# Show today's tasks
echo -e "\n[TODAY'S MISSION]"
things-cli today | head -n 3

# Show recently accessed repos
echo -e "\n[RECENTLY ACCESSED]"
find ~/code -maxdepth 1 -type d -exec test -d "{}/.git" \; -print |
  xargs -I{} bash -c 'printf "%s\t%s\n" "$(stat -f "%m" "{}")" "⌥ $(basename "{}")"' |
  sort -rn | head -n 3 | cut -f2-

# Show recent notes
find "${OBSIDIAN_ROOT}" -type f -mtime -1 -not -path '*/\.*' -print |
  awk -v r="${OBSIDIAN_ROOT}/" '{sub(r, ""); printf "※ %s\n", $0}' |
  head -n 3

# Show sunset info
# echo -e "\n[🌇$(curl -s --max-time 2 "wttr.in/NYC?format=%s")]"

# Show cached reflection
echo -e "\n[REFLECTION]"
cat "$REFLECTION_CACHE"

echo -e "\n[SYSTEM READY]"

