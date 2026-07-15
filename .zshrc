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

# Detect Homebrew prefix (Apple Silicon vs Intel)
# Check for actual bin directory, not just the parent (empty /opt/homebrew can exist on Intel)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.claude/local:$HOME/.dotfiles/bin:$HOME/bin:$HOME/.local/bin:$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH

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
plugins=(git zsh-autosuggestions)

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
[ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$BREW_PREFIX/opt/nvm/nvm.sh"
[ -s "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

PATH=~/.console-ninja/.bin:$PATH

# Terminal settings
# TERM override removed 2026-07-15: it stomped Ghostty's xterm-ghostty, which
# blinded tmux to the Sync capability → laggy/tearing scroll in panes. Let the
# terminal set its own TERM. If an ancient ssh host complains, fix per-host:
#   infocmp -x xterm-ghostty | ssh host tic -x -
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

# Vulpes theme — session colors only. All FILE mutations (lazygit, yazi, tmux,
# btop, fzf symlink, claude) belong to bin/appearance-watcher; see
# docs/THEME-SYSTEM.md. This block must load before p10k for colors to work.
if defaults read -g AppleInterfaceStyle &>/dev/null; then
  source ~/.config/zsh/themes/vulpes-reddishnovember-dark.zsh 2>/dev/null
else
  source ~/.config/zsh/themes/vulpes-reddishnovember-light.zsh 2>/dev/null
fi
[ -f ~/.config/fzf/current.sh ] && source ~/.config/fzf/current.sh

# Muscle-memory shims for the retired vulpes-* switcher functions
alias vulpes-dark='theme-dark'
alias vulpes-light='theme-light'
alias vulpes-auto='theme'

# ZSH syntax highlighting - load after theme
# Fast syntax highlighting (faster than zsh-syntax-highlighting)
# Install with: brew install zsh-fast-syntax-highlighting
[ -f "$BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ] && \
  source "$BREW_PREFIX/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Custom aliases and commands
# Override Oh My Zsh ls aliases with lsd
alias l='lsd -lah'
alias la='lsd -lAh'
alias ll='lsd -lht'
alias ls='lsd -G'
alias lsa='lsd -lah'

alias cheatsheet="cheatsheets"
alias dev="yarn dev"
alias yarni="yarn install"
alias nodei="node index.js"
alias c="clear"
alias yd="yarn dev"
alias pbp="pbpaste"
alias pbc="pbcopy"
alias catcopy="cat | pbcopy"
alias tmuxkill="tmux kill-server"
alias tmuxnew="tmux new -s"
alias showcase="open \"https://ejfox-codeshowcase.web.val.run/?code=$(pbpaste | jq -sRr @uri)\""
alias vault="cd $HOME/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox"
alias agentvault="cd $HOME/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/agent-vault"
alias nukeyarn="rm yarn.lock;rm -rf node_modules"
alias ghpub='gh repo create $1 --public --source=. --remote=origin --push'
alias sshvps='vps'  # Use mosh-powered vps() function

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
alias clc='claude commit'  # Let the robots write your commit messages
alias ta='tmux attach -t 0'  # Your default tmux session
alias t0='tmux attach -t 0'  # Alternative for muscle memory
alias metro='z ~/code/metro-maker4'  # Jump to metro-maker4 (using z)
alias coach='z ~/code/coachartie2'  # Jump to coachartie2 (using z)
alias ccode='z ~/code'  # Main code directory (renamed to avoid conflict)
alias ..2='cd ../..'  # Go up two directories (renamed)
alias ..3='cd ../../..'  # Go up three directories (renamed)
alias nrd='npm run dev'  # Your 423x daily ritual (renamed to avoid conflict)
alias nred='npm run electron:dev'  # When you need electron (renamed)
alias yy='npx yalc'  # Shortcut for yalc commands (shortened)

export PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
# Load environment variables from ~/.env (not committed to git)
[ -f ~/.env ] && source ~/.env

# Load local customizations (1Password helpers, etc)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

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
tips() { grep -i "${1:-.}" ~/.dotfiles/docs/tips.txt | fzf --height=50% --reverse; }

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

# UV FOREVER 🚀
export UV_SYSTEM_PYTHON=1
alias python="uv run python"
alias pip="uv pip"
alias pip3="uv pip"
alias install="uv tool install"

# Quick uv commands
alias uvi="uv tool install"      # install any Python CLI tool
alias uvr="uv run"               # run in isolated env
alias uvs="uv sync"              # sync dependencies

# Steer venv workflows toward uv
alias venv='echo "💡 Use uv instead: uv init (new) or uv sync (existing)"'
alias virtualenv='echo "💡 Use uv instead: uv init (new) or uv sync (existing)"'
alias activate='echo "💡 No activation needed! Just use: uv run python"'
alias deactivate='echo "💡 No deactivation needed with uv!"'

# fuck it, zoxide is cd now
alias cd='z'
alias stream-motd='rm -rf /tmp/startup_cache/* && ~/.startup.sh'

# Random tip from tips.txt (video game loading screen style)
alias tip='shuf -n 1 ~/.dotfiles/docs/tips.txt'

# Nvim fuzzy finder aliases
alias v='nvim'
alias vs='nvim $(fzf --preview "bat --color=always --style=numbers {}" --preview-window=right:60%:wrap)'
alias vg='nvim $(rg --line-number --no-heading --color=always . | fzf --ansi --preview "echo {} | cut -d: -f1,2 | xargs -I {} sh -c \"bat --color=always --highlight-line \$(echo {} | cut -d: -f2) \$(echo {} | cut -d: -f1)\"" --delimiter ":" --preview-window=right:60%:wrap | cut -d: -f1)'
alias o='cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox && nvim "$(fd -e md -E .trash -E attachments -x stat -f "%m {}" | sort -rn | cut -d" " -f2- | sed "s|^\./||" | fzf --preview "bat --color=always --style=numbers {}" --preview-window=right:60%:wrap --with-nth=-2.. --delimiter=/)"'
alias r='nvim "$(fd -t f -e js -e ts -e vue -e md -e jsx -e tsx -e css -e scss -e py -e go -e rs -E node_modules -E dist -E build -E .next -E .nuxt -E out -E target -E vendor . ~/code -x stat -f "%m {}" | sort -rn | cut -d" " -f2- | sed "s|$HOME/code/||" | fzf --preview "bat --color=always --style=numbers ~/code/{}" --preview-window=right:60% --prompt=\"  \" --pointer=\"\" --marker=\"󰄲\" | sed "s|^|$HOME/code/|")"'






alias y='yazi'
alias n='nvim .'

# session-wise fix
ulimit -n 4096
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# IRC shortcuts
alias fp='irssi'
alias ircsesh='tmux new-session -d -s irc "irssi" && tmux attach -t irc'

list-panes() {
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} - #{pane_title} (#{pane_current_command})"
}





# RSS reader alias
alias rss="newsboat"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Fly.io
export FLYCTL_INSTALL="$HOME/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

# Shell leg of usage logging (tmux/nvim/hammerspoon/talon legs live elsewhere)
[ -f ~/.dotfiles/lib/shell-usage-logging.zsh ] && source ~/.dotfiles/lib/shell-usage-logging.zsh
