#!/bin/zsh
# tp7-import.sh — orchestrates a TP-7 pull with milestone notifications and a
# guaranteed field-kit fallback. Called by the launchd watcher (tp7-mount-handler.sh)
# when a TP-7 is detected in MTP mode. Safe to run by hand too.
export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/bin:$PATH"
setopt extendedglob

SH=/Users/ejfox/.local/share/music-cli
DEST="${1:-/Users/ejfox/tp7/latest/recordings}"
LOG="${HOME}/.local/share/music-cli/import.log"
JLOG_DIR="${HOME}/.local/share/usage-logs/music"
LOCK=/tmp/.music-tp7-pulling
mkdir -p "$DEST" "$JLOG_DIR"

# single-flight: the import owns its lock (PID-stamped). A stale lock from a
# crashed run is detected by the dead PID and taken over. This also protects
# manual runs racing the launchd watcher.
if [[ -f "$LOCK" ]]; then
  oldpid=$(<"$LOCK")
  if [[ -n "$oldpid" ]] && kill -0 "$oldpid" 2>/dev/null; then
    echo "another import (pid $oldpid) is running — exiting"
    exit 0
  fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT INT TERM

# keep the human log bounded (~1MB cap, keep last 256KB)
if [[ -f "$LOG" && $(stat -f%z "$LOG" 2>/dev/null || echo 0) -gt 1048576 ]]; then
  tail -c 262144 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

notify() { osascript -e "display notification \"$1\" with title \"TP-7 import\" sound name \"Glass\"" 2>/dev/null; }
log()    { echo "[$(date '+%F %T')] $1" >> "$LOG"; }
# structured event log, same idiom as the rest of usage-logs
jlog() {
  local evt="$1"; shift
  local extra=""
  local kv
  for kv in "$@"; do extra+=",\"${kv%%=*}\":\"${kv#*=}\""; done
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"src\":\"music\",\"evt\":\"$evt\"$extra}" \
    >> "$JLOG_DIR/$(date +%F).jsonl"
}

# persistent heads-up in Things Today (a notification is easy to miss when EJ is away)
things_todo() {   # $1 short title (Watch-legible), $2 notes
  local q=$(python3 -c 'import sys, urllib.parse as u; print(u.urlencode({"title": sys.argv[1], "notes": sys.argv[2], "when": "today"}, quote_via=u.quote))' "$1" "$2")
  open -g "things:///add?$q" 2>/dev/null
}

log "=== import start -> $DEST ==="
jlog import_start dest="$DEST"

# how many real files are already staged (so we can tell if the pull added anything)
before=$(find "$DEST" -type f -name '*.wav' 2>/dev/null | wc -l | tr -d ' ')

notify "TP-7 detected — starting pull"

# --- pull via the native tp7 CLI (totocaster/tp7) + MIDI mode switch ---
# 2026-10-28: on firmware 1.1.11 libmtp lists 0 files (blind to /memo AND /recordings), so the old
# sudo/libmtp puller (tp7-root-pull.sh) is no longer called. The TP-7 also drops out of MTP after
# each CLI session, so before every op we send TE's MTP mode-switch SysEx over MIDI (sendmidi;
# sequence from totocaster/tp7 docs/tp7-handshake.md) and wait for "TP-7 MTP Device". One op per
# switch, retry once. Disk floor = min_free_gb from tp7-pull.conf, checked before every file.
MEMO_DIR="${HOME}/tp7/cli-memo"
QUAR="${HOME}/tp7/quarantine"
CONF="${HOME}/.config/music/tp7-pull.conf"
mkdir -p "$MEMO_DIR"
floor_gb=20
[[ -f "$CONF" ]] && floor_gb=$(awk -F= '/^ *min_free_gb/{gsub(/ /,"",$2); print $2}' "$CONF")
[[ "$floor_gb" == <-> ]] || floor_gb=20

in_mtp() { ioreg -p IOUSB -l -w0 | grep -q '"USB Product Name" = "TP-7 MTP Device"'; }
to_mtp() {
  in_mtp && return 0
  sendmidi dev "TP-7" hex syx 00 20 76 19 40 60 05 04 00 01 03 2>/dev/null
  local i
  for i in {1..30}; do
    if in_mtp; then sleep 1; return 0; fi
    sleep 0.5
  done
  return 1
}
# one tp7 CLI op on a fresh MTP session; on failure re-switch and retry once.
# macOS's ptpcamerad grabs every MTP device exclusively the moment it appears ("busy", 0xe00002c5,
# 2026-10-31); it runs as EJ, so kill it right before each op (launchd respawns it, harmlessly).
tp7op() {
  to_mtp && pkill -9 -x ptpcamerad 2>/dev/null; to_mtp && tp7 "$@" 2>/dev/null && return 0
  sleep 2
  to_mtp && pkill -9 -x ptpcamerad 2>/dev/null; to_mtp && tp7 "$@" 2>/dev/null
}

total=0; got=0; stopped=""; retry_wanted=0
if ! command -v tp7 >/dev/null || ! command -v sendmidi >/dev/null; then
  stopped=notools
  log "tp7 CLI or sendmidi missing"
  notify "tp7 CLI or sendmidi missing — see README"
else
  # 1. memos: whole /memo folder (small), new ones hardlinked into DEST for tp7-post
  tp7op pull --recursive --skip-existing --no-progress /memo "$MEMO_DIR" | grep '^downloaded' >> "$LOG"
  if (( pipestatus[1] != 0 )); then
    retry_wanted=1
    log "memo pull FAILED"
  fi
  memo_new=0
  for m in "$MEMO_DIR"/*.wav(N); do
    [[ -e "$DEST/${m:t}" ]] && continue
    ln "$m" "$DEST/" 2>/dev/null && memo_new=$((memo_new+1))
  done
  log "memos via tp7 CLI: $memo_new new"
  jlog memo_pull new="$memo_new"

  # 2. recordings: list newest-first, pull each one we don't have, above the disk floor
  listing=$(tp7op ls -l -t /recordings)
  if [[ -z "$listing" ]]; then
    stopped=listfail
    log "LISTFAIL /recordings"
    jlog pull_listfail
    notify "couldn't list TP-7 recordings — unplug, replug in MTP mode"
  else
    want=()
    for line in ${(f)listing}; do
      w=(${=line})                     # file <bytes> <stamp> <name>
      [[ "${w[1]}" == file ]] || continue
      [[ -e "$DEST/${w[4]}" || -e "$QUAR/${w[4]}" ]] && continue
      want+=("${w[2]} ${w[4]}")
    done
    total=${#want}
    need=0
    for item in $want; do need=$(( need + ${item%% *} )); done
    free=$(df -k "$DEST" | awk 'NR==2{print $4*1024}')
    log "recordings: $total to pull, $(( need / 1048576 )) MB (floor ${floor_gb} GB)"
    if (( total > 0 && free < need + floor_gb * 1073741824 )); then
      stopped=diskfloor
      log "STOP diskfloor: need $(( need / 1048576 )) MB + ${floor_gb} GB floor, $(( free / 1048576 )) MB free"
      jlog pull_diskfloor
      notify "Mac disk too full to pull $total TP-7 recording(s). Free space, then replug."
      things_todo "TP-7: disk full" "$total recording(s), $(( need / 1048576 )) MB, are waiting on the TP-7. Free space on the Mac, then plug it in again."
    elif (( total > 0 )); then
      notify "$total recording(s) to pull"
      jlog pull_start topull="$total"
      # ONE session for everything (2026-10-31): every tp7 op restarts the TP-7 into MTP mode,
      # so per-file pulls meant a restart per file. skip-existing skips what we already have;
      # a truncated file from a dropped session is quarantined by tp7-post and re-pulled next time.
      tp7op pull --recursive --skip-existing --no-progress /recordings "$DEST" | grep '^downloaded' >> "$LOG"
      (( pipestatus[1] != 0 )) && retry_wanted=1
      for item in $want; do [[ -e "$DEST/${item#* }" ]] && got=$((got+1)); done
      (( got < total )) && retry_wanted=1
    fi
    log "pull end: got=$got of $total"
  fi
fi

# evaluate what actually landed on disk (source of truth, not the stream)
after=$(find "$DEST" -type f -name '*.wav' 2>/dev/null | wc -l | tr -d ' ')
added=$(( after - before ))
size=$(du -sh "$DEST" 2>/dev/null | cut -f1)
log "after=$after before=$before added=$added size=$size"

if [[ $added -gt 0 ]]; then
  notify "✓ imported $added file(s) — $size total"
  log "=== import OK: +$added files ==="
  jlog pull_ok added="$added" staged_total="$after" size="$size"
else
  # nothing new landed. A known stop already told EJ why; TOPULL=0 means up to date; anything else = real failure.
  if [[ -n "${stopped:-}" ]]; then
    log "=== stopped ($stopped), nothing new landed ==="
  elif [[ ${total:-0} -eq 0 ]]; then
    log "=== nothing to import (already current) ==="
    jlog pull_uptodate staged_total="$after"
  else
    retry_wanted=1
    log "=== import FAILED: nothing landed ==="
  fi
fi

# post-pull: quarantine, by-date links, memos, publish. Run via zsh so a lost exec bit can't
# silently skip it (that happened: "permission denied", import "succeeded", post never ran).
/bin/zsh "$SH/tp7-post.sh"

# exit 75 (EX_TEMPFAIL) = the device couldn't be fully read; the watcher retries this plug-in.
# Disk-floor stops exit 0: retrying can't fix a full disk, and EJ was already notified.
if [[ "$stopped" == listfail || "$retry_wanted" == 1 ]]; then
  exit 75
fi
exit 0
