#!/bin/bash
# Blog posts widget: 4-week dot matrix from ejfox.com/rss.xml pubDates.
# Hidden when any macOS Focus mode is active. RSS cached 15min.

. "$(dirname "$0")/_lib.sh"

if focus_active; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

CACHE="/tmp/sketchybar-ejfox-rss.xml"
CACHE_TTL=900   # 15 minutes

if [ ! -f "$CACHE" ] || [ $(( $(date +%s) - $(stat -f %m "$CACHE") )) -gt $CACHE_TTL ]; then
  curl -sfm 5 "https://ejfox.com/rss.xml" -o "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
fi

WS=$(week_start_monday)
W0=0; W1=0; W2=0; W3=0
LATEST=0

if [ -f "$CACHE" ]; then
  while IFS= read -r line; do
    # line looks like: <pubDate>Sun, 25 Jan 2026 16:20:39 GMT</pubDate>
    date_str=$(echo "$line" | sed -E 's|.*<pubDate>([^<]+)</pubDate>.*|\1|')
    [ -z "$date_str" ] && continue
    ts=$(date -j -f "%a, %d %b %Y %H:%M:%S %Z" "$date_str" +%s 2>/dev/null)
    [ -z "$ts" ] && continue
    [ "$ts" -gt "$LATEST" ] && LATEST=$ts
    b=$(bucket_for "$ts" "$WS")
    case "$b" in
      0) W0=1 ;;
      1) W1=1 ;;
      2) W2=1 ;;
      3) W3=1 ;;
    esac
  done < <(grep -o '<pubDate>[^<]*</pubDate>' "$CACHE" | tail -n +2)
  # tail -n +2 skips the channel-level pubDate, keeping only item pubDates.
fi

LABEL=$(render_matrix "$W0" "$W1" "$W2" "$W3" "$LATEST")

sketchybar --set "$NAME" \
  drawing=on \
  label="$LABEL" \
  label.color="$DEFAULT" \
  click_script="open ~/code/blog"
