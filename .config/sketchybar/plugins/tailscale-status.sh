#!/bin/bash
# Tailscale status indicator for sketchybar
# Shows single character: 🔗 connected, ○ offline, ⚠ error

# Get Tailscale status without blocking (0.2s timeout)
TAILSCALE_STATUS=$(timeout 0.2 /opt/homebrew/bin/tailscale status --json 2>/dev/null | jq -r '.Self.Online // "unknown"' 2>/dev/null)

# Determine icon and color
case "$TAILSCALE_STATUS" in
  true)
    ICON="🔗"
    COLOR="0xff4da6a4"  # Teal - connected
    LABEL="Connected"
    ;;
  false)
    ICON="○"
    COLOR="0xff999999"  # Gray - disconnected
    LABEL="Offline"
    ;;
  *)
    ICON="⚠"
    COLOR="0xffff8c42"  # Orange - error/unknown
    LABEL="Unknown"
    ;;
esac

# Update sketchybar item
sketchybar --set $NAME label="$ICON" color="$COLOR" tooltip="Tailscale: $LABEL"
