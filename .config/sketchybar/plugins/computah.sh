#!/bin/bash
# computah — menu-bar cockpit for the Windows muscle-machine.
# Renders instantly from ~/.cache/computah/status (written by `computah-probe`);
# never blocks the bar on SSH. Icon = the PC, color/label = its state.
#   moon  (dim)   → asleep/off       · click wakes it
#   tower (muted) → up & idle        · click shows full vitals
#   tower (amber) → busy (GPU job)   · label shows GPU%
PROBE="$HOME/.dotfiles/bin/computah-probe"
CACHE="$HOME/.cache/computah/status"
LOCK="/tmp/computah-probe.lockdir"

# read cache into vars (key=val)
state="down"; via="-"; cpu="?"; gpu="?"; disk="?"; busy="0"
deskflow="?"; llm="?"; preview="?"; vban="?"; komo="?"; vm="?"; host=""
[ -f "$CACHE" ] && while IFS='=' read -r k v; do
  case "$k" in state)state=$v;;via)via=$v;;host)host=$v;;cpu)cpu=$v;;gpu)gpu=$v;;disk)disk=$v;;
    busy)busy=$v;;komo)komo=$v;;vm)vm=$v;;deskflow)deskflow=$v;;llm)llm=$v;;preview)preview=$v;;vban)vban=$v;; esac
done < "$CACHE"

# ---- click: wake if asleep, else show full vitals ----
if [ "$SENDER" = "mouse.clicked" ]; then
  if [ "$state" = "down" ]; then
    osascript -e 'display notification "sending wake-on-LAN…" with title "computah" subtitle "waking"' >/dev/null 2>&1
    ( "$HOME/.dotfiles/bin/computah" wake >/dev/null 2>&1 ) &
  else
    gpud=$([ "$gpu" = "-1" ] && echo "n/a" || echo "${gpu}%")
    body="CPU ${cpu}% · GPU ${gpud} · ${disk}GB free"
    line2="deskflow:${deskflow}  vban:${vban}  llm:${llm}  komorebi:$([ "$komo" = True ] && echo on || echo off)"
    osascript -e "display notification \"$body
$line2\" with title \"computah — $state ($via)\"" >/dev/null 2>&1
  fi
  exit 0
fi

# ---- render from cache ----
case "$state" in
  down)  ICON="󰤄"; ICOLOR="0xff555555"; LABEL=""; LCOLOR="0xff555555" ;;   # moon, dim
  busy)  ICON="󰢹"; ICOLOR="0xffe6c36a"                                    # tower, amber
         if [ "$gpu" != "?" ] && [ "$gpu" != "-1" ] && [ "$gpu" -gt 0 ] 2>/dev/null; then LABEL="${gpu}%"; else LABEL="●"; fi
         LCOLOR="0xffe6c36a" ;;
  *)     ICON="󰢹"; ICOLOR="0xff888888"; LABEL=""; LCOLOR="0xff888888" ;;   # tower, muted (idle)
esac

if [ -n "$LABEL" ]; then
  sketchybar --set "$NAME" icon="$ICON" icon.color="$ICOLOR" label="$LABEL" label.color="$LCOLOR" label.drawing=on
else
  sketchybar --set "$NAME" icon="$ICON" icon.color="$ICOLOR" label.drawing=off
fi

# ---- kick a background refresh (mkdir lock; clear stale >90s) ----
if [ -d "$LOCK" ]; then
  # remove a stale lock left by a killed probe
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +1.5 2>/dev/null)" ]; then rmdir "$LOCK" 2>/dev/null; fi
fi
if mkdir "$LOCK" 2>/dev/null; then
  ( "$PROBE"; rmdir "$LOCK" 2>/dev/null ) >/dev/null 2>&1 &
fi
