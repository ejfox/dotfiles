#!/bin/bash
# Dispatch widget: rendered from a local JSON cache that Dispatch writes
# on every vault scan / publish / unpublish (~/Library/Caches/com.ejfox.dispatch/sketchybar.json).
#
# Renders:
#   - Pending count (drafts modified in last ~21d)
#   - Streak chip (🔥Nd) when active
#   - Red dot when there are LIVE posts modified-since-publish
#
# Falls back to RSS-based heuristic when the cache is missing (e.g. fresh
# install where Dispatch hasn't run yet). Click opens Dispatch.

. "$(dirname "$0")/_lib.sh"

if focus_active; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

CACHE="$HOME/Library/Caches/com.ejfox.dispatch/sketchybar.json"

PENDING=0
STREAK=0
HAS_MODIFIED=0
USED_CACHE=0

if [ -f "$CACHE" ]; then
  # Cheap JSON read via python (system python3, no deps).
  read -r PENDING STREAK HAS_MODIFIED < <(python3 -c "
import json, sys
try:
    d = json.load(open('$CACHE'))
    print(d.get('pending', 0), d.get('streak_days', 0), int(bool(d.get('has_modified', False))))
except Exception:
    print(0, 0, 0)
" 2>/dev/null)
  USED_CACHE=1
fi

# --- Fallback path: same RSS-vs-vault dance as before, used when Dispatch
# hasn't written the cache yet. Kept intact so the widget never goes blank
# during a fresh install.
if [ "$USED_CACHE" = "0" ]; then
  VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox/blog"
  RSS_CACHE="/tmp/sketchybar-ejfox-rss.xml"
  if [ ! -f "$RSS_CACHE" ] || [ $(( $(date +%s) - $(stat -f %m "$RSS_CACHE") )) -gt 900 ]; then
    curl -sfm 5 "https://ejfox.com/rss.xml" -o "$RSS_CACHE.tmp" && mv "$RSS_CACHE.tmp" "$RSS_CACHE"
  fi
  PUBLISHED=""
  if [ -f "$RSS_CACHE" ]; then
    PUBLISHED=$(grep -oE '<link>https?://ejfox\.com/blog/[^<]+</link>' "$RSS_CACHE" \
      | sed -E 's|.*/blog/([^<]+)</link>|\1|' | sed -E 's|/$||')
  fi
  if [ -d "$VAULT" ]; then
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      slug=$(basename "$f" .md)
      echo "$PUBLISHED" | grep -qFx "$slug" || PENDING=$((PENDING + 1))
    done < <(find "$VAULT" -name "*.md" -mtime -21 2>/dev/null)
  fi
fi

# --- Compose label.
# Format: "5  🔥3d" or "🔥3d" (no pending) or "5" (no streak) or "" (idle).
LABEL=""
[ "$PENDING" -gt 0 ] && LABEL="$PENDING"
if [ "$STREAK" -gt 0 ]; then
  STREAK_CHIP="🔥${STREAK}d"
  if [ -n "$LABEL" ]; then
    LABEL="${LABEL}  ${STREAK_CHIP}"
  else
    LABEL="$STREAK_CHIP"
  fi
fi

# --- Color logic.
# Modified-since-publish overrides everything → amber icon. Pending → white.
# Idle (no pending, no modified, no streak) → muted gray.
if [ "$HAS_MODIFIED" = "1" ]; then
  ICON_COLOR="0xffff9f0a"   # macOS systemOrange — gentle "you have stale live posts"
  COLOR="0xffff9f0a"
elif [ "$PENDING" -gt 0 ] || [ "$STREAK" -gt 0 ]; then
  ICON_COLOR="0xffffffff"
  COLOR="0xffffffff"
else
  ICON_COLOR="$MUTED"
  COLOR="$DEFAULT"
fi

sketchybar --set "$NAME" \
  drawing=on \
  label="$LABEL" \
  label.color="$COLOR" \
  icon.color="$ICON_COLOR" \
  click_script="open -a Dispatch"
