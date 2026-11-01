#!/bin/zsh
# music-cli — polls for TP-7 in MTP mode, auto-pulls when detected.
# Runs from launchd every 10s; uses ioreg (~30ms) instead of system_profiler (~1-2s)
# so the poll is effectively free.
export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/bin:$PATH"
SEEN=/tmp/.music-tp7-seen
LOCK=/tmp/.music-tp7-pulling
LOG="${HOME}/.local/share/music-cli/watcher.log"
JLOG_DIR="${HOME}/.local/share/usage-logs/music"

jlog() {
  local evt="$1"; shift
  local extra=""
  local kv
  for kv in "$@"; do extra+=",\"${kv%%=*}\":\"${kv#*=}\""; done
  mkdir -p "$JLOG_DIR"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"src\":\"music\",\"evt\":\"$evt\"$extra}" \
    >> "$JLOG_DIR/$(date +%F).jsonl"
}

# keep the watcher log bounded (~1MB cap, keep last 256KB)
if [[ -f "$LOG" && $(stat -f%z "$LOG" 2>/dev/null || echo 0) -gt 1048576 ]]; then
  tail -c 262144 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

# Teenage Engineering vendor id = 0x2367 (9063); TP-7 MTP-mode product id = 0x0019 (25).
# ioreg -p IOUSB prints these as decimal. The two greps are independent, so in
# theory another attached device with idProduct 25 could fake "MTP mode" while
# the TP-7 sits in disk mode — accepted: worst case is one harmless NODEV pull
# attempt, and the odds are negligible. (Event-driven launchd IOKit matching
# exists but needs an XPC event-consumer helper to avoid relaunch loops; a
# 17ms ioreg poll every 10s is simpler and effectively free.)
usb_info=$(ioreg -p IOUSB -l 2>/dev/null)

# 2026-10-28: any plug-in syncs, in audio OR MTP mode. tp7-import.sh flips the TP-7 into MTP itself
# over MIDI (no hold-STOP), and it falls back to audio mode on its own afterward.
COOL=/tmp/.music-tp7-last   # epoch when the last import finished
GONE=/tmp/.music-tp7-gone   # consecutive polls with no TP-7 on the bus
TRIES=/tmp/.music-tp7-tries # failed imports this plug-in (retry cap)
SH=/Users/ejfox/.local/share/music-cli
notify() { osascript -e "display notification \"$1\" with title \"TP-7 import\" sound name \"Basso\"" 2>/dev/null; }

# --- daily self-check: runs whether or not the TP-7 is plugged in; silent unless something is broken ---
STAMP="$SH/selftest.stamp"
if [[ "$(cat "$STAMP" 2>/dev/null)" != "$(date +%F)" ]]; then
  date +%F > "$STAMP"
  problems=()
  for c in tp7 sendmidi receivemidi whisper-cli ffmpeg ffprobe; do
    command -v "$c" >/dev/null || problems+=("missing $c")
  done
  [[ -x "$HOME/.dotfiles/bin/music" ]] || problems+=("missing ~/.dotfiles/bin/music")
  [[ -f "$SH/models/ggml-base.en.bin" ]] || problems+=("missing whisper model")
  for f in tp7-mount-handler.sh tp7-import.sh tp7-post.sh; do
    zsh -n "$SH/$f" 2>/dev/null || problems+=("$f does not parse")
    cmp -s "$SH/$f" "$HOME/.dotfiles/lib/music-cli/$f" || problems+=("$f differs from dotfiles")
  done
  floor=$(awk -F= '/^ *min_free_gb/{gsub(/ /,"",$2); print $2}' "$HOME/.config/music/tp7-pull.conf" 2>/dev/null)
  free_gb=$(df -g "$HOME" | awk 'NR==2{print $4}')
  (( free_gb < ${floor:-20} )) && problems+=("disk ${free_gb} GB free < ${floor:-20} GB floor: pulls will stop")
  if (( ${#problems} )); then
    echo "[$(date '+%F %T')] SELFTEST FAIL: ${(j:; :)problems}" >> "$LOG"
    jlog selftest_fail problems="${(j:; :)problems}"
    notify "self-check: ${(j:; :)problems}"
  else
    jlog selftest_ok
  fi
fi

# no TP-7 connected. It also vanishes for ~1 s on every audio<->MTP switch, so only treat it as
# unplugged after 3 empty polls (~30 s); otherwise each mode switch would look like a new plug-in.
# The LOCK belongs to tp7-import.sh (PID-stamped); only clear it if the owning process is dead.
if ! echo "$usb_info" | grep -q '"idVendor" = 9063'; then
  gone=$(( $(cat "$GONE" 2>/dev/null || echo 0) + 1 ))
  echo "$gone" > "$GONE"
  (( gone >= 3 )) && rm -f "$SEEN" "$TRIES"
  if [[ -f "$LOCK" ]] && ! kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
    rm -f "$LOCK"
  fi
  exit 0
fi
rm -f "$GONE"

# already handled this plug-in
[[ -f "$SEEN" ]] && exit 0

# second guard against mode-switch blips: no new import within 3 min of the last one
last=$(cat "$COOL" 2>/dev/null || echo 0)
(( $(date +%s) - last < 180 )) && exit 0

mode=audio
echo "$usb_info" | grep -q '"USB Product Name" = "TP-7 MTP Device"' && mode=mtp

# A powered-off TP-7 still shows on USB (charging) but ignores the MIDI mode switch, which made the
# import fail (LISTFAIL 2026-10-28). In audio mode, only start once it answers a MIDI identity
# request; until then exit quietly and re-check next poll (it syncs the moment it's switched on).
# Background + kill instead of `timeout`: that binary under launchd triggers TCC prompts here.
if [[ "$mode" == audio ]]; then
  probe=/tmp/.music-tp7-midi.$$
  receivemidi dev "TP-7" > "$probe" 2>/dev/null &
  rpid=$!
  sleep 0.4
  sendmidi dev "TP-7" hex syx 7e 7f 06 01 2>/dev/null
  sleep 1.5
  kill "$rpid" 2>/dev/null
  awake=0
  grep -q 'system-exclusive' "$probe" && awake=1
  rm -f "$probe"
  (( awake )) || exit 0
fi

touch "$SEEN"
jlog device_seen mode="$mode"

# Locking lives inside tp7-import.sh (PID-stamped single-flight); launchd never overlaps this job,
# so the import's own mode switches happen while no poll is running.
/bin/zsh "$SH/tp7-import.sh" >> "$LOG" 2>&1   # via zsh: a lost exec bit can't silently skip it
rc=$?
date +%s > "$COOL"

# 75 = the device couldn't be fully read. Retry this plug-in after the 3-min cooldown, up to 3 times;
# then stop and say so once (unplug/replug resets the count).
if (( rc == 75 )); then
  tries=$(( $(cat "$TRIES" 2>/dev/null || echo 0) + 1 ))
  echo "$tries" > "$TRIES"
  if (( tries < 3 )); then
    rm -f "$SEEN"
    jlog retry_scheduled tries="$tries"
  else
    jlog retry_gave_up tries="$tries"
    notify "sync failed 3 times. Unplug the TP-7, then plug it back in."
    # persistent too: a Things to-do survives EJ being away from the Mac
    q=$(python3 -c 'import sys, urllib.parse as u; print(u.urlencode({"title": "TP-7 sync failed", "notes": "3 tries failed. Unplug the TP-7 and plug it back in. Log: ~/.local/share/music-cli/import.log", "when": "today"}, quote_via=u.quote))')
    open -g "things:///add?$q" 2>/dev/null
  fi
else
  rm -f "$TRIES"
fi
