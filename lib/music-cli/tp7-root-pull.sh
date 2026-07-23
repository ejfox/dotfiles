#!/bin/zsh
# Runs as root (NOPASSWD). macOS 15.7+ needs root for TP-7 USB. Emits progress on stdout.
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
SH=/Users/ejfox/.local/share/music-cli
DEST="${1:-/Users/ejfox/tp7/latest/recordings}"
mkdir -p "$DEST"
# keep macOS camera daemon out of the way for the whole pull (no driver re-yank)
( for i in $(seq 1 2400); do pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null; sleep 0.5; done ) &
KP=$!
pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null
"$SH/tp7-detach-driver" >/dev/null 2>&1
"$SH/tp7-pull" "$DEST"
rc=$?
kill $KP 2>/dev/null
chown -R ejfox:staff "$(dirname "$DEST")" 2>/dev/null
exit $rc
