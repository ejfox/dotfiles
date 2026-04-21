#!/bin/bash
# Claude's dev helper for hue-stream + Hammerspoon iteration.
# Usage:  bash ~/.local/share/hue/dev.sh <cmd>
# cmds:   reload | test | test-desk | test-streak <n> | status | kill

set -eu
: "${HUE_BRIDGE_IP:?source ~/.env first}"

case "${1:-}" in
  reload)
    hue-stream trigger quit 2>/dev/null || true
    sleep 1
    pkill -f 'hue-stream\.js' 2>/dev/null || true
    hue-stream stop 2>/dev/null || true   # force bridge out of streaming state
    sleep 5                                # bridge needs ~5s to release DTLS
    nohup hue-stream daemon dark > /tmp/hue-daemon.log 2>&1 &
    disown
    sleep 4
    hs -c "hs.reload()" 2>/dev/null || true
    sleep 1.5
    echo "daemon:       $(tail -1 /tmp/hue-daemon.log)"
    echo "hueKeyTap:    $(hs -c 'return tostring(hueKeyTap and hueKeyTap:isEnabled())' 2>&1 | tail -1)"
    echo "streak span:  $(grep STREAK_SPAN ~/.hammerspoon/init.lua | head -1 | awk '{print $4}')"
    echo "pulse dur:    $(grep PULSE_DURATION ~/.hammerspoon/init.lua | head -1 | awk '{print $4}')"
    ;;
  test)
    echo '{"type":"pulse","position":[0,0,0],"color":[1,1,1],"duration":0.4,"radius":10}' | nc -u -w1 127.0.0.1 9999
    echo "broadcast white pulse fired"
    ;;
  test-desk)
    echo '{"type":"pulse","position":[0,0,0],"color":[0,1,1],"duration":0.6,"radius":10,"target":["desk"]}' | nc -u -w1 127.0.0.1 9999
    echo "desk-only cyan pulse fired"
    ;;
  test-streak)
    n="${2:-40}"
    echo "firing $n rapid targeted pulses simulating streak..."
    for i in $(seq 1 "$n"); do
      # hue progresses 0 → 0.66 over n pulses
      h=$(awk -v i="$i" -v n="$n" 'BEGIN{printf "%.3f", (i-1)/n * 0.66}')
      # crude HSV→RGB: use Python for simplicity
      rgb=$(python3 -c "
import colorsys
r,g,b = colorsys.hsv_to_rgb($h, 1, 1)
print(f'{r:.3f},{g:.3f},{b:.3f}')")
      IFS=',' read -r r g b <<< "$rgb"
      echo "{\"type\":\"pulse\",\"position\":[0,0,0],\"color\":[$r,$g,$b],\"duration\":2.2,\"radius\":10,\"target\":[\"desk\"]}" | nc -u -w0 127.0.0.1 9999
      sleep 0.15
    done
    echo "done"
    ;;
  status)
    echo "daemon:       $(pgrep -lf hue-stream.js 2>/dev/null || echo 'NOT RUNNING')"
    echo "hammerspoon:  $(pgrep -l Hammerspoon 2>/dev/null || echo 'NOT RUNNING')"
    echo "hueKeyTap:    $(hs -c 'return tostring(hueKeyTap and hueKeyTap:isEnabled())' 2>&1 | tail -1)"
    ;;
  kill)
    hue-stream trigger quit 2>/dev/null || true
    sleep 1
    pkill -f 'hue-stream\.js' 2>/dev/null || true
    echo "daemon killed"
    ;;
  *)
    echo "commands: reload | test | test-desk | test-streak [n] | status | kill"
    ;;
esac
