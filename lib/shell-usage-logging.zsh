# shell-usage-logging.zsh - Log shell activity for analysis
# Source this from .zshrc

USAGE_LOG_DIR="$HOME/.local/share/usage-logs/shell"
mkdir -p "$USAGE_LOG_DIR"

_usage_log_shell() {
  local evt="$1"
  shift
  local log_file="$USAGE_LOG_DIR/$(date +%Y-%m-%d).jsonl"
  local ts=$(date -Iseconds)

  # Build JSON
  local json="{\"ts\":\"$ts\",\"src\":\"shell\",\"evt\":\"$evt\""
  for arg in "$@"; do
    local key="${arg%%=*}"
    local val="${arg#*=}"
    # Escape quotes and newlines
    val="${val//\\/\\\\}"
    val="${val//\"/\\\"}"
    val="${val//$'\n'/\\n}"
    json="$json,\"$key\":\"$val\""
  done
  json="$json}"

  # Async write
  echo "$json" >> "$log_file" &!
}

# Track command start time
_usage_cmd_start=0
_usage_last_cmd=""

# preexec - runs before each command
_usage_preexec() {
  _usage_cmd_start=$EPOCHSECONDS
  _usage_last_cmd="$1"

  # Log command start
  _usage_log_shell "cmd_start" \
    "cmd=$1" \
    "cwd=$PWD" \
    "tty=$TTY"
}

# precmd - runs before prompt (after command completes)
_usage_precmd() {
  local exit_code=$?
  local duration=0

  if [[ $_usage_cmd_start -gt 0 ]]; then
    duration=$((EPOCHSECONDS - _usage_cmd_start))

    # Log command completion
    _usage_log_shell "cmd_end" \
      "cmd=$_usage_last_cmd" \
      "exit=$exit_code" \
      "duration=$duration" \
      "cwd=$PWD"
  fi

  _usage_cmd_start=0
}

# Directory changes
_usage_chpwd() {
  _usage_log_shell "cd" \
    "to=$PWD" \
    "from=$OLDPWD"
}

# Register hooks
autoload -Uz add-zsh-hook
add-zsh-hook preexec _usage_preexec
add-zsh-hook precmd _usage_precmd
add-zsh-hook chpwd _usage_chpwd

# Log shell session start
_usage_log_shell "session_start" \
  "shell=$SHELL" \
  "term=$TERM" \
  "pid=$$" \
  "cwd=$PWD"

# Log shell session end on exit
zshexit() {
  _usage_log_shell "session_end" "pid=$$"
}
