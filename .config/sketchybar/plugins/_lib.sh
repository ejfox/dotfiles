#!/bin/bash
# Shared helpers for sketchybar creative widgets.
# Source this from plugins: . "$(dirname "$0")/_lib.sh"

MUTED="0xff666666"
DIM="0xff444444"
DEFAULT="0xff888888"

# Returns 0 if any macOS Focus mode is active, 1 otherwise.
focus_active() {
  local f="$HOME/Library/DoNotDisturb/DB/Assertions.json"
  [ ! -f "$f" ] && return 1
  local n
  n=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(len(d['data'][0].get('storeAssertionRecords',[])))" "$f" 2>/dev/null)
  [ -n "$n" ] && [ "$n" -gt 0 ]
}

# Start-of-current-week (Monday 00:00 local) in unix seconds.
week_start_monday() {
  local now midnight dow
  now=$(date +%s)
  midnight=$(date -j -v0H -v0M -v0S +%s)
  dow=$(date +%u)                                       # 1=Mon..7=Sun
  echo $(( midnight - (dow - 1) * 86400 ))
}

# bucket_for <ts> <week_start> → 0 (this week) .. 3 (3 weeks ago), -1 older.
bucket_for() {
  local ts=$1 ws=$2 diff
  if [ "$ts" -ge "$ws" ]; then echo 0; return; fi
  diff=$(( ws - ts ))
  if   [ $diff -lt 604800 ];  then echo 1
  elif [ $diff -lt 1209600 ]; then echo 2
  elif [ $diff -lt 1814400 ]; then echo 3
  else echo -1
  fi
}

# render_matrix <w0> <w1> <w2> <w3> <latest_ts>
# Emits "<4-char matrix>[ drought Nd|Nw|Nmo]" — caller sets the icon slot.
# w0 = current week (rightmost), w3 = 3 weeks ago (leftmost).
render_matrix() {
  local w0=$1 w1=$2 w2=$3 w3=$4 latest=$5
  local d0 d1 d2 d3
  d0=$([ "$w0" = "1" ] && echo "●" || echo "○")   # current week: outline when empty (the nudge)
  d1=$([ "$w1" = "1" ] && echo "●" || echo " ")   # past weeks: whitespace for absence
  d2=$([ "$w2" = "1" ] && echo "●" || echo " ")
  d3=$([ "$w3" = "1" ] && echo "●" || echo " ")
  local filled=$((w0 + w1 + w2 + w3))
  local suffix=""
  if [ "$filled" -le 1 ] && [ -n "$latest" ] && [ "$latest" -gt 0 ]; then
    local age_days=$(( ($(date +%s) - latest) / 86400 ))
    if   [ "$age_days" -lt 14 ]; then suffix=" ${age_days}d"
    elif [ "$age_days" -lt 365 ]; then suffix=" $((age_days / 7))w"
    else suffix=" $((age_days / 30))mo"
    fi
  fi
  echo "${d3}${d2}${d1}${d0}${suffix}"
}
