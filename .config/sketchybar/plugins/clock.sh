#!/bin/bash

# Source mystical symbols library
source "$HOME/.dotfiles/lib/mystical-symbols.sh"

# Time with icon
TIME=$(date +"%I:%M")
TIME_ICON=$(get_time_of_day_icon)

# Just time icon + time
sketchybar --set $NAME label="$TIME_ICON $TIME"
