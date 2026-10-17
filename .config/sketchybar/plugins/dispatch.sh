#!/bin/bash
# Dispatch widget: how many vault blog posts (edited in the last ~21 days)
# aren't on ejfox.com yet, checked against the site's RSS feed.
# Dispatch stopped writing its sketchybar cache (and dropped streaks) in
# 2026-10, so this widget no longer reads it. Click opens Dispatch.

. "$(dirname "$0")/_lib.sh"

if focus_active; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox/blog"
RSS_CACHE="/tmp/sketchybar-ejfox-rss.xml"

# Refresh the RSS copy at most every 15 minutes.
if [ ! -f "$RSS_CACHE" ] || [ $(( $(date +%s) - $(stat -f %m "$RSS_CACHE") )) -gt 900 ]; then
  curl -sfm 5 "https://ejfox.com/rss.xml" -o "$RSS_CACHE.tmp" && mv "$RSS_CACHE.tmp" "$RSS_CACHE"
fi

PUBLISHED=""
if [ -f "$RSS_CACHE" ]; then
  PUBLISHED=$(grep -oE '<link>https?://ejfox\.com/blog/[^<]+</link>' "$RSS_CACHE" \
    | sed -E 's|.*/blog/([^<]+)</link>|\1|' | sed -E 's|/$||' | sed -E 's|.*/||')
fi

PENDING=0
if [ -d "$VAULT" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    slug=$(basename "$f" .md)
    echo "$PUBLISHED" | grep -qFx "$slug" || PENDING=$((PENDING + 1))
  done < <(find "$VAULT" -name "*.md" -mtime -21 2>/dev/null)
fi

# Pending count in white; idle is muted with no label.
if [ "$PENDING" -gt 0 ]; then
  LABEL="$PENDING"
  COLOR="0xffffffff"
  ICON_COLOR="0xffffffff"
else
  LABEL=""
  COLOR="$DEFAULT"
  ICON_COLOR="$MUTED"
fi

sketchybar --set "$NAME" \
  drawing=on \
  label="$LABEL" \
  label.color="$COLOR" \
  icon.color="$ICON_COLOR" \
  click_script="open -a Dispatch"
