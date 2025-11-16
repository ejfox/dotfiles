# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

alias \?\?="gh copilot suggest $0"

# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# custom startup script
# [ -f ~/.startup.sh ] && source ~/.startup.sh

# Cache the startup script output to improve terminal startup speed

# Path to the cache file
CACHE_FILE="$HOME/.cache/startup_script_cache"
CACHE_DURATION=10800  # 3 hours in seconds

# Function to get the last modification time of the cache file (works on macOS and Linux)
function get_cache_mod_time {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    stat -f "%m" "$CACHE_FILE"  # For macOS
  else
    stat -c "%Y" "$CACHE_FILE"  # For Linux
  fi
}

# Function to run the startup script and cache the output
function run_startup_script {
  current_time=$(date +%s)
  if [ -f "$CACHE_FILE" ]; then
    cache_mod_time=$(get_cache_mod_time)
    if (( current_time - cache_mod_time < CACHE_DURATION )); then
      cat "$CACHE_FILE"
      return
    fi
  fi
  # If cache is missing or outdated, run the startup script and cache the output
  ~/.startup.sh > "$CACHE_FILE"
  cat "$CACHE_FILE"
}

# Display cached or freshly generated MOTD
run_startup_script

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Speed optimizations for Oh My Zsh
ZSH_DISABLE_COMPFIX=true  # Skip security checks
DISABLE_UPDATE_PROMPT=true  # Don't ask about updates

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="pygmalion"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files under VCS as dirty.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(git zsh-autosuggestions zsh-lux)

# Skip global compinit for faster loading (OMZ will handle it)
skip_global_compinit=1

source $ZSH/oh-my-zsh.sh

# Better completion configuration
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# User configuration

# Standard zsh history settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.

# NVM configuration - initialize for p10k prompt detection
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Terminal settings
export TERM="xterm-256color"
export COLORTERM="truecolor"
touch ~/.hushlogin
export MAILCHECK=0


source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Initialize theme based on system appearance (powered by zsh-lux)
if macos_is_dark; then
  theme-dark
else
  theme-light
fi

# Smart git commit with LLM integration
alias commit='git add -A && diff_output=$(git diff --cached) && if [ ${#diff_output} -gt 100000 ]; then commit_msg=$(echo -e "$(git diff --name-only)\n\n$(echo "$diff_output" | head -c 1024)" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) The git diff is too large to process fully. Based on the list of changed files and the first part of the diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); else commit_msg=$(echo "$diff_output" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) Based on the following git diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); fi && selected_msg=$(echo "$commit_msg" | fzf --prompt="Select a commit message:") && git commit -m "$selected_msg"'

# Custom aliases and commands
# Override Oh My Zsh ls aliases with lsd
alias l='lsd -lah'
alias la='lsd -lAh'
alias ll='lsd -lht'
alias ls='lsd -G'
alias lsa='lsd -lah'

# Nvim aliases - fuzzy finding and searching
alias v='nvim'
alias n='nvim .'
alias vs='nvim $(fzf --preview "bat --color=always --style=numbers {}" --preview-window=right:60%:wrap)'
alias vg='nvim $(rg --line-number --no-heading --color=always . | fzf --ansi --preview "echo {} | cut -d: -f1,2 | xargs -I {} sh -c \"bat --color=always --highlight-line \$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)\"" --delimiter ":" --preview-window=right:60%:wrap | cut -d: -f1)'

alias dev="yarn dev"
alias yarni="yarn install"
alias nodei="node index.js"
alias c="clear && refresh"
alias yd="yarn dev"
alias pbp="pbpaste"
alias pbc="pbcopy"
alias pbjson="pbpaste | jsonfui"
alias catcopy="cat | pbcopy"
alias jcurl="curl -s \"$1\" | jsonfui"
alias tmuxkill="tmux kill-server"
alias tmuxnew="tmux new -s"
alias showcase="open \"https://ejfox-codeshowcase.web.val.run/?code=$(pbpaste | jq -sRr @uri)\""
alias obsidian="cd /Users/ejfox/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox"
alias pico8="/Applications/PICO-8.app/Contents/MacOS/pico8"
alias nukeyarn="rm yarn.lock;rm -rf node_modules"
alias ghpub='gh repo create $1 --public --source=. --remote=origin --push'
alias sshvps='ssh -i ~/.ssh/2024-mbp.pem debian@208.113.130.118'
alias sshsmallweb='ssh -i ~/.ssh/2024-mbp.pem smallweb@208.113.130.118'
alias newsketch='
  ART_DIR=~/art
  TODAY=$(date +"%m-%d")
  INDEX=$(ls $ART_DIR | grep $TODAY | awk -F"[-.]" "{print \$3}" | sort -n | tail -n 1)
  if [ -z "$INDEX" ]; then
    INDEX=1
  else
    INDEX=$((INDEX+1))
  fi
  SKETCH_FILE="$TODAY-$INDEX.js"
  cp $ART_DIR/template/default-sketch.js $ART_DIR/$SKETCH_FILE
  echo "Created $ART_DIR/$SKETCH_FILE"
  cd $ART_DIR
  npx canvas-sketch-cli $SKETCH_FILE --open &
  code $ART_DIR/art.code-workspace
'

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
. "/Users/ejfox/.deno/env"
# Load environment variables from ~/.env (not committed to git)
[ -f ~/.env ] && source ~/.env

scraps() {
  local limit=${1:-10}     # Default to 10 rows
  local filter=${2:-""}    # Optional filter, e.g., "type=eq.note"

  curl -s "$PERSONAL_SUPABASE_URL/rest/v1/scraps?select=id,content,summary,created_at,updated_at,tags,relationships,metadata,scrap_id,graph_imported,url,screenshot_url,location,title,latitude,longitude,type,published_at,shared,processing_instance_id,processing_started_at,source&order=id.desc&limit=$limit&$filter" \
    -H "apikey: $PERSONAL_SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $PERSONAL_SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" | jq
}

summarize_commits() {
    # Configurable defaults
    local default_since="48.hours"   # Default time range
    local default_commits=5         # Default number of commits

    # Optional arguments
    local since="${1:-$default_since}" # Accept user input or use default
    local num_commits="${2:-$default_commits}" # Default to 5 commits if not provided

    # Retrieve the latest N commits in the given time frame
    local commits=()
    while IFS= read -r commit; do
        commits+=("$commit")
    done < <(git log --since="$since" --pretty=format:"%H" -n "$num_commits")

    # Check if there are any commits in the specified range
    if [ ${#commits[@]} -eq 0 ]; then
        echo "No commits found in the last $since."
        return 1
    fi

    # Generate diffs for the retrieved commits
    local diffs=""
    for commit in "${commits[@]}"; do
        diffs+="$(git show "$commit")\n\n"
    done

    # Send the diffs to the LLM for summarization
    echo -e "$diffs" | llm -m "gpt-3.5-turbo-16k" "Summarize the following git diffs in detail, particularly focused on describing the delta, summarizing the changes that were made:"
}

# >>> conda initialize - lazy loaded for speed >>>
conda() {
    unset -f conda
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
            . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
        else
            export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
        fi
    fi
    unset __conda_setup
    conda "$@"
}
# <<< conda initialize <<<

# Initialize zoxide (smarter cd command) - lazy loaded
z() {
    unset -f z
    eval "$(zoxide init zsh)"
    z "$@"
}

# Initialize atuin - lazy loaded  
atuin() {
    unset -f atuin
    eval "$(atuin init zsh)"
    atuin "$@"
}


export EDITOR="nvim"
export VISUAL="nvim"

alias foxpods='SwitchAudioSource -s "FOXPODS"'
alias speakers='SwitchAudioSource -s "MacBook Pro Speakers"'
alias sw="smallweb"

# ========================================
# UV FOREVER 🚀 - Modern Python tooling
# ========================================
export UV_SYSTEM_PYTHON=1

# Quick uv commands
alias uvi="uv tool install"      # install any Python CLI tool
alias uvr="uv run"               # run in isolated env
alias uvs="uv sync"              # sync dependencies
alias uvx="uvx"                  # run without installing

# Override pip/python with helpful reminders (functions, not aliases)
function pip() {
  echo "💡 Use uv instead:"
  echo "  • uv add <package>        (in a project)"
  echo "  • uv tool install <tool>  (for CLI tools)"
  echo "  • uv pip install <pkg>    (if you really need pip)"
  echo ""
  echo "Running traditional pip..."
  command pip "$@"
}

function pip3() {
  pip "$@"  # Just call pip function
}

# Override python to suggest uv for projects
function python() {
  if [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
    echo "💡 Python project detected! Use: uv run python"
    echo "   This ensures correct dependencies are loaded"
    echo ""
  fi
  command python "$@"
}

function python3() {
  python "$@"  # Just call python function
}

# Override venv commands - helpful reminders to break old habits
alias venv='echo "💡 Use uv instead: uv init (new) or uv sync (existing)"'
alias virtualenv='echo "💡 Use uv instead: uv init (new) or uv sync (existing)"'
alias activate='echo "💡 No activation needed! Just use: uv run python"'
alias deactivate='echo "💡 No deactivation needed with uv!"'

# More aggressive overrides for common venv patterns
alias "source venv/bin/activate"='echo "💡 Stop! Use: uv run python"'
alias "source .venv/bin/activate"='echo "💡 Stop! Use: uv run python"'
alias ". venv/bin/activate"='echo "💡 Stop! Use: uv run python"'
alias ". .venv/bin/activate"='echo "💡 Stop! Use: uv run python"'

# ========================================
# UV HELPER FUNCTIONS
# ========================================

# Quick reference
alias halp='echo "
📦 UV QUICK REFERENCE:
  uv init              → start new project
  uv add <package>     → install package (like npm install)
  uv remove <package>  → uninstall package
  uv sync              → install all deps from pyproject.toml
  uv run <script>      → run in project env
  uv tool install      → install CLI tools globally
  uvx <tool>           → run tool without installing
"'

# Smart python that knows what you want
function py() {
  if [[ -f "pyproject.toml" ]]; then
    echo "🚀 Running with uv in project..."
    uv run python "$@"
  elif [[ -f "requirements.txt" ]]; then
    echo "📦 Found requirements.txt, using uv..."
    uv pip sync requirements.txt
    uv run python "$@"
  else
    echo "🐍 No project found, using system python..."
    /usr/bin/python3 "$@"
  fi
}

# Install packages smartly
function install() {
  if [[ -f "pyproject.toml" ]]; then
    echo "📦 Adding to project with uv..."
    uv add "$@"
  elif [[ -f "package.json" ]]; then
    echo "📦 npm project detected..."
    npm install "$@"
  else
    echo "🔧 Installing as global tool..."
    uv tool install "$@"
  fi
}

# Auto-reminder when cd into Python project
function cd() {
  builtin cd "$@"
  if [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
    echo "🐍 Python project detected! Commands:"
    echo "  • py script.py    (auto-runs with uv)"
    echo "  • install <pkg>   (auto-adds with uv)"
    echo "  • uv sync         (install all deps)"
  fi
}

# Quick fixes
alias fixit='uv pip sync requirements.txt 2>/dev/null || uv sync 2>/dev/null || uv init'
alias fuckit='rm -rf .venv __pycache__ && uv sync'

# Quick new project
function pyproject() {
  mkdir -p "$1" && cd "$1"
  uv init
  echo "✨ Project $1 created! Now do: install <packages>"
}

alias refresh-motd='rm -f /tmp/startup_cache/reflection_cache.txt && ~/.startup.sh'

# IRC shortcuts
alias fp='irssi'
alias ircsesh='tmux new-session -d -s irc "irssi" && tmux attach -t irc'
alias irclog='tail -f ~/.dotfiles/.irssi/logs/**/*.log | head -50'
alias fp="irssi"

# Theme switching - vulpes-reddish2 light/dark mode for shell (nvim handles its own via auto-dark-mode)
theme-dark() {
  # vulpes-reddish2 colors for dark mode
  ZSH_HIGHLIGHT_STYLES=(
    'alias:fg=#f30061'
    'builtin:fg=#ff5703'
    'command:fg=#da0000'
    'function:fg=#f30061'
    'hashed-command:fg=#da0000'
    'reserved-word:fg=#ff6e0e'
    'string:fg=#ff8e0e'
    'comment:fg=#c00000,bold'
    'globbing:fg=#f300a2'
    'history-expansion:fg=#ff279a'
    'default:fg=#e5dcdc'
  )

  export FZF_DEFAULT_OPTS=$'--color=fg:#e5dcdc,bg:#000000,hl:#da0000 \
    --color=fg+:#e5dcdc,bg+:#1a1a1a,hl+:#da0000 \
    --color=info:#ff279a,prompt:#da0000,pointer:#da0000 \
    --color=marker:#ff8e0e,spinner:#f300a2,header:#c00000 \
    --color=border:#1a1a1a,label:#e5dcdc,query:#e5dcdc'

  echo "🌙 Switched to dark mode (vulpes-reddish2)"
}

theme-light() {
  # vulpes-reddish2 colors for light mode
  ZSH_HIGHLIGHT_STYLES=(
    'alias:fg=#ea005e'
    'builtin:fg=#f45100'
    'command:fg=#ff0404'
    'function:fg=#ea005e'
    'hashed-command:fg=#ff0404'
    'reserved-word:fg=#e05a00'
    'string:fg=#f48200'
    'comment:fg=#ff3737,bold'
    'globbing:fg=#ea009c'
    'history-expansion:fg=#ff048a'
    'default:fg=#3b2b2b'
  )

  export FZF_DEFAULT_OPTS=$'--color=fg:#3b2b2b,bg:#f7f7f7,hl:#ff0404 \
    --color=fg+:#3b2b2b,bg+:#e6e6e6,hl+:#ff0404 \
    --color=info:#ff048a,prompt:#ff0404,pointer:#ff0404 \
    --color=marker:#f48200,spinner:#ea009c,header:#ff3737 \
    --color=border:#e6e6e6,label:#3b2b2b,query:#3b2b2b'

  echo "☀️ Switched to light mode (vulpes-reddish2)"
}
