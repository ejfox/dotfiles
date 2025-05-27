#!/bin/zsh
# Minimal prompt for zsh - matches tmux/nvim aesthetic

# Git info
git_prompt() {
  # Check if we're in a git repo
  git rev-parse --is-inside-work-tree &>/dev/null || return
  
  # Check for uncommitted changes
  if [[ -n $(git status -s 2>/dev/null) ]]; then
    echo "◆"
  else
    echo "◇"
  fi
}

# Vi mode indicator
vi_mode_prompt() {
  echo "${${KEYMAP/vicmd/◆}/(main|viins)/○}"
}

# Set the prompt
setopt PROMPT_SUBST

# Minimal prompt: just a symbol that changes based on context
PROMPT='$(git_prompt 2>/dev/null || echo "▪") '

# Right prompt: current directory (just the last part)
RPROMPT='%1~'

# Remove all the extra info
unset RPS1
unset PS2
unset PS3
unset PS4