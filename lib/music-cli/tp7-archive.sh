#!/bin/zsh
# tp7-archive.sh: copy anything new in ~/tp7 to the PRIVATE R2 bucket ejfox-archive (no public URL).
# Copy only: never deletes or overwrites-by-removal, locally or remotely.
# Runs after every import (tp7-post.sh) and once a day (tp7-mount-handler.sh self-check), so a failed
# run is retried the next day by itself. Single-flight via a PID lock.
# by-date/ is hardlinks into latest/ + archive/, so only its single-link files are uploaded.
# Never point this at ejfox-personal: that bucket is public through r2.ejfox.com.
export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"
TP7="$HOME/tp7"
DEST="r2-archive:ejfox-archive/originals/imac/tp7"
SH="$HOME/.local/share/music-cli"
LOG="$SH/import.log"
LOCK="$SH/.archive.lock"   # a directory: mkdir is atomic, and it lives in our own state dir, not /tmp
JLOG_DIR="$HOME/.local/share/usage-logs/music"
log()  { echo "[$(date '+%F %T')] archive: $1" >> "$LOG"; }
jlog() { mkdir -p "$JLOG_DIR"; echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"src\":\"music\",\"evt\":\"$1\"${2:+,\"detail\":\"$2\"}}" >> "$JLOG_DIR/$(date +%F).jsonl"; }

if ! mkdir "$LOCK" 2>/dev/null; then
  # held: leave if its owner is alive; reclaim once if it died without cleaning up
  kill -0 "$(cat "$LOCK/pid" 2>/dev/null)" 2>/dev/null && exit 0
  rm -f "$LOCK/pid"; rmdir "$LOCK" 2>/dev/null
  mkdir "$LOCK" 2>/dev/null || exit 0
fi
echo $$ > "$LOCK/pid"
trap 'rm -f "$LOCK/pid"; rmdir "$LOCK" 2>/dev/null' EXIT

command -v rclone >/dev/null || { log "FAILED: rclone missing"; jlog archive_fail "rclone missing"; exit 1; }
cd "$TP7" || { log "FAILED: no $TP7"; exit 1; }

FLAGS=(--transfers 4 --s3-upload-cutoff 200M --s3-chunk-size 64M --stats 0 --log-level NOTICE)
bydate=$(mktemp)
out=$(mktemp)
rc0=0
if [[ -d by-date ]]; then
  find by-date -type f -links 1 > "$bydate" 2>> "$out"
  rc0=$?
fi
rclone copy "$TP7" "$DEST" --exclude "by-date/**" --exclude ".DS_Store" --exclude "*.partial" $FLAGS > "$out" 2>&1
rc1=$?
rc2=0
if [[ -s "$bydate" ]]; then
  rclone copy "$TP7" "$DEST" --files-from "$bydate" $FLAGS >> "$out" 2>&1
  rc2=$?
fi
if (( rc0 == 0 && rc1 == 0 && rc2 == 0 )); then
  log "OK (copied anything new to ejfox-archive)"
  jlog archive_ok
else
  log "FAILED rc=$rc0/$rc1/$rc2, retries tomorrow: $(tail -3 "$out" | tr '\n' ' ')"
  jlog archive_fail "rc=$rc0/$rc1/$rc2"
fi
rm -f "$out" "$bydate"
