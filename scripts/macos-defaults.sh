#!/usr/bin/env bash
# macOS defaults — run once on new machines or after a reset
# Usage: bash ~/.dotfiles/scripts/macos-defaults.sh

set -euo pipefail

echo "Applying macOS defaults..."

# ── Screenshots ──────────────────────────────────────────────────────────────
mkdir -p ~/screenshots
defaults write com.apple.screencapture location -string "$HOME/screenshots"
defaults write com.apple.screencapture style -string "selection"    # default to selection mode
defaults write com.apple.screencapture showsClicks -bool true       # show clicks in recordings
defaults write com.apple.screencapture target -string "file"

echo "Done. Some changes may require: killall SystemUIServer"
