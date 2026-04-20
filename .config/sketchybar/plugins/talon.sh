#!/bin/bash
# Talon state indicator — driven by talon_state events from sketchybar_bridge.py.
# $MODE is set by the bridge: sleep | command | dictation | mixed | other
# Colors mirror ~/.talon/user/ejfox-overrides/mode_line.py so the bar + mode-line agree.

case "${MODE:-other}" in
  sleep)
    # Sleeping — hide. No noise when Talon isn't listening.
    sketchybar --set "$NAME" drawing=off
    ;;
  command)
    sketchybar --set "$NAME" \
      drawing=on \
      icon="TALON" \
      icon.color=0xffe60067
    ;;
  dictation)
    sketchybar --set "$NAME" \
      drawing=on \
      icon="DICT" \
      icon.color=0xff6eedf7
    ;;
  mixed)
    sketchybar --set "$NAME" \
      drawing=on \
      icon="MIX" \
      icon.color=0xff6eedf7
    ;;
  *)
    sketchybar --set "$NAME" drawing=off
    ;;
esac
