#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# MYSTICAL SYMBOLS LIBRARY - Moon phases, I Ching, cosmic glyphs
# Source this from sketchybar, tmux, p10k, startup scripts, etc.
# ═══════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────────────────
# MOON PHASES - Based on actual lunar cycle
# ─────────────────────────────────────────────────────────────────────────────

# Moon phase icons (nerdfont)
MOON_NEW="󰽤"
MOON_WAXING_CRESCENT="󰽥"
MOON_FIRST_QUARTER="󰽦"
MOON_WAXING_GIBBOUS="󰽧"
MOON_FULL="󰽨"
MOON_WANING_GIBBOUS="󰽩"
MOON_LAST_QUARTER="󰽪"
MOON_WANING_CRESCENT="󰽫"

# Alternative Unicode moons (more widely supported)
MOON_PHASES_UNICODE=("🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘")

get_moon_phase() {
  # Calculate moon phase (0-7) based on synodic month
  # Known new moon: Jan 11, 2024 (reference point)
  local ref_new_moon=1704931200  # Unix timestamp for Jan 11, 2024
  local synodic_month=2551443    # ~29.53 days in seconds
  local now=$(date +%s)
  local days_since=$(( (now - ref_new_moon) % synodic_month ))
  local phase=$(( days_since * 8 / synodic_month ))
  echo $phase
}

get_moon_icon() {
  local phase=$(get_moon_phase)
  local icons=("$MOON_NEW" "$MOON_WAXING_CRESCENT" "$MOON_FIRST_QUARTER" "$MOON_WAXING_GIBBOUS" "$MOON_FULL" "$MOON_WANING_GIBBOUS" "$MOON_LAST_QUARTER" "$MOON_WANING_CRESCENT")
  echo "${icons[$phase]}"
}

get_moon_name() {
  local phase=$(get_moon_phase)
  local names=("new" "waxing crescent" "first quarter" "waxing gibbous" "full" "waning gibbous" "last quarter" "waning crescent")
  echo "${names[$phase]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# I CHING HEXAGRAMS - All 64 with meanings
# ─────────────────────────────────────────────────────────────────────────────

# The 64 hexagrams (Unicode U+4DC0 to U+4DFF)
HEXAGRAMS=(
  "䷀" "䷁" "䷂" "䷃" "䷄" "䷅" "䷆" "䷇"
  "䷈" "䷉" "䷊" "䷋" "䷌" "䷍" "䷎" "䷏"
  "䷐" "䷑" "䷒" "䷓" "䷔" "䷕" "䷖" "䷗"
  "䷘" "䷙" "䷚" "䷛" "䷜" "䷝" "䷞" "䷟"
  "䷠" "䷡" "䷢" "䷣" "䷤" "䷥" "䷦" "䷧"
  "䷨" "䷩" "䷪" "䷫" "䷬" "䷭" "䷮" "䷯"
  "䷰" "䷱" "䷲" "䷳" "䷴" "䷵" "䷶" "䷷"
  "䷸" "䷹" "䷺" "䷻" "䷼" "䷽" "䷾" "䷿"
)

# Names of the 64 hexagrams
HEXAGRAM_NAMES=(
  "Creative" "Receptive" "Difficulty" "Youthful Folly" "Waiting" "Conflict" "Army" "Holding Together"
  "Small Taming" "Treading" "Peace" "Standstill" "Fellowship" "Great Possession" "Modesty" "Enthusiasm"
  "Following" "Work on Decay" "Approach" "Contemplation" "Biting Through" "Grace" "Splitting Apart" "Return"
  "Innocence" "Great Taming" "Nourishment" "Great Exceeding" "Abysmal" "Clinging" "Influence" "Duration"
  "Retreat" "Great Power" "Progress" "Darkening Light" "The Family" "Opposition" "Obstruction" "Deliverance"
  "Decrease" "Increase" "Breakthrough" "Coming to Meet" "Gathering" "Pushing Upward" "Oppression" "The Well"
  "Revolution" "The Cauldron" "Arousing" "Keeping Still" "Development" "Marrying Maiden" "Abundance" "Wanderer"
  "Gentle" "Joyous" "Dispersion" "Limitation" "Inner Truth" "Small Exceeding" "After Completion" "Before Completion"
)

# Short wisdom for each hexagram (for display)
HEXAGRAM_WISDOM=(
  "Creative force flows" "Receptive earth yields" "Persist through difficulty" "Learn with humility"
  "Wait with patience" "Avoid conflict" "Organize resources" "Unite with others"
  "Small steps forward" "Tread carefully" "Harmony prevails" "Withdraw and wait"
  "Seek community" "Abundance comes" "Stay humble" "Share enthusiasm"
  "Adapt and follow" "Repair what's broken" "Approach gently" "Observe deeply"
  "Cut through obstacles" "Cultivate beauty" "Let go gracefully" "Begin again"
  "Act without expectation" "Restrain great power" "Nourish carefully" "Support excess"
  "Navigate darkness" "Attach to clarity" "Open to influence" "Commit fully"
  "Retreat strategically" "Use strength wisely" "Advance steadily" "Protect inner light"
  "Nurture bonds" "Bridge differences" "Find another way" "Remove blockages"
  "Sacrifice wisely" "Accept blessings" "Break through now" "Handle with care"
  "Come together" "Rise gradually" "Endure hardship" "Draw from depths"
  "Transform completely" "Refine and perfect" "Move with thunder" "Be still as mountain"
  "Develop gradually" "Accept transitions" "Shine brightly" "Journey onward"
  "Penetrate gently" "Express joy" "Scatter and renew" "Set boundaries"
  "Trust your center" "Small exceeds great" "Completion nears" "Almost there"
)

get_daily_hexagram_index() {
  # Deterministic hexagram based on date (changes daily)
  local day_seed=$(date +%Y%m%d)
  echo $(( day_seed % 64 ))
}

get_daily_hexagram() {
  local idx=$(get_daily_hexagram_index)
  echo "${HEXAGRAMS[$idx]}"
}

get_daily_hexagram_name() {
  local idx=$(get_daily_hexagram_index)
  echo "${HEXAGRAM_NAMES[$idx]}"
}

get_daily_hexagram_wisdom() {
  local idx=$(get_daily_hexagram_index)
  echo "${HEXAGRAM_WISDOM[$idx]}"
}

get_random_hexagram() {
  local idx=$((RANDOM % 64))
  echo "${HEXAGRAMS[$idx]}"
}

# Get hexagram based on a seed (useful for consistent per-context hexagrams)
get_seeded_hexagram() {
  local seed=$1
  local hash=$(echo -n "$seed" | md5 | cut -c1-8)
  local idx=$((16#$hash % 64))
  echo "${HEXAGRAMS[$idx]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# TRIGRAMS - The 8 building blocks of hexagrams
# ─────────────────────────────────────────────────────────────────────────────

TRIGRAMS=("☰" "☱" "☲" "☳" "☴" "☵" "☶" "☷")
TRIGRAM_NAMES=("Heaven" "Lake" "Fire" "Thunder" "Wind" "Water" "Mountain" "Earth")
TRIGRAM_ATTRS=("creative" "joyous" "clinging" "arousing" "gentle" "abysmal" "still" "receptive")

# ─────────────────────────────────────────────────────────────────────────────
# PLANETARY HOURS - Traditional astrological timing
# ─────────────────────────────────────────────────────────────────────────────

PLANETS=("☉" "☽" "♂" "☿" "♃" "♀" "♄")  # Sun Moon Mars Mercury Jupiter Venus Saturn
PLANET_NAMES=("Sol" "Luna" "Mars" "Mercury" "Jupiter" "Venus" "Saturn")

get_planetary_hour() {
  # Simplified: each hour ruled by a planet in sequence
  local hour=$(date +%H)
  local day=$(date +%u)  # 1=Monday, 7=Sunday
  # Day rulers: Sun=1, Moon=2, Mars=3, Mercury=4, Jupiter=5, Venus=6, Saturn=7
  local day_ruler=$(( (day % 7) ))
  local hour_offset=$(( hour % 7 ))
  local planet_idx=$(( (day_ruler + hour_offset) % 7 ))
  echo "${PLANETS[$planet_idx]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# WEATHER SYMBOLS - Nerdfont weather icons
# ─────────────────────────────────────────────────────────────────────────────

WEATHER_CLEAR=""
WEATHER_CLOUDY="󰖐"
WEATHER_RAIN=""
WEATHER_STORM="󰼱"
WEATHER_SNOW=""
WEATHER_FOG=""
WEATHER_WIND="󰖒"

# ─────────────────────────────────────────────────────────────────────────────
# ENERGY/SIGNAL SETS - For visualizing levels
# ─────────────────────────────────────────────────────────────────────────────

# Signal strength (5 levels)
SIGNAL=("󰤭" "󰤟" "󰤢" "󰤥" "󰤨")

# Battery states
BATTERY_STATES=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

# Circle fill (5 levels)
CIRCLE_FILL=("󰪥" "󰪡" "󰪢" "󰪣" "󰪤")

# Hourglass states
HOURGLASS=("󱎫" "󱎬" "󱎭")

# Dice
DICE=("󰊱" "󰊲" "󰊳" "󰊴" "󰊵" "󰊶")

get_signal_icon() {
  local level=$1  # 0-100
  local idx=$(( level / 25 ))
  [ $idx -gt 4 ] && idx=4
  echo "${SIGNAL[$idx]}"
}

get_circle_fill() {
  local level=$1  # 0-100
  local idx=$(( level / 25 ))
  [ $idx -gt 4 ] && idx=4
  echo "${CIRCLE_FILL[$idx]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# TIME OF DAY - Contextual symbols
# ─────────────────────────────────────────────────────────────────────────────

get_time_of_day_icon() {
  local hour=$(date +%H)
  if [ $hour -ge 5 ] && [ $hour -lt 7 ]; then
    echo "󰇊"  # sunrise
  elif [ $hour -ge 7 ] && [ $hour -lt 12 ]; then
    echo ""   # morning sun
  elif [ $hour -ge 12 ] && [ $hour -lt 17 ]; then
    echo ""   # afternoon sun
  elif [ $hour -ge 17 ] && [ $hour -lt 20 ]; then
    echo "󰇈"  # sunset
  elif [ $hour -ge 20 ] && [ $hour -lt 23 ]; then
    echo "󰽥"  # evening moon
  else
    echo "󰽤"  # night (new moon)
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# COSMIC GLYPHS - Aesthetic symbols
# ─────────────────────────────────────────────────────────────────────────────

COSMIC_STAR=""
COSMIC_GALAXY="󱩡"
COSMIC_COMET="󱁊"
COSMIC_SATURN="󰇧"
COSMIC_ORBIT="󰽑"
COSMIC_BLACK_HOLE=""

# ─────────────────────────────────────────────────────────────────────────────
# CARD SUITS - For randomization/decoration
# ─────────────────────────────────────────────────────────────────────────────

SUITS=("󰣎" "󰣏" "󰣑" "󰣐")  # hearts diamonds clubs spades

# ─────────────────────────────────────────────────────────────────────────────
# GEOMETRIC PROGRESSION
# ─────────────────────────────────────────────────────────────────────────────

SHAPES=("󰝤" "󰝣" "󰝥" "󰝦" "󰝧")  # triangle square pentagon hexagon octagon

# ─────────────────────────────────────────────────────────────────────────────
# ALCHEMICAL / MYSTICAL
# ─────────────────────────────────────────────────────────────────────────────

ALCHEMY_PENTAGRAM="󱢅"
ALCHEMY_INFINITY="󰫃"
ALCHEMY_OMEGA="󱗝"
ALCHEMY_EYE="󰻀"
ALCHEMY_ANKH="󰠥"
ALCHEMY_TRIFORCE="󱀝"
ALCHEMY_YIN_YANG="󰴈"

# ─────────────────────────────────────────────────────────────────────────────
# QUICK ONE-LINER EXPORTS
# ─────────────────────────────────────────────────────────────────────────────

# For embedding in prompts/status bars
mystical_status() {
  echo "$(get_moon_icon) $(get_daily_hexagram) $(get_time_of_day_icon)"
}

# Full mystical context
mystical_context() {
  local moon=$(get_moon_icon)
  local phase=$(get_moon_name)
  local hex=$(get_daily_hexagram)
  local hex_name=$(get_daily_hexagram_name)
  local wisdom=$(get_daily_hexagram_wisdom)
  local planet=$(get_planetary_hour)

  echo "$moon $phase | $hex $hex_name | $planet planetary hour"
  echo "  → $wisdom"
}
