# music-cli TP-7 pipeline (mirror)

LIVE copies run from `~/.local/share/music-cli/` — these are tracked mirrors so
the pipeline survives a disk loss. If you edit here, copy to the live location
(or vice versa). The `tp7-pull` (libmtp) and `tp7-detach-driver` (libusb)
binaries are built by `music setup` and are not mirrored.

## Flow

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

## Debugging

- Human logs: `~/.local/share/music-cli/{watcher,import}.log` (auto-truncated at 1MB)
- Structured: `~/.local/share/usage-logs/music/YYYY-MM-DD.jsonl`
  (`device_seen`, `import_start`, `pull_start`, `pull_ok`, `pull_uptodate`, `pull_fail`)
- `sudo -n -l` must list both NOPASSWD entries, else the pipeline dies at
  `sudo -n` (reinstall via `music setup`)
- MTP mode = power off, hold STOP while powering on
- Field Kit holds the USB interface — scripts quit it before pulling
