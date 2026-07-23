#!/bin/zsh
# tp7-post.sh — post-pull integrity check, organize, and off-machine backup.
# Called by tp7-import.sh after every pull; safe (and useful) to run by hand.
#
#  1. INTEGRITY  truncated-download protection: a USB disconnect mid-transfer
#                leaves a wav whose RIFF header declares more bytes than exist.
#                Quarantine those — removing the name from latest/ (the
#                skip-existing ledger) makes the next connect re-pull them.
#  2. ORGANIZE   hardlink wavs into ~/tp7/by-date/YYYY-MM-DD/ (date parsed
#                from the TP-7's timestamped filenames; zero extra disk).
#                latest/recordings must keep its files — it is the dedupe
#                ledger against the device. Never move out of it, only link.
#  3. BACKUP     aws s3 sync → r2://ejfox-personal/tp7-raw (same creds the
#                music CLI uses, from ~/.config/music/.env). Excludes by-date/
#                (hardlinks would upload twice) and quarantine/.
export PATH="/usr/local/bin:/opt/homebrew/bin:$HOME/bin:$PATH"
setopt extendedglob null_glob

TP7_ROOT="${TP7_ROOT:-$HOME/tp7}"
QUAR="$TP7_ROOT/quarantine"
BYDATE="$TP7_ROOT/by-date"
LOG="${HOME}/.local/share/music-cli/import.log"
JLOG_DIR="${HOME}/.local/share/usage-logs/music"
mkdir -p "$JLOG_DIR"

log()  { echo "[$(date '+%F %T')] post: $1" >> "$LOG"; }
jlog() {
  local evt="$1"; shift
  local extra="" kv
  for kv in "$@"; do extra+=",\"${kv%%=*}\":\"${kv#*=}\""; done
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"src\":\"music\",\"evt\":\"$evt\"$extra}" \
    >> "$JLOG_DIR/$(date +%F).jsonl"
}

# --- 1. integrity: quarantine truncated wavs (actual bytes < RIFF declared) ---
quarantined=0
for f in "$TP7_ROOT"/*/recordings/*.wav "$TP7_ROOT"/*/recordings/*.WAV; do
  [[ -f "$f" ]] || continue
  actual=$(stat -f%z "$f" 2>/dev/null || echo 0)
  if [[ "$actual" -lt 44 ]]; then           # smaller than a bare RIFF+fmt header
    declared=99999999
  else
    riff=$(od -An -t u4 -j 4 -N 4 "$f" 2>/dev/null | tr -d ' ')
    [[ -z "$riff" ]] && riff=0
    [[ "$riff" -eq 4294967295 ]] && continue  # RF64/streaming sentinel — can't judge
    declared=$(( riff + 8 ))
  fi
  if [[ "$actual" -lt "$declared" ]]; then
    mkdir -p "$QUAR"
    mv "$f" "$QUAR/"
    quarantined=$((quarantined+1))
    log "QUARANTINED truncated: ${f##*/} (actual=$actual declared=$declared)"
    jlog wav_quarantined file="${f##*/}" actual="$actual" declared="$declared"
  fi
done
if [[ $quarantined -gt 0 ]]; then
  osascript -e "display notification \"$quarantined truncated file(s) quarantined — will re-pull on next connect\" with title \"TP-7 import\" sound name \"Basso\"" 2>/dev/null
fi

# --- 2. organize: hardlink into by-date/YYYY-MM-DD/ ---
linked=0
for f in "$TP7_ROOT"/*/recordings/*.wav "$TP7_ROOT"/*/recordings/*.WAV; do
  [[ -f "$f" ]] || continue
  name="${f##*/}"
  if [[ "$name" =~ '^([0-9]{4}-[0-9]{2}-[0-9]{2})_' ]]; then
    d="$match[1]"
  else
    d=$(stat -f %Sm -t %Y-%m-%d "$f" 2>/dev/null) || continue
  fi
  dst="$BYDATE/$d/$name"
  if [[ -e "$dst" ]]; then
    [[ "$f" -ef "$dst" ]] && continue                     # already this inode
    if cmp -s "$f" "$dst"; then continue; fi              # same content elsewhere (legacy dup)
    dst="$BYDATE/$d/${name%.*}-dup.${name##*.}"           # same name, different audio — keep both
    [[ -e "$dst" ]] && continue
    jlog organize_collision file="$name" date="$d"
  fi
  mkdir -p "$BYDATE/$d"
  ln "$f" "$dst" 2>/dev/null && linked=$((linked+1))
done
[[ $linked -gt 0 ]] && { log "organized $linked file(s) into by-date/"; jlog organize_ok linked="$linked"; }

# --- 3. backup: raw wavs to R2 bucket ejfox-personal under tp7-raw/ ---
# Capability-detecting, two tiers (as of 2026-07-23 the music S3 keypair is
# READ-ONLY — PutObject denied — and wrangler caps `r2 object put` at 300MiB):
#   a) probe S3 write with a marker object; if allowed -> aws s3 sync
#      (multipart, resumable, handles any size). This lights up automatically
#      the moment a write-capable token lands in ~/.config/music/.env.
#   b) else -> wrangler for files <=250MiB; larger files are loudly flagged
#      as LOCAL-ONLY until the write token exists.
BUCKET_NAME="ejfox-personal"; PREFIX="tp7-raw"
WRANGLER_MAX=$((250 * 1024 * 1024))
if [[ -f "$HOME/.config/music/.env" ]] && command -v aws >/dev/null; then
  source "$HOME/.config/music/.env"
  export AWS_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-}" AWS_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-}" AWS_DEFAULT_REGION=auto
  EP="https://${R2_ACCOUNT_ID:-deffa184038440afc07f53b5e7583a97}.r2.cloudflarestorage.com"

  if print -n "probe" | aws s3 cp - "s3://$BUCKET_NAME/$PREFIX/.write-probe" --endpoint-url "$EP" >/dev/null 2>&1; then
    # tier (a): real sync
    if aws s3 sync "$TP7_ROOT" "s3://$BUCKET_NAME/$PREFIX" --endpoint-url "$EP" \
         --exclude "by-date/*" --exclude "quarantine/*" --exclude ".*" --exclude "*/.*" \
         --only-show-errors 2>>"$LOG"; then
      log "backup sync OK -> r2:$BUCKET_NAME/$PREFIX (s3 write token active)"
      jlog backup_ok mode=sync
    else
      log "backup sync FAILED"
      jlog backup_fail mode=sync
      osascript -e 'display notification "R2 backup failed — recordings are LOCAL ONLY" with title "TP-7 import" sound name "Basso"' 2>/dev/null
    fi
  elif command -v wrangler >/dev/null; then
    # tier (b): wrangler small-file bridge. Remote inventory via read creds.
    typeset -A on_r2
    while IFS=$'\t' read -r key sz; do
      [[ -n "$key" ]] && on_r2["${key#$PREFIX/}"]="$sz"
    done < <(aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --prefix "$PREFIX/" \
               --endpoint-url "$EP" --query 'Contents[].[Key,Size]' --output text 2>>"$LOG")
    up_ok=0; up_fail=0; too_big=0
    for f in "$TP7_ROOT"/*/recordings/*.wav "$TP7_ROOT"/*/recordings/*.WAV; do
      [[ -f "$f" ]] || continue
      rel="${f#$TP7_ROOT/}"
      sz=$(stat -f%z "$f" 2>/dev/null || echo 0)
      [[ "${on_r2[$rel]:-}" == "$sz" ]] && continue
      if [[ "$sz" -gt "$WRANGLER_MAX" ]]; then
        too_big=$((too_big+1)); log "backup SKIPPED (>250MiB, needs s3 write token): $rel"
        continue
      fi
      if wrangler r2 object put "$BUCKET_NAME/$PREFIX/$rel" --file "$f" --remote >/dev/null 2>>"$LOG"; then
        up_ok=$((up_ok+1)); log "backed up $rel ($sz bytes)"
      else
        up_fail=$((up_fail+1)); log "backup FAILED for $rel"
      fi
    done
    log "backup (wrangler tier): ok=$up_ok fail=$up_fail local_only_toobig=$too_big"
    jlog backup_partial uploaded="$up_ok" failed="$up_fail" too_big="$too_big"
    if [[ $((up_fail + too_big)) -gt 0 ]]; then
      osascript -e "display notification \"$too_big large + $up_fail failed file(s) NOT backed up — add a write R2 token (see lib/music-cli/README)\" with title \"TP-7 backup\" sound name \"Basso\"" 2>/dev/null
    fi
  else
    log "backup skipped: no write path (s3 read-only, wrangler missing)"
    jlog backup_skipped
  fi
else
  log "backup skipped: missing music .env or aws cli"
  jlog backup_skipped
fi
