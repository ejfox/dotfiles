#!/bin/bash
# Clock — rightmost system anchor.
# Time-of-day nerd glyph (mystical-symbols.sh) + 12-hour time, e.g. " 1:12pm".
# Styling (13pt PRIMARY, muted grey) lives in sketchybarrc.

source "$HOME/.dotfiles/lib/mystical-symbols.sh"

ICON=$(get_time_of_day_icon)

# 12-hour, leading zero stripped, lowercase am/pm — matches next_event.sh's time language.
TIME=$(date +"%I:%M%p" | sed 's/^0//' | tr '[:upper:]' '[:lower:]')

sketchybar --set "$NAME" icon="$ICON" label="$TIME"
