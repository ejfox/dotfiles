# music-cli TP-7 pipeline (mirror)

LIVE copies run from `~/.local/share/music-cli/` — these are tracked mirrors so
the pipeline survives a disk loss. If you edit here, copy to the live location
(or vice versa). The `tp7-pull` (libmtp) and `tp7-detach-driver` (libusb)
binaries are built by `music setup` and are not mirrored.

## Flow (since 2026-10-28: tp7 CLI + MIDI, no hold-STOP)

On firmware 1.1.11 libmtp lists **0 files** (blind to `/memo` and `/recordings`), so the
automatic path no longer uses it. Plug the TP-7 in normally, in any mode, and it syncs:

```
launchd com.ejfox.music-tp7-watch (every 10s)
  └─ tp7-mount-handler.sh   TE vendor 9063 on the bus? once per plug-in
       │                    (unplug = 3 empty polls; 180 s cooldown, because
       │                     every audio<->MTP switch drops off USB for ~1 s)
       └─ tp7-import.sh        (run via /bin/zsh so a lost exec bit can't skip it)
            ├─ before EVERY tp7 op: MIDI SysEx 00 20 76 19 40 60 05 04 00 01 03 → wait for
            │  "TP-7 MTP Device", then `pkill -9 ptpcamerad` (macOS's camera daemon grabs MTP
            │  devices exclusively → "busy" 0xe00002c5). Each op = one TP-7 restart; the device
            │  falls back to audio mode after every CLI session.
            ├─ tp7 pull --recursive --skip-existing /memo → ~/tp7/cli-memo, hardlinked into latest/
            ├─ tp7 ls -l -t /recordings → disk floor checked on the TOTAL of missing files
            ├─ tp7 pull --recursive --skip-existing /recordings → latest/   (ONE session)
            └─ tp7-post.sh
                 1 quarantine truncated wavs (re-pulled next plug-in)
                 2 by-date/ hardlinks
                 4 memos: ONE whole-file whisper pass per new file. ≥5 real words = memo →
                   ejfox/voicememos/ + embed in that week's note; <5 = jam. Word count → ledger col 4.
                 5 PUBLISH (public!): jam, ≥30 s, not from /memo, ledger words <5 →
                   320k MP3 via wrangler → r2 ejfox-personal music/tp7/<real date>-<HHMM>.mp3
                   (r2.ejfox.com; listed on music.tools + Tapes iOS app via /api/tracks).
                   Every upload: notification + row in vault music-published.md (▶ listen /
                   ✕ remove) + Things to-do "Jam Oct 11 10:59p ok?" + import.log line.
                   Anything that fails the gate is HELD (publish-held.tsv + Things), never retried.
```

**Remove a published jam:** click ✕ remove in `music-published.md` →
`hammerspoon://tp7-unpublish?key=…` → `~/.dotfiles/hammerspoon/tp7-unpublish.lua` →
`music tp7 unpublish <key>` (deletes from R2, strikes the row, notifies; never re-uploaded).

**Ledgers** (`~/.local/share/music-cli/`): `memos-ledger.tsv` (wav, verdict, note, words),
`published.tsv` (wav, key, published, removed), `publish-pending.txt` (failed uploads, retried),
`publish-held.tsv` (gate failures). The old R2 "backup" sync is gone: r2.ejfox.com is a PUBLIC
domain over the whole bucket, so raw files never go there. restic to computah backs up ~/tp7.

**Waveforms on music.tools:** `vps:/data2/smallweb/data/music/peaks.py` (cron */15, flock)
computes 200 real peaks per track with ffmpeg → `music/data/peaks.json`; main.ts draws SVG.

- Deps: `tp7` (brew totocaster/tap/tp7 0.1.0) and `sendmidi`, both in /usr/local/bin. The CLI
  only sees the device in MTP mode (PID 0x0019); in audio mode this unit is 0x8019, which the
  CLI doesn't match. That's why the MIDI switch is done here and not with `tp7 -a`.
- Memos: the TP-7 clock ran exactly 14001 days fast until it was set; `music tp7 memos` maps
  2064/2065 stamps back. Ledger `preexisting` / `preexisting-memo` rows = never processed;
  delete a line to backfill that file.
- `music tp7` with no args prints usage. The old libmtp commands (pull, ls, status, clean,
  rename-memos) are unrouted: libmtp is blind on 1.1.11, and `pull` uploaded speech unrecorded.
- Failures that need EJ also leave a Things to-do: disk too full to pull, or 3 failed tries.
- Deploy edits atomically (`cp f f.new && mv f.new f`): zsh reads scripts as it runs, and
  replacing one mid-run caused "parse error" lines in watcher.log on 2026-10-28.
- Manual run: `~/.local/share/music-cli/tp7-import.sh` (works from audio mode).
- **Powered off but plugged in:** it still shows on USB but ignores MIDI. The watcher sends a MIDI
  identity request (`7e 7f 06 01`) and starts only once the TP-7 answers, so it syncs the moment
  it's switched on. Exits quietly until then.
- **Retries:** `tp7-import.sh` exits 75 when the device couldn't be fully read (list failed, memo
  pull failed, or any recording failed). The watcher retries that plug-in after the 3-min cooldown,
  up to 3 times, then notifies once ("unplug, then plug back in"). Counter: `/tmp/.music-tp7-tries`,
  cleared on unplug or success. A disk-floor stop exits 0, since retrying can't help.
- **Daily self-check** (inside the watcher, once per day, TP-7 not needed; notifies ONLY on failure):
  deps (tp7, sendmidi, receivemidi, whisper-cli, ffmpeg, ffprobe, music, whisper model), each live
  script parses AND matches its dotfiles copy, disk free ≥ floor. Log line `SELFTEST FAIL` in
  watcher.log, events `selftest_ok/fail` in the usage log. Force a re-run: delete `selftest.stamp`.

### Old libmtp flow (kept for reference; broken on firmware 1.1.11)

```
launchd com.ejfox.music-tp7-watch (every 10s)
  └─ tp7-mount-handler.sh     ioreg poll (~17ms): TE vendor 9063 present?
       └─ tp7-import.sh       notifications, milestone %, field-kit fallback,
            │                 JSONL events → ~/.local/share/usage-logs/music/
            └─ sudo -n tp7-root-pull.sh     (as root)
                 ├─ suppress ptpcamerad/mscamerad for transfer duration
                 ├─ tp7-detach-driver       libusb whole-device capture
                 └─ tp7-pull DEST           libmtp, skip-existing
                                            → ~/tp7/latest/recordings
```

`music tp7 pull` (manual) uses the same root engine, then runs its own phase 2:
whisper auto-naming → BPM (aubio) / key (keyfinder) → mp3 → R2 upload.

## Why it's built this way (researched 2026-07-23)

- **Root for USB detach**: on macOS, libusb kernel-driver detach is
  whole-device *capture* and requires root — the `com.apple.vm.device-access`
  entitlement alternative is unavailable to CLI tools (no provisioning
  profiles). See [libusb FAQ](https://github.com/libusb/libusb/wiki/FAQ),
  [PR #911](https://github.com/libusb/libusb/pull/911),
  [issue #1014](https://github.com/libusb/libusb/issues/1014).
- **ptpcamerad kill loop**: macOS's PTP camera daemon claims MTP devices on
  connect and re-claims them; it cannot be persistently disabled on modern
  macOS (SIP). Suppressing it only during the transfer window is the
  community-standard workaround (OpenMTP does the same). See
  [OpenMTP](https://github.com/ganeshrvel/openmtp),
  [Apple discussion](https://discussions.apple.com/thread/254788819).
- **Polling instead of launchd IOKit matching**: `LaunchEvents >
  com.apple.iokit.matching` can fire on USB match, but the job must consume
  the XPC event via `xpc_set_event_stream_handler()` or launchd relaunches it
  repeatedly — needs a compiled helper
  ([snosrap/xpc_set_event_stream_handler](https://github.com/snosrap/xpc_set_event_stream_handler),
  [mac-device-connect-daemon](https://github.com/himbeles/mac-device-connect-daemon)).
  A 17ms `ioreg` check every 10s is simpler, dependency-free, and effectively
  free; `system_profiler` (the old poll) cost ~1.5s per tick.
- **gphoto2 retired for transfer**: as non-root it cannot claim the TP-7 on
  macOS 15.7+; it lingers only as best-effort in `music tp7 pull --clean`.

## Security note (known, accepted tradeoff)

`/etc/sudoers.d/tp7-detach` grants NOPASSWD root for `tp7-detach-driver` and
`tp7-root-pull.sh`, which live in a **user-writable** directory — any code
running as ejfox could edit them and escalate to root. Accepted on this
single-user machine for convenience. To harden (needs sudo once):

```sh
sudo mkdir -p /usr/local/libexec/music-cli
sudo cp ~/.local/share/music-cli/{tp7-root-pull.sh,tp7-detach-driver,tp7-pull} /usr/local/libexec/music-cli/
sudo chown -R root:wheel /usr/local/libexec/music-cli
# then point /etc/sudoers.d/tp7-detach and tp7-import.sh at the libexec copies
```

## Post-pull pass (tp7-post.sh, added 2026-07-23)

Runs after every import (also fine by hand). Three phases:

1. **Integrity / mid-transfer protection** — a USB unplug mid-download leaves
   a wav whose RIFF header declares more bytes than exist on disk. Those get
   moved to `~/tp7/quarantine/`, which removes their names from the
   skip-existing ledger, so the next connect re-pulls them automatically.
2. **Organize** — hardlinks every wav into `~/tp7/by-date/YYYY-MM-DD/` (date
   parsed from the TP-7's timestamped filenames). Zero extra disk. RULE:
   `latest/recordings` is the dedupe ledger against the device — never move
   files out of it while they're still on the TP-7; only link.
3. **Backup to R2** (`ejfox-personal/tp7-raw/`) — capability-detecting:
   - probes S3 write each run; with a write-capable token it uses
     `aws s3 sync` (multipart, any size, resumable)
   - **current state**: the music S3 keypair is READ-ONLY and wrangler caps
     uploads at 300MiB — so files ≤250MiB go up via wrangler and larger ones
     are flagged LOCAL-ONLY in notifications/logs.
   - **to finish this properly**: Cloudflare dashboard → R2 → Manage API
     Tokens → create an "Object Read & Write" token scoped to
     `ejfox-personal`, put its S3 credentials in `~/.config/music/.env` as
     `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY`. The script upgrades itself
     to full sync on the next run, no code change.

Locking: `tp7-import.sh` owns `/tmp/.music-tp7-pulling` (PID-stamped
single-flight; stale locks from crashed runs are detected via dead PID). The
watcher only clears it when the owner is dead. Manual + auto runs can't race.

## Voice memos → Obsidian (`music tp7 memos`, added 2026-07-28)

Transcribes voice memos out of the pulled pile into notes in the **main Obsidian
vault** (`…/Documents/ejfox/voicememos/`). Runs on already-pulled files — no
device needed.

    music tp7 memos [src-dir]        # default src: ~/tp7/latest/recordings
    music tp7 memos --redo <file>    # force re-transcribe one file

How it decides what's a memo: `tp7_analyze_audio` runs whisper (`ggml-base.en`)
on the first 30s — real words ⇒ memo, instrumental/silence ⇒ skipped as a jam.
Memos get a **full** transcript (whole file, 16k mono) and one note each:
frontmatter (`title/date/duration/audio/type: voicememo`) + a callout + the
transcript body. The `audio:` field links the wav; it is not embedded.

- **Idempotent ledger**: `~/.local/share/music-cli/memos-ledger.tsv`
  (`basename <TAB> speech|instrumental <TAB> notepath`). Every file is recorded
  once, so reruns are cheap and notes are never clobbered (colliding names get a
  `-2` suffix). Delete a line (or the file) to force reprocessing.
- **Known limits**: the 30s classifier window can miss a memo that starts with
  long silence, or false-positive a music track with an early vocal. Eyeball the
  notes; fix one with `--redo`.
- **zsh gotcha fixed 2026-07-28**: `tp7_analyze_audio` used bash `${var,,}`
  lowercasing, which is a hard error under this zsh script — it had been silently
  breaking whisper auto-naming in `music tp7 pull` too. Now `${(L)var}`.

## Device cleanup (`music tp7 clean`, added 2026-07-28)

Safe eraser for the TP-7 itself. **Never deletes anything not already backed up
in BOTH `~/tp7` (verified by byte size) AND R2.** Always prints a plan; the
`--go` path additionally requires typing `yes`.

    music tp7 clean               # dry-run: shows safe-to-delete vs KEPT (not backed up)
    music tp7 clean --go          # delete the verified-safe files (confirms first)
    music tp7 clean --go --limit 1  # delete at most N (cautious incremental cleaning)

**Hardware reality**: each libmtp op *captures* the TP-7's USB interface until
it's re-enumerated (replug / power-cycle into MTP mode). So `clean` touches the
device **at most once**: the plan is computed offline from `~/tp7/latest/recordings`
∩ R2 (a pulled file was on the device; if it's also in R2 it's safe to remove
there), and `--go` deletes the whole safe set in a **single**
`sudo -n tp7-root-mtp.sh del name…` → `mtp-delfile -f name…` call. The dry-run
never touches the device, so it doesn't burn the one claim. Local-only files
(e.g. jams >250MiB never pushed to R2) are **KEPT**. Finish the R2 write token
(see Post-pull pass) to make big files deletable.

`music setup` installs the third NOPASSWD sudoers line for `tp7-root-mtp.sh`;
without it `clean` refuses with "run: music setup".

## Debugging

- Human logs: `~/.local/share/music-cli/{watcher,import}.log` (auto-truncated at 1MB)
- Structured: `~/.local/share/usage-logs/music/YYYY-MM-DD.jsonl`
  (`device_seen`, `import_start`, `pull_start`, `pull_ok`, `pull_uptodate`, `pull_fail`)
- `sudo -n -l` must list both NOPASSWD entries, else the pipeline dies at
  `sudo -n` (reinstall via `music setup`)
- MTP mode = power off, hold STOP while powering on
- Field Kit holds the USB interface — scripts quit it before pulling
- **`LIBMTP PANIC: Unable to find interface & endpoints` / `NODEV`**: the first
  pull *captures* the USB interface (libusb whole-device capture on macOS); a
  second claim fails until the TP-7 is re-enumerated. Fix = unplug + power-cycle
  back into MTP mode before another `pull`/`ls`/`clean`.
- `sudo -n -l` should now list THREE NOPASSWD entries (detach-driver,
  root-pull.sh, root-mtp.sh). Missing the third ⇒ `clean` can't run; `music setup`.
