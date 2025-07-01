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
CACHE_DURATION=1800  # 30 minutes in seconds

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
ENABLE_CORRECTION="true"

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
plugins=(git)

# Skip global compinit for faster loading (OMZ will handle it)
skip_global_compinit=1

source $ZSH/oh-my-zsh.sh

# User configuration

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

# NVM configuration - lazy loaded for speed
export NVM_DIR="$HOME/.nvm"
nvm() {
    unset -f nvm
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
    nvm "$@"
}

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

PATH=~/.console-ninja/.bin:$PATH

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Terminal settings
export TERM="xterm-256color"
export COLORTERM="truecolor"
touch ~/.hushlogin
export MAILCHECK=0

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Smart git commit with LLM integration
alias commit='git add -A && diff_output=$(git diff --cached) && if [ ${#diff_output} -gt 100000 ]; then commit_msg=$(echo -e "$(git diff --name-only)\n\n$(echo "$diff_output" | head -c 1024)" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) The git diff is too large to process fully. Based on the list of changed files and the first part of the diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); else commit_msg=$(echo "$diff_output" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) Based on the following git diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); fi && selected_msg=$(echo "$commit_msg" | fzf --prompt="Select a commit message:") && git commit -m "$selected_msg"'

# Custom aliases and commands
# Override Oh My Zsh ls aliases with lsd
alias l='lsd -lah'
alias la='lsd -lAh'
alias ll='lsd -lh'
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
