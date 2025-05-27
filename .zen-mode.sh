#!/bin/bash
# Simple zen mode toggle

ZEN_STATE="/tmp/.zen-mode-state"

if [ -f "$ZEN_STATE" ]; then
  # EXIT ZEN MODE
  rm -f "$ZEN_STATE"
  
  # Show tmux status
  tmux set -g status on 2>/dev/null
  
  # Start sketchybar
  brew services start sketchybar 2>/dev/null
  
  echo "◯ normal"
else
  # ENTER ZEN MODE
  touch "$ZEN_STATE"
  
  # Hide tmux status
  tmux set -g status off 2>/dev/null
  
  # Stop sketchybar
  brew services stop sketchybar 2>/dev/null
  
  echo "◆ zen"
fi