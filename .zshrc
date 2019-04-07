# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

unsetopt correct

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="amuse"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=5

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(powerline git zsh-syntax-highlighting brew catimg coffee common-aliases jsontools pip)

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
# export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# ~aliases
alias ~aliases="vim ~/.zshrc +86"
#
alias shutdown="sudo shutdown -r now"
alias scripts="cat package.json | grep 'scripts' -A 10"
alias serve="npx node-static -p 8000"
alias ~desktop"=cd ~/Desktop;ll"
alias ~wcd="wc -l **/*"
alias ~.zshrc="vim ~/.zshrc +111"
alias zshconfig="vim ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias ~git="cd ~/git/;ll"
alias ~website="cd ~/git/website"
alias ~dropbox="cd ~/Dropbox/;ll"
alias ~writing="cd ~/Dropbox/Writing/;ll"
alias ~sd="sudo shutdown -h now"
alias ~cloudterm="ssh debian@107.180.238.27"
alias ~cloud="ssh ejfox@https://ejfox.xyz"
alias ~ip="curl https://ipinfo.io/ip"
alias g="googler -n 5"
alias g!="googler -n 5 -j"
alias commit="f() { git add .; git commit -m $1; git push };f"
alias newrepo="f() { curl -u 'ejfox' https://api.github.com/user/repos -d '{"name":"$1"}' };f"

###-tns-completion-start-###
if [ -f /Users/EJ/.tnsrc ]; then
    source /Users/EJ/.tnsrc
fi
###-tns-completion-end-###
### MOTD Script Start ###

      # Display MotD
      if [[ -e $HOME/.motd ]]; then cat $HOME/.motd; fi

### MOTD Script End ###

alias ~motd="f() { echo '$1' > ~/.motd}"

export PATH="/Users/ejf/bin:/usr/local/bin:/Library/Frameworks/Python.framework/Versions/3.7/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/MacGPG2/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/Applications/Wireshark.app/Contents/MacOS:/Users/ejf/.nvm/versions/node/v8.11.1/bin:/Users/ejf/bin:/Library/Frameworks/Python.framework/Versions/3.7/bin:/Users/ejf/.vimpkg/bin"
