#!/usr/bin/env bash
# flash-lib.sh — shared helpers for the desk-event flash system.
# Source it (don't execute):  . "$HOME/.dotfiles/lib/flash-lib.sh"
#
# Single source of truth for the grammar is lib/desk-flash-patterns.json; every
# consumer (desk-event caption, flash-toast banner, rgb-flash colors) reads it
# through these accessors instead of hardcoding colors/labels/emoji.

FLASH_GRAMMAR="${FLASH_GRAMMAR:-$HOME/.dotfiles/lib/desk-flash-patterns.json}"
FLASH_REST_COLOR="pink"   # resting palette key, mirrors the JSON "rest" field

# --- grammar accessors ------------------------------------------------------

# grammar_field <event> <field> → the field's value, or "" if absent.
grammar_field() {
  jq -r --arg e "$1" --arg f "$2" '.events[$e][$f] // empty' "$FLASH_GRAMMAR" 2>/dev/null
}

grammar_color() { grammar_field "$1" color; }   # palette key, e.g. "yellow"
grammar_label() { grammar_field "$1" label; }   # human label, e.g. "COME HERE !!!"
grammar_emoji() { grammar_field "$1" emoji; }   # status dot, e.g. "🟡"

# palette_rgb <color-name> → "R G B" (space-separated); falls back to pink.
palette_rgb() {
  jq -r --arg c "$1" \
    '(.palette[$c] // [230,0,103]) | "\(.[0]) \(.[1]) \(.[2])"' \
    "$FLASH_GRAMMAR" 2>/dev/null || echo "230 0 103"
}

# grammar_rgb_query <event> → "r=R&g=G&b=B" for the pixel/http API (falls back pink).
grammar_rgb_query() {
  local name rgb
  name=$(grammar_color "$1"); [ -n "$name" ] || name="$FLASH_REST_COLOR"
  read -r r g b <<<"$(palette_rgb "$name")"
  printf 'r=%s&g=%s&b=%s' "${r:-230}" "${g:-0}" "${b:-103}"
}

# --- Hue bridge (LAN) helpers ----------------------------------------------

# hue_bridge_ip → the bridge IP from ~/.env, without sourcing the whole file.
hue_bridge_ip() {
  grep -m1 'HUE_BRIDGE_IP=' "$HOME/.env" 2>/dev/null \
    | sed 's/.*HUE_BRIDGE_IP=//; s/["'\'' ]//g'
}

# hue_bridge_reachable [ip] → 0 if the bridge answers on :443 (LAN up), else 1.
# Used to tell whether a flash actually had a chance to reach the bulbs.
hue_bridge_reachable() {
  local ip; ip="${1:-$(hue_bridge_ip)}"
  [ -n "$ip" ] && nc -z -G 1 -w 1 "$ip" 443 >/dev/null 2>&1
}
