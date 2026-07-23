# music-cli TP-7 pipeline (mirror)

LIVE copies run from `~/.local/share/music-cli/` — these are tracked mirrors so
the pipeline survives a disk loss. If you edit here, copy to the live location
(or vice versa). The `tp7-pull` and `tp7-detach-driver` binaries are built by
`music setup` and are not mirrored.

Flow: launchd (10s ioreg poll) → tp7-mount-handler.sh → tp7-import.sh
→ sudo tp7-root-pull.sh (detach driver + libmtp pull) → ~/tp7/latest/recordings
Structured events land in ~/.local/share/usage-logs/music/YYYY-MM-DD.jsonl
