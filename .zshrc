# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

# Quick CLI help - ask how to do something in the terminal
function '??' {
  llm -m 4o-mini -s "You are a concise CLI expert. Given a task, respond with ONLY the command(s) needed. No explanations, no markdown, just executable commands. If multiple commands needed, put each on its own line." "$*"
}

# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Startup script (execute as subprocess to avoid job control noise)
[ -f ~/.startup.sh ] && ~/.startup.sh

# Apply Claude Code theme customizations (if configured)
[ -f ~/.dotfiles/.tweakcc-apply.sh ] && ~/.dotfiles/.tweakcc-apply.sh

# OLD caching mechanism (backup reference):
# The new script handles caching internally and displays instantly
# No need for external caching wrapper anymore

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.claude/local:$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH

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
plugins=(git zsh-autosuggestions you-should-use)

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

PATH=~/.console-ninja/.bin:$PATH

# Terminal settings
export TERM="xterm-256color"
export COLORTERM="truecolor"
touch ~/.hushlogin
export MAILCHECK=0

# Vulpes red man page colors (LESS_TERMCAP)
export LESS_TERMCAP_mb=$'\e[1;38;5;204m'      # begin bold - pink-red
export LESS_TERMCAP_md=$'\e[1;38;5;204m'      # begin blink - pink-red (headers)
export LESS_TERMCAP_me=$'\e[0m'               # end bold/blink
export LESS_TERMCAP_so=$'\e[38;5;0;48;5;174m' # begin standout - dark on dusty rose
export LESS_TERMCAP_se=$'\e[0m'               # end standout
export LESS_TERMCAP_us=$'\e[4;38;5;167m'      # begin underline - orange-red
export LESS_TERMCAP_ue=$'\e[0m'               # end underline

# Vulpes autosuggestion color (subtle mauve)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

# Vulpes theme integration - MUST load before p10k for colors to work
# Unified theme switcher functions (switches ZSH, Yazi, and Lazygit)
vulpes-dark() {
  # ZSH colors
  source ~/.config/zsh/themes/vulpes-reddishnovember-dark.zsh

  # Yazi theme symlink
  ln -sf ~/.config/yazi/vulpes-reddishnovember-dark.toml ~/.config/yazi/theme.toml

  # Lazygit config
  cp ~/.config/lazygit/config.yml ~/.config/lazygit/config.yml.bak 2>/dev/null
  cat > ~/.config/lazygit/config.yml << 'EOF'
# vulpes-reddishnovember-dark - Lazygit Theme
gui:
  theme:
    activeBorderColor: ['#e60067', bold]
    inactiveBorderColor: ['#ffffff']
    searchingActiveBorderColor: ['#ff0022', bold]
    optionsTextColor: ['#ff0095']
    selectedLineBgColor: ['#1a1a1a']
    selectedRangeBgColor: ['#1a1a1a']
    cherryPickedCommitBgColor: ['#ff0095']
    cherryPickedCommitFgColor: ['#0d0d0d']
    unstagedChangesColor: ['#ff001e']
    defaultFgColor: ['#f2cfdf']
  commitLength:
    show: true
  showFileTree: true
  showListFooter: true
  showRandomTip: true
  showBranchCommitHash: false
  showBottomLine: true
  showCommandLog: true
  authorColors:
    "*": '#e60067'
  branchColors:
    "main": '#ffffff'
    "master": '#ffffff'
    "develop": '#ff0095'
    "feature/*": '#ff0022'
    "fix/*": '#ff001e'
EOF

  # FZF colors - vulpes red dark
  export FZF_DEFAULT_OPTS="
    --color=fg:#f5d0dc,bg:#0d0d0d,hl:#ff0055
    --color=fg+:#ffffff,bg+:#2d1a22,hl+:#ff3344
    --color=info:#ff0077,prompt:#ff0055,pointer:#ff0055
    --color=marker:#ff0055,spinner:#ff0077,header:#73264a
    --color=border:#73264a
  "

  echo "✓ Switched to vulpes-reddishnovember-dark (ZSH, Yazi, Lazygit, FZF)"
  echo "  Note: Ghostty, Neovim, and Bat auto-switch with system appearance"
}

vulpes-light() {
  # ZSH colors
  source ~/.config/zsh/themes/vulpes-reddishnovember-light.zsh

  # Yazi theme symlink
  ln -sf ~/.config/yazi/vulpes-reddishnovember-light.toml ~/.config/yazi/theme.toml

  # Lazygit config
  cp ~/.config/lazygit/config.yml ~/.config/lazygit/config.yml.bak 2>/dev/null
  cat > ~/.config/lazygit/config.yml << 'EOF'
# vulpes-reddishnovember-light - Lazygit Theme
gui:
  theme:
    activeBorderColor: ['#fa0070', bold]
    inactiveBorderColor: ['#000000']
    searchingActiveBorderColor: ['#e0001e', bold]
    optionsTextColor: ['#e00083']
    selectedLineBgColor: ['#efefef']
    selectedRangeBgColor: ['#efefef']
    cherryPickedCommitBgColor: ['#e00083']
    cherryPickedCommitFgColor: ['#f7f7f7']
    unstagedChangesColor: ['#e0001a']
    defaultFgColor: ['#501630']
  commitLength:
    show: true
  showFileTree: true
  showListFooter: true
  showRandomTip: true
  showBranchCommitHash: false
  showBottomLine: true
  showCommandLog: true
  authorColors:
    "*": '#fa0070'
  branchColors:
    "main": '#d60044'
    "master": '#d60044'
    "develop": '#e00083'
    "feature/*": '#e0001e'
    "fix/*": '#e0001a'
EOF

  # FZF colors - vulpes red light
  export FZF_DEFAULT_OPTS="
    --color=fg:#2d1a22,bg:#fff5f8,hl:#cc0044
    --color=fg+:#0d0d0d,bg+:#f5e0e8,hl+:#dd2244
    --color=info:#cc0055,prompt:#cc0044,pointer:#cc0044
    --color=marker:#cc0044,spinner:#cc0055,header:#d4a0b0
    --color=border:#d4a0b0
  "

  echo "✓ Switched to vulpes-reddishnovember-light (ZSH, Yazi, Lazygit, FZF)"
  echo "  Note: Ghostty, Neovim, and Bat auto-switch with system appearance"
}

# Auto-detect macOS system appearance and apply theme
vulpes-auto() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Check macOS appearance mode
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
      # Dark mode is on (suppress output on startup)
      if [[ "$1" != "silent" ]]; then
        vulpes-dark
      else
        source ~/.config/zsh/themes/vulpes-reddishnovember-dark.zsh >/dev/null 2>&1
        ln -sf ~/.config/yazi/vulpes-reddishnovember-dark.toml ~/.config/yazi/theme.toml 2>/dev/null
      fi
    else
      # Light mode is on (suppress output on startup)
      if [[ "$1" != "silent" ]]; then
        vulpes-light
      else
        source ~/.config/zsh/themes/vulpes-reddishnovember-light.zsh >/dev/null 2>&1
        ln -sf ~/.config/yazi/vulpes-reddishnovember-light.toml ~/.config/yazi/theme.toml 2>/dev/null
      fi
    fi
  else
    echo "Auto-detection only supported on macOS"
    echo "Manually run: vulpes-dark or vulpes-light"
  fi
}

# Auto-sync themes with system appearance on shell startup
vulpes-auto silent

# ZSH syntax highlighting - load after theme
# Fast syntax highlighting (faster than zsh-syntax-highlighting)
source /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Smart git commit with LLM integration
alias commit='git add -A && diff_output=$(git diff --cached) && if [ ${#diff_output} -gt 100000 ]; then commit_msg=$(echo -e "$(git diff --name-only)\n\n$(echo "$diff_output" | head -c 1024)" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) The git diff is too large to process fully. Based on the list of changed files and the first part of the diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); else commit_msg=$(echo "$diff_output" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) Based on the following git diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); fi && selected_msg=$(echo "$commit_msg" | fzf --prompt="Select a commit message:") && git commit -m "$selected_msg"'

# Custom aliases and commands
# Override Oh My Zsh ls aliases with lsd
alias l='lsd -lah'
alias la='lsd -lAh'
alias ll='lsd -lht'
alias ls='lsd -G'
alias lsa='lsd -lah'

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
alias sshvps='vps'  # Use mosh-powered vps() function
alias sshsmallweb='ssh -i ~/.ssh/2024-mbp.pem smallweb@208.113.130.118'

# Cracked SSH helpers - never lose your VPS session again
vps() {
  # Try mosh first (handles disconnects like a boss), fall back to SSH
  if command -v mosh &> /dev/null; then
    echo "🚀 Connecting with mosh (roaming mode)..."

    # Try mosh connection
    if ! mosh vps -- tmux new-session -A -s 0 2>/dev/null; then
      echo "⚠️  Mosh failed (server might not have it installed)"
      echo "📦 Auto-installing mosh on VPS..."

      # Copy setup script and run it
      scp -q -i ~/.ssh/2024-mbp.pem ~/.dotfiles/scripts/setup-vps-mosh.sh debian@208.113.130.118:/tmp/ 2>/dev/null
      ssh -t vps 'bash /tmp/setup-vps-mosh.sh && rm /tmp/setup-vps-mosh.sh'

      echo ""
      echo "✓ Setup complete! Connecting with mosh..."
      mosh vps -- tmux new-session -A -s 0
    fi
  else
    echo "📡 Mosh not found locally, using SSH (install: brew install mosh)"
    ssh -t vps 'tmux new-session -A -s 0'
  fi
}

# Quick reconnect - respawns pane with same command
vpsreconnect() {
  if [ -n "$TMUX" ]; then
    tmux respawn-pane -k "vps"
  else
    vps
  fi
}

# Keep SSH session alive by sending data every 60s
sshkeepalive() {
  local host="${1:-vps}"
  while true; do
    ssh -o ServerAliveInterval=60 -t "$host" 'tmux new-session -A -s main'
    echo "⚠️  Connection lost. Reconnecting in 3s..."
    sleep 3
  done
}

# Based on your actual usage patterns (you're welcome)
alias cl='claude --dangerously-skip-permissions'  # Your 651x favorite command
alias cln='claude --no-approval'  # When you need even more speed
alias clc='claude commit'  # Let the robots write your commit messages
alias ta='tmux attach -t 0'  # Your default tmux session
alias t0='tmux attach -t 0'  # Alternative for muscle memory
alias metro='z ~/code/metro-maker4'  # Jump to metro-maker4 (using z)
alias ddhq='z ~/client-code/ddhq'  # Jump to ddhq (using z)
alias coach='z ~/code/coachartie2'  # Jump to coachartie2 (using z)
alias cc='z ~/client-code'  # Client code directory (using z)
alias ccode='z ~/code'  # Main code directory (renamed to avoid conflict)
alias ..2='cd ../..'  # Go up two directories (renamed)
alias ..3='cd ../../..'  # Go up three directories (renamed)
alias nrd='npm run dev'  # Your 423x daily ritual (renamed to avoid conflict)
alias nred='npm run electron:dev'  # When you need electron (renamed)
alias yy='npx yalc'  # Shortcut for yalc commands (shortened)
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

# Load local customizations (1Password helpers, etc)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

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
export MANPAGER='nvim +Man!'

# Quick tips lookup
tips() { grep -i "${1:-.}" ~/tips.txt | fzf --height=50% --reverse; }

# Quick note to Obsidian inbox
note() { echo "- $* ($(date '+%H:%M'))" >> ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox/inbox.md && echo "noted"; }

# Re-run last command and copy output
yank() { fc -e - | pbcopy && echo "output copied"; }

# Ask LLM about clipboard contents
ask() { pbpaste | llm "$*"; }

# Explain last command output
explain() { fc -e - | llm "explain this terminal output concisely"; }

# Notify when long command finishes (use: sleep 10; ding)
ding() { osascript -e "display notification \"Done\" with title \"Terminal\" sound name \"Glass\""; }

# Quick gist from clipboard
gist() { pbpaste | gh gist create -f "${1:-snippet.txt}" -d "${2:-}" && echo "gisted"; }

alias foxpods='SwitchAudioSource -s "FOXPODS"'
alias speakers='SwitchAudioSource -s "MacBook Pro Speakers"'
alias sw="smallweb"
alias pip="uv pip"
alias pip3="uv pip"
export UV_SYSTEM_PYTHON=1

# UV FOREVER 🚀
alias python="uv run python"
alias pip="uv pip"
alias pip3="uv pip"
alias venv="uv venv"
alias install="uv tool install"

# Quick uv commands
alias uvi="uv tool install"      # install any Python CLI tool
alias uvr="uv run"               # run in isolated env
alias uvs="uv sync"              # sync dependencies
alias uvx="uvx"                  # run without installing

# Never see pip conflicts again
export UV_SYSTEM_PYTHON=1
# ========================================
# UV HELPERS - Remind you to use uv instead
# ========================================

# Override pip to remind about uv
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
  echo "💡 Use uv instead:"
  echo "  • uv add <package>        (in a project)"
  echo "  • uv tool install <tool>  (for CLI tools)"
  echo "  • uv pip install <pkg>    (if you really need pip)"
  echo ""
  echo "Running traditional pip3..."
  command pip3 "$@"
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
  if [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
    echo "💡 Python project detected! Use: uv run python"
    echo "   This ensures correct dependencies are loaded"
    echo ""
  fi
  command python3 "$@"
}

# Override venv commands
alias venv='echo "💡 Use uv instead: uv init (new) or uv sync (existing)"'
alias virtualenv='echo "💡 Use uv instead: uv init (new) or uv sync (existing)"'
alias activate='echo "💡 No activation needed! Just use: uv run python"'
alias deactivate='echo "💡 No deactivation needed with uv!"'

# fuck it, zoxide is cd now
alias cd='z'
alias stream-motd='rm -rf /tmp/startup_cache/* && ~/.startup.sh'

# Random tip from tips.txt (video game loading screen style)
alias tip='shuf -n 1 ~/tips.txt'

# Nvim fuzzy finder aliases
alias v='nvim'
alias vs='nvim $(fzf --preview "bat --color=always --style=numbers {}" --preview-window=right:60%:wrap)'
alias vg='nvim $(rg --line-number --no-heading --color=always . | fzf --ansi --preview "echo {} | cut -d: -f1,2 | xargs -I {} sh -c \"bat --color=always --highlight-line \$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)\"" --delimiter ":" --preview-window=right:60%:wrap | cut -d: -f1)'
alias o='cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox && nvim "$(fd -e md -E .trash -E attachments -x stat -f "%m {}" | sort -rn | cut -d" " -f2- | sed "s|^\./||" | fzf --preview "bat --color=always --style=numbers {}" --preview-window=right:60%:wrap --with-nth=-2.. --delimiter=/)"'
alias r='nvim "$(fd -t f -e js -e ts -e vue -e md -e jsx -e tsx -e css -e scss -e py -e go -e rs -E node_modules -E dist -E build -E .next -E .nuxt -E out -E target -E vendor . ~/code -x stat -f "%m {}" | sort -rn | cut -d" " -f2- | sed "s|$HOME/code/||" | fzf --preview "bat --color=always --style=numbers ~/code/{}" --preview-window=right:60% --prompt=\"  \" --pointer=\"\" --marker=\"󰄲\" | sed "s|^|$HOME/code/|")"'


# JINA_CLI_BEGIN

## autocomplete
if [[ ! -o interactive ]]; then
    return
fi

compctl -K _jina jina

_jina() {
  local words completions
  read -cA words

  if [ "${#words}" -eq 2 ]; then
    completions="$(jina commands)"
  else
    completions="$(jina completions ${words[2,-2]})"
  fi

  reply=(${(ps:
:)completions})
}








alias y='yazi'
alias n='nvim .'

# session-wise fix
ulimit -n 4096
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# JINA_CLI_END


# Initialize rbenv
eval "$(rbenv init - zsh)"

# Email shortcuts
alias m='neomutt'
alias ei='email-insights'

# IRC shortcuts
alias fp='irssi'
alias ircsesh='tmux new-session -d -s irc "irssi" && tmux attach -t irc'
alias irclog='tail -f ~/.dotfiles/.irssi/logs/**/*.log | head -50'

# cmus YouTube integration 
alias yt="~/.config/cmus/cmus-yt.sh"
alias ytp="~/.config/cmus/yt-playlist.sh"
alias cm="cmus"
alias cmp="cmus-remote -u"  # pause/play toggle
alias cmn="cmus-remote -n"  # next
alias cmr="cmus-remote -r"  # previous
alias cms="cmus-remote -s"  # stop
alias cmq="cmus-remote -Q"  # current track info
# This line has been cleaned up - the duplicate paths and VMware Fusion issue have been resolved
# The PATH is now managed by the earlier export PATH statements in this file

# Mermaid ASCII tool configuration
export PATH="$HOME/bin:$PATH"

# Mermaid ASCII aliases
alias mermaid="mermaid-ascii"
alias ascii-mermaid="mermaid-ascii"
alias mmd="mermaid-ascii"

# Tmux + Mermaid functions
send-mermaid() {
    local target_pane=${1}
    if [[ -z "$target_pane" ]]; then
        echo "Usage: send-mermaid <pane_target>"
        echo "Available panes:"
        tmux list-panes -a -F "  #{session_name}:#{window_index}.#{pane_index} - #{pane_title} (#{pane_current_command})"
        echo ""
        echo "Example: echo 'graph TD"$'\n'"A --> B"$'\n'"B --> C' | send-mermaid 0:6.2"
        echo "NOTE: Use multiline syntax, NOT semicolons!"
        return 1
    fi
    local temp_file="/tmp/mermaid_$(date +%s).txt"

    # Use ASCII-only mode (-a flag) for terminal compatibility
    if mermaid-ascii -a -f - > "$temp_file" 2>/dev/null; then
        tmux send-keys -t "$target_pane" "clear && echo '🎯 MERMAID DIAGRAM:' && cat '$temp_file' && rm '$temp_file'" Enter
    else
        echo "❌ Error: Failed to generate mermaid diagram"
        echo "Check your syntax - use multiline format:"
        echo "graph TD"
        echo "A --> B"
        echo "B --> C"
        echo ""
        echo "NOT: graph TD; A-->B; B-->C"
        rm -f "$temp_file"
        return 1
    fi
}

list-panes() {
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} - #{pane_title} (#{pane_current_command})"
}

# Auto-sync lazygit theme with system appearance
if [[ -x "$HOME/.local/bin/lazygit-theme-sync" ]]; then
    "$HOME/.local/bin/lazygit-theme-sync" &>/dev/null
fi




# RSS reader alias
alias rss="newsboat"

# DDHQ TUI alias
alias elections="/Users/ejfox/client-code/ddhq/ddhq-rust-tui/target/release/ddhq-tui"
alias scrap="scrapbook-cli"

# bun completions
[ -s "/Users/ejfox/.bun/_bun" ] && source "/Users/ejfox/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
