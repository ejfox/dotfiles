#!/bin/bash
# Simple zen mode toggle

ZEN_STATE="/tmp/.zen-mode-state"

if [ -f "$ZEN_STATE" ]; then
  # EXIT ZEN MODE
  rm -f "$ZEN_STATE"
  
  # Show tmux status
  tmux set -g status on 2>/dev/null

  # Show sketchybar (it's plist-loaded, not brew-services-managed)
  sketchybar --bar hidden=off 2>/dev/null

  echo "◯ normal"
else
  # ENTER ZEN MODE
  touch "$ZEN_STATE"
  
  # Hide tmux status
  tmux set -g status off 2>/dev/null

  # Hide sketchybar (it's plist-loaded, not brew-services-managed)
  sketchybar --bar hidden=on 2>/dev/null

  echo "◆ zen"
fi