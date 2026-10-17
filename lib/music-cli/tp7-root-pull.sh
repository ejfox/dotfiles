#!/bin/zsh
# Runs as root (NOPASSWD via /etc/sudoers.d/tp7-detach). Emits progress on stdout.
#   tp7-root-pull.sh [DEST] [--list]
#
# Why root: libusb kernel-driver detach on macOS is whole-device "capture" and
# requires root (the com.apple.vm.device-access entitlement is unavailable to
# CLI tools) — see libusb PR #911 / issue #1014.
# Why the pkill loop: ptpcamerad re-claims PTP/MTP devices continuously and
# cannot be persistently disabled on modern macOS (SIP). Suppressing it for the
# duration of the transfer is the community-standard workaround (same approach
# as OpenMTP). Scoped to the pull itself: it runs exactly as long as tp7-pull does
# (it used to be a fixed 20 min, so long pulls lost the device mid-transfer).
# Watchdog: a hung libmtp read could hold the device and the import lock forever, so the pull gets 3 hours max.
# Ownership: tp7-pull fchown()s each file to DEST's owner itself (no more recursive chown of all of ~/tp7).
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
SH=/Users/ejfox/.local/share/music-cli
DEST="${1:-/Users/ejfox/tp7/latest/recordings}"
MODE="${2:-}"
[[ -n "$MODE" && "$MODE" != "--list" ]] && { echo "usage: tp7-root-pull.sh [DEST] [--list]" >&2; exit 2; }
mkdir -p "$DEST" && chown ejfox:staff "$DEST" 2>/dev/null

pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null
"$SH/tp7-detach-driver" >/dev/null 2>&1

timeout 3h "$SH/tp7-pull" "$DEST" ${MODE:+"$MODE"} &
PULL=$!
( while kill -0 $PULL 2>/dev/null; do pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null; sleep 0.5; done ) &
KP=$!
trap 'kill $PULL $KP 2>/dev/null' INT TERM   # never leak the pull or the suppressor
wait $PULL; rc=$?
kill $KP 2>/dev/null
[[ $rc -eq 124 ]] && echo "STOP timeout: pull ran over 3 hours"
exit $rc
