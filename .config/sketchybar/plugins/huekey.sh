#!/bin/bash
# huekey — toggle keyboard-reactive desk lights (Hammerspoon hueKeyTap)
# Click to flip the tap on/off; icon color reflects state.

HS="/opt/homebrew/bin/hs"

get_state() {
  [ -x "$HS" ] || { echo "off"; return; }
  s=$("$HS" -c "return tostring(hueKeyTap and hueKeyTap:isEnabled() or false)" 2>/dev/null | tail -1)
  [ "$s" = "true" ] && echo "on" || echo "off"
}

# On click: toggle tap + clear any in-flight pulses on OFF so lights go dark immediately
if [ "$SENDER" = "mouse.clicked" ]; then
  if [ "$(get_state)" = "on" ]; then
    "$HS" -c "hueKeyTap:stop()" >/dev/null 2>&1
    echo '{"type":"clear"}' | nc -u -w0 127.0.0.1 9999
  else
    "$HS" -c "hueKeyTap:start()" >/dev/null 2>&1
  fi
fi

# Render
if [ "$(get_state)" = "on" ]; then
  sketchybar --set "$NAME" icon="󰛨" icon.color=0xffe60067
else
  sketchybar --set "$NAME" icon="󰌵" icon.color=0xff666666
fi
