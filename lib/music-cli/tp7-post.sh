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
#  3. (removed 2026-10-29) The old R2 "backup" synced ALL of ~/tp7, memos
#                included, to the bucket behind the PUBLIC r2.ejfox.com domain the
#                moment a write key existed. It never succeeded; restic to computah
#                backs up ~/tp7. Nothing here uploads raw files.
#  4. MEMOS      `music tp7 memos` transcribes new spoken recordings into the
#                main vault's voicememos/, then embeds each one under "What
#                happened this week" in this week's note (created from the
#                template if missing). Verbatim; no summary. Recordings that
#                predate 2026-10-28 were seeded into the ledger as
#                "preexisting", so only new memos are touched.
#  5. PUBLISH    new jams → music.tools.ejfox.com (PUBLIC). The ONLY R2 write in
#                this pipeline. Every upload: its own notification with the public
#                URL + a row in the vault's music-published.md + an import.log line.
#                Memos never upload. See the step for the exact rules.
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

# --- 3. (removed 2026-10-29): no raw R2 sync; see header. restic to computah backs up ~/tp7. ---

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
    # template weeks: insert above "## What I made" (the human section). Other layouts (e.g. the
    # reconstructed backfill weeks): append under an "## In my own words" heading, added once.
    if grep -q '^## What I made' "$week"; then
      E="$embed" awk '/^## What I made/ && !done {printf "%s\n\n", ENVIRON["E"]; done=1} {print}' "$week" > "$week.tmp" && mv "$week.tmp" "$week"
    else
      grep -q '^## In my own words' "$week" || print -- $'\n## In my own words (TP-7 memos)\n' >> "$week"
      print -- "$embed" >> "$week"
    fi
    log "memos: ${n:t} -> week-notes/$wk.md"
    jlog memos_ok week="$wk"
  done
else
  log "memos skipped: $MUSIC missing"
fi

# --- 5. publish: new TP-7 jams -> music.tools.ejfox.com (PUBLIC) ---
# EJ 2026-10-29: auto-publish every new jam, and "be VERY SUPER CLEAR about every single file ever
# uploaded, no 'secretly' uploading files". So this is the ONLY R2 write in the pipeline, and every
# upload gets: its own notification with the public URL, a row in the vault's music-published.md,
# and an import.log line. A failed upload notifies too.
# What qualifies: recordings that arrived in THIS run (new ledger lines) judged "instrumental" by step 4,
# at least 30 s long, and passing every privacy layer below: not from the TP-7's memo folder, never
# judged speech/noise, no voicememos note, and a WHOLE-FILE transcription with <= 12 real words.
# Anything that fails the last check is HELD (publish-held.tsv + notification), never auto-retried.
PUBLOG="$VAULT/music-published.md"
PLEDGER="$HOME/.local/share/music-cli/published.tsv"   # wav <TAB> r2 key <TAB> published at
pnotify() { osascript -e "display notification \"$1\" with title \"TP-7 → music.tools (public)\" sound name \"$2\"" 2>/dev/null; }
r2_put() {   # $1 local mp3, $2 key. Creds stay inside this subshell.
  ( source "$HOME/.config/music/.env" || exit 1
    export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" AWS_DEFAULT_REGION=auto
    aws s3 cp "$1" "s3://${R2_BUCKET_NAME:-ejfox-personal}/$2" \
      --endpoint-url "https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com" \
      --content-type audio/mpeg --only-show-errors ) 2>>"$LOG"
}
if [[ -x "$MUSIC" && -n "${before:-}" ]]; then
  PENDING="$HOME/.local/share/music-cli/publish-pending.txt"   # failed uploads, retried every run
  touch "$PLEDGER" "$PENDING"
  HELD="$HOME/.local/share/music-cli/publish-held.tsv"   # wav <TAB> words heard <TAB> when; never auto-retried
  touch "$HELD"
  jams=( ${(fu)"$( { tail -n +$((before+1)) "$MLEDGER" | awk -F'\t' '$2=="instrumental"{print $1}'; cat "$PENDING"; } )"} )
  for base in $jams; do
    wav="$TP7_ROOT/latest/recordings/$base"
    [[ -f "$wav" ]] || continue
    # --- privacy layers (EJ 2026-10-29: "make sure we don't leak private notes and voice memos") ---
    [[ -e "$TP7_ROOT/cli-memo/$base" ]] && continue                          # TP-7 memo folder: never
    awk -F'\t' -v b="$base" '$1==b && $2!="instrumental"{f=1} END{exit !f}' "$MLEDGER" && continue  # ever judged speech/noise
    grep -rqF -- "${base%.wav}" "$VAULT/voicememos" 2>/dev/null && continue  # has a transcript note
    awk -F'\t' -v b="$base" '$1==b{f=1} END{exit !f}' "$HELD" && continue     # held for EJ: never auto-retry
    awk -F'\t' -v b="$base" '$1==b{f=1} END{exit !f}' "$PLEDGER" && continue  # already published
    [[ "$base" =~ '^([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2})([0-9]{2})' ]] || continue
    d="$match[1]"; hhmm="$match[2]$match[3]"
    secs=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$wav" 2>/dev/null)
    secs=${secs%.*}
    (( ${secs:-0} >= 30 )) || continue
    # last gate: transcribe the WHOLE recording; any real talking (or a failed check) = held, not published
    heard=$("$MUSIC" tp7 safe-to-publish "$wav" 2>/dev/null)
    if (( $? != 0 )); then
      printf '%s\t%s\t%s\n' "$base" "${heard:-unchecked}" "$(date '+%F %H:%M')" >> "$HELD"
      log "HELD (not published) $base: talking detected (${heard:-unchecked} words)"
      jlog publish_held wav="$base" words="${heard:-unchecked}"
      pnotify "Held, NOT published: $base has talking in it (${heard:-?} words). Tell Claude if it's fine to post." "Basso"
      grep -vxF "$base" "$PENDING" > "$PENDING.tmp"; mv "$PENDING.tmp" "$PENDING"
      continue
    fi
    # real recording date: the TP-7 clock ran exactly 14001 days fast until it was set
    (( ${d[1,4]} > $(date +%Y) )) && d=$(date -j -v-14001d -f %F "$d" +%F)
    key="music/tp7/${d}-${hhmm}.mp3"
    n=2
    while [[ "$(curl -s -o /dev/null -w '%{http_code}' -m 10 -I "https://r2.ejfox.com/$key")" == 200 ]]; do
      key="music/tp7/${d}-${hhmm}-$n.mp3"; n=$((n+1))                        # never overwrite
    done
    url="https://r2.ejfox.com/$key"
    len=$(printf '%d:%02d' $((secs / 60)) $((secs % 60)))
    mp3="/tmp/tp7-publish-$$.mp3"
    if ffmpeg -loglevel error -y -i "$wav" -codec:a libmp3lame -b:a 320k "$mp3" </dev/null && r2_put "$mp3" "$key"; then
      now=$(date '+%F %H:%M')
      printf '%s\t%s\t%s\n' "$base" "$key" "$now" >> "$PLEDGER"
      if [[ ! -f "$PUBLOG" ]]; then
        print -- "# Music published to music.tools.ejfox.com" > "$PUBLOG"
        print -- "" >> "$PUBLOG"
        print -- "Every file the TP-7 pipeline has ever uploaded. These are PUBLIC. Written by tp7-post.sh; nothing uploads without a row here." >> "$PUBLOG"
        print -- "" >> "$PUBLOG"
        print -- "| published | recorded | length | public URL | source wav |" >> "$PUBLOG"
        print -- "|---|---|---|---|---|" >> "$PUBLOG"
      fi
      print -- "| $now | $d ${hhmm[1,2]}:${hhmm[3,4]} | $len | $url | $base |" >> "$PUBLOG"
      log "PUBLISHED (public) $base -> $url ($len)"
      jlog published wav="$base" key="$key" len="$len"
      pnotify "Published $d ${hhmm[1,2]}:${hhmm[3,4]} jam ($len): $url" "Glass"
      grep -vxF "$base" "$PENDING" > "$PENDING.tmp"; mv "$PENDING.tmp" "$PENDING"
    else
      log "PUBLISH FAILED $base (nothing went public; will retry next plug-in)"
      jlog publish_fail wav="$base"
      pnotify "NOT published: $base. Upload failed, nothing went public. Retrying next plug-in." "Basso"
      grep -qxF "$base" "$PENDING" || print -- "$base" >> "$PENDING"
    fi
    rm -f "$mp3"
  done
fi
