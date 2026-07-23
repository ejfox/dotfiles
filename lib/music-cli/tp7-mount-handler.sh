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

# no TP-7 connected — clear state
if ! echo "$usb_info" | grep -q '"idVendor" = 9063'; then
  rm -f "$SEEN" "$LOCK"
  exit 0
fi

# already handled this session
[[ -f "$SEEN" ]] && exit 0

# TP-7 connected but not MTP mode
if ! echo "$usb_info" | grep -q '"idProduct" = 25'; then
  touch "$SEEN"
  jlog device_seen mode=disk
  osascript -e 'display notification "To pull files: power off, hold STOP + power on" with title "TP-7 connected" sound name "Glass"'
  exit 0
fi

# TP-7 in MTP mode — auto-pull
touch "$SEEN"
jlog device_seen mode=mtp

# prevent double-runs
[[ -f "$LOCK" ]] && exit 0
touch "$LOCK"

# self-healing importer: tries the CLI pull, auto-falls-back to field kit on failure.
# milestone notifications (25/50/75/100% of delta) handled inside; no per-file spam.
/Users/ejfox/.local/share/music-cli/tp7-import.sh >> "$LOG" 2>&1

rm -f "$LOCK"
