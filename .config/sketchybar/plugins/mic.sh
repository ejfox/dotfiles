#!/bin/bash
IV=$(/usr/bin/osascript -e 'input volume of (get volume settings)' 2>/dev/null)
if [ -n "$IV" ] && [ "$IV" -gt 0 ]; then
  /opt/homebrew/bin/sketchybar --set $NAME drawing=on icon="MIC ON" icon.color=0xffe60067
else
  /opt/homebrew/bin/sketchybar --set $NAME drawing=off
fi
