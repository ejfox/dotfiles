#!/bin/bash
################################################################################
# ~/.tweakcc-apply.sh - Auto-apply Claude Code theme customizations
################################################################################
# PURPOSE:
#   Automatically applies saved tweakcc customizations to Claude Code on startup
#   Ensures your custom theme persists after Claude Code updates
#   Auto-switches theme based on OS light/dark mode if configured
#
# SETUP REQUIRED:
#   1. Run `npx tweakcc` once to create your custom themes interactively
#   2. Configure your vulpes colors in the UI
#   3. Set lightModeThemeId and darkModeThemeId in ~/.tweakcc/config.json
#   4. This script will then auto-apply on every shell startup
#
# FEATURES:
#   - Silent operation (no output unless error)
#   - Fast exit if config doesn't exist yet
#   - Auto light/dark theme switching based on OS appearance
#   - Graceful handling of tweakcc updates
#
################################################################################

# Check if tweakcc config exists
TWEAKCC_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tweakcc"
[ ! -d "$TWEAKCC_DIR" ] && TWEAKCC_DIR="$HOME/.tweakcc"

# Exit silently if no config (user hasn't run tweakcc yet)
[ ! -d "$TWEAKCC_DIR" ] && exit 0

# Apply saved customizations silently with auto-theme switching
npx tweakcc --apply --auto-theme &>/dev/null &
