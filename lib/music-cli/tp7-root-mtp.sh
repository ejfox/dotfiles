#!/bin/zsh
# tp7-root-mtp.sh — run libmtp list/delete ops as root, with the same
# kernel-driver detach + ptpcamerad suppression as tp7-root-pull.sh.
# Invoked via `sudo -n` by `music tp7 clean`. NEVER deletes on its own —
# the caller decides which file IDs to pass and only after verifying backups.
#
#   sudo -n tp7-root-mtp.sh list            # mtp-files listing (all folders)
#   sudo -n tp7-root-mtp.sh del <id> [...]  # delete file(s) by libmtp File ID
#
# Why root: libusb kernel-driver detach on macOS is whole-device capture and
# requires root (same reason as tp7-root-pull.sh). Why the pkill loop:
# ptpcamerad continuously re-claims MTP/PTP devices and can't be disabled under
# SIP — suppress it for the duration (OpenMTP's approach). Loop self-terminates
# via the trap or after ~2 min.
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
SH=/Users/ejfox/.local/share/music-cli

( for i in $(seq 1 240); do pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null; sleep 0.5; done ) &
KP=$!
trap 'kill $KP 2>/dev/null' EXIT INT TERM   # never leak the suppressor
pkill -9 -x ptpcamerad 2>/dev/null; pkill -9 -f mscamerad 2>/dev/null
"$SH/tp7-detach-driver" >/dev/null 2>&1

case "${1:-}" in
  list)
    mtp-files
    ;;
  del)
    shift
    rc=0
    for id in "$@"; do
      mtp-delfile -n "$id" || rc=1
    done
    exit $rc
    ;;
  *)
    echo "usage: tp7-root-mtp.sh list | del <fileid>..." >&2
    exit 2
    ;;
esac
