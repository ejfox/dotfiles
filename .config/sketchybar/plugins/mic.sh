#!/bin/bash
# mic.sh — shows 🔇 only while the real mics are muted (see bin/mic-toggle).
# Driven by the custom `mic_change` event; also runs on system_woke.
HS=$(command -v hs || echo /usr/local/bin/hs)
MUTED=$("$HS" -c 'for _, d in ipairs(hs.audiodevice.allInputDevices()) do
  local n = d:name()
  if (n == "Shure MVX2U" or n == "iMac Pro Microphone" or n == "MacBook Pro Microphone")
     and d:inputMuted() ~= nil then print(d:inputMuted() and "yes" or "no") break end
end' 2>/dev/null)

if [ "$MUTED" = "yes" ]; then
  sketchybar --set "$NAME" drawing=on icon="󰍭" icon.color=0xffff2222
else
  sketchybar --set "$NAME" drawing=off
fi
