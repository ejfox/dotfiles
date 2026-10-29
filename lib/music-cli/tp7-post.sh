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
#  4. MEMOS      `music tp7 memos` transcribes new spoken recordings into the
#                main vault's voicememos/, then embeds each one under "What
#                happened this week" in this week's note (created from the
#                template if missing). Verbatim; no summary. Recordings that
#                predate 2026-10-28 were seeded into the ledger as
#                "preexisting", so only new memos are touched.
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
  # exactly 8 bytes "short" = a writer that stored the file size (not size-8) in the RIFF field. The file is
  # complete; quarantining it caused an endless re-pull loop (2026-10-04). tp7-pull now verifies every download
  # against the device's size, so this check is a second line of defense for real truncations only.
  [[ $(( declared - actual )) -eq 8 ]] && continue
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
# Probe S3 write with a marker object; if allowed -> aws s3 sync (multipart, resumable, any size). This lights up
# automatically the moment a write-capable token lands in ~/.config/music/.env. Otherwise skip quietly.
BUCKET_NAME="ejfox-personal"; PREFIX="tp7-raw"
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
  else
    # No write token yet. The old wrangler per-file bridge was removed 2026-10-04: under launchd it failed every
    # file (439/run, ~12 min of cold starts) and ended in a Basso alert on every connect. Recordings are covered
    # by the restic backup to computah until a write-capable R2 token lands in ~/.config/music/.env.
    log "backup skipped: R2 key is read-only (add a write token, see README); restic covers ~/tp7"
    jlog backup_skipped reason=readonly_token
  fi
else
  log "backup skipped: missing music .env or aws cli"
  jlog backup_skipped
fi

# --- 4. memos: transcribe new speech -> vault, embed in this week's note ---
# Absolute path: $HOME/bin/music is a stale May copy without `tp7 memos`.
MUSIC="$HOME/.dotfiles/bin/music"
MLEDGER="$HOME/.local/share/music-cli/memos-ledger.tsv"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
if [[ -x "$MUSIC" ]]; then
  touch "$MLEDGER"
  before=$(wc -l < "$MLEDGER" | tr -d ' ')
  "$MUSIC" tp7 memos >/dev/null 2>>"$LOG" || { log "memos: transcribe FAILED"; jlog memos_fail; }
  new_notes=( ${(f)"$(tail -n +$((before+1)) "$MLEDGER" | awk -F'\t' '$2=="speech"{print $3}')"} )
  # each memo goes in the week it was RECORDED (note names start YYYY-MM-DD; the broken TP-7 clock is
  # already mapped to today by `music tp7 memos`), not the week it happened to be imported
  for n in $new_notes; do
    d="${${n:t}[1,10]}"
    wk=$(date -j -f %F "$d" +%G-%V 2>/dev/null) || wk=$(date +%G-%V)
    week="$VAULT/week-notes/$wk.md"
    if [[ ! -f "$week" ]]; then
      sed "s/{{date:YYYY-WW}}/$wk/g" "$VAULT/templates/weekly.md" > "$week"
      log "memos: created week note $wk from template"
    fi
    embed="![[voicememos/${${n:t}%.md}]]"
    grep -qF "$embed" "$week" && continue
    # insert above "## What I made" so memos sit in the human section; else append
    if grep -q '^## What I made' "$week"; then
      E="$embed" awk '/^## What I made/ && !done {printf "%s\n\n", ENVIRON["E"]; done=1} {print}' "$week" > "$week.tmp" && mv "$week.tmp" "$week"
    else
      print -- "$embed" >> "$week"
    fi
    log "memos: ${n:t} -> week-notes/$wk.md"
    jlog memos_ok week="$wk"
  done
else
  log "memos skipped: $MUSIC missing"
fi
