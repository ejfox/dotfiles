#!/bin/bash
# Tmux mystical status - outputs symbols for tmux status bar
source "$HOME/.dotfiles/lib/mystical-symbols.sh"

case "$1" in
  moon)
    get_moon_icon
    ;;
  hexagram)
    get_daily_hexagram
    ;;
  time-icon)
    get_time_of_day_icon
    ;;
  planet)
    get_planetary_hour
    ;;
  full)
    echo "$(get_moon_icon) $(get_daily_hexagram)"
    ;;
  *)
    get_moon_icon
    ;;
esac
