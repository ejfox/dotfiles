#!/bin/zsh
# Runs as root (NOPASSWD via /etc/sudoers.d/tp7-detach). Emits progress on stdout.
#
# Why root: libusb kernel-driver detach on macOS is whole-device "capture" and
# requires root (the com.apple.vm.device-access entitlement is unavailable to
# CLI tools) — see libusb PR #911 / issue #1014.
# Why the pkill loop: ptpcamerad re-claims PTP/MTP devices continuously and
# cannot be persistently disabled on modern macOS (SIP). Suppressing it for the
# duration of the transfer is the community-standard workaround (same approach
# as OpenMTP). Scoped: loop dies with this script (trap) or after 20 min max.
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
SH=/Users/ejfox/.local/share/music-cli
DEST="${1:-/Users/ejfox/tp7/latest/recordings}"
mkdir -p "$DEST"
( for i in $(seq 1 2400); do pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null; sleep 0.5; done ) &
KP=$!
trap 'kill $KP 2>/dev/null' EXIT INT TERM   # never leak the suppressor, even on SIGKILL of tp7-pull
pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null
"$SH/tp7-detach-driver" >/dev/null 2>&1
"$SH/tp7-pull" "$DEST"
rc=$?
chown -R ejfox:staff "$(dirname "$DEST")" 2>/dev/null
exit $rc
