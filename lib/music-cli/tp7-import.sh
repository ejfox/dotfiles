#!/bin/zsh
# tp7-import.sh — orchestrates a TP-7 pull with milestone notifications and a
# guaranteed field-kit fallback. Called by the launchd watcher (tp7-mount-handler.sh)
# when a TP-7 is detected in MTP mode. Safe to run by hand too.
export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/bin:$PATH"

SH=/Users/ejfox/.local/share/music-cli
DEST="${1:-/Users/ejfox/tp7/latest/recordings}"
LOG="${HOME}/.local/share/music-cli/import.log"
JLOG_DIR="${HOME}/.local/share/usage-logs/music"
mkdir -p "$DEST" "$JLOG_DIR"

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

fallback_fieldkit() {
  log "CLI pull did not deliver files — opening field kit"
  jlog pull_fail fallback=fieldkit
  notify "auto-pull couldn't read the device — opening field kit"
  open -a "field kit" 2>/dev/null
}

log "=== import start -> $DEST ==="
jlog import_start dest="$DEST"

# how many real files are already staged (so we can tell if the pull added anything)
before=$(find "$DEST" -type f -name '*.wav' 2>/dev/null | wc -l | tr -d ' ')

notify "TP-7 detected — starting pull"

total=0; nextpct=25
# stream root pull output; milestone notifications only — NO per-file spam.
# NOTE: zsh runs the last pipe stage in the current shell, so $total survives the loop.
# The puller emits lines like:
#   /path/to/dest TOPULL=5        (count is NOT the first token — match anywhere)
#   P <n> <total> <filename>      (per-file progress)
#   END got=<n> failed=<n>
sudo -n "$SH/tp7-root-pull.sh" "$DEST" 2>>"$LOG" | while IFS= read -r line; do
  log "$line"
  case "$line" in
    *TOPULL=*)
      total="${line##*TOPULL=}"; total="${total%%[^0-9]*}"
      if [[ "${total:-0}" -eq 0 ]]; then
        notify "already up to date — nothing new"
      else
        notify "$total file(s) to pull"
        jlog pull_start topull="$total"
      fi ;;
    P\ *)
      w=(${=line})   # w[1]=P w[2]=done-count w[3]=total w[4...]=name
      if [[ $total -gt 0 && "${w[2]:-0}" -gt 0 ]]; then
        pct=$(( w[2] * 100 / total ))
        while (( pct >= nextpct && nextpct <= 100 )); do
          notify "${nextpct}% — ${w[2]}/${total} files"; nextpct=$((nextpct+25))
        done
      fi ;;
    END*) log "pull end: $line" ;;
  esac
done

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
  # nothing new landed. If the device simply had nothing, TOPULL was 0 and that's fine.
  if [[ ${total:-0} -eq 0 ]]; then
    log "=== nothing to import (already current) ==="
    jlog pull_uptodate staged_total="$after"
  else
    fallback_fieldkit
    log "=== import FAILED — fell back to field kit ==="
  fi
fi
