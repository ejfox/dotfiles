# .zshenv - runs for ALL zsh invocations (interactive, login, scripts, ssh commands)
# Keep this minimal — only PATH essentials

# Cargo
. "$HOME/.cargo/env" 2>/dev/null

# Homebrew (Apple Silicon vs Intel)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
elif [[ -x "/usr/local/bin/brew" ]]; then
  export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
fi

# Essential tool paths
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
