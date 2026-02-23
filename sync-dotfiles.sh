#!/bin/bash
# Sync dotfiles and recreate all symlinks
set -e

cd ~/.dotfiles

# Pull latest changes (stash local changes if needed)
if ! git diff --quiet 2>/dev/null; then
  echo "Stashing local changes..."
  git stash
  git pull origin main
  git stash pop
else
  git pull origin main
fi

# Ensure ~/.config exists
mkdir -p ~/.config

# Core dotfiles
ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.startup.sh ~/.startup.sh
ln -sf ~/.dotfiles/.zen-mode.sh ~/.zen-mode.sh
ln -sf ~/.dotfiles/.p10k.zsh ~/.p10k.zsh
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/.npmrc ~/.npmrc
ln -sf ~/.dotfiles/.zprofile ~/.zprofile
ln -sf ~/.dotfiles/.bash_profile ~/.bash_profile
ln -sf ~/.dotfiles/.zshenv ~/.zshenv
ln -sf ~/.dotfiles/.llm-persona.txt ~/.llm-persona.txt

# Config directories
ln -sf ~/.dotfiles/.config/nvim ~/.config/nvim
ln -sf ~/.dotfiles/.config/ghostty ~/.config/ghostty
ln -sf ~/.dotfiles/.config/yazi ~/.config/yazi
ln -sf ~/.dotfiles/.config/btop ~/.config/btop
ln -sf ~/.dotfiles/.config/minimal-prompt.zsh ~/.config/minimal-prompt.zsh
ln -sf ~/.dotfiles/.config/atuin ~/.config/atuin
ln -sf ~/.dotfiles/.config/bat ~/.config/bat
ln -sf ~/.dotfiles/.config/htop ~/.config/htop
ln -sf ~/.dotfiles/.config/karabiner ~/.config/karabiner
ln -sf ~/.dotfiles/.config/lazygit ~/.config/lazygit
ln -sf ~/.dotfiles/.config/neofetch ~/.config/neofetch
ln -sf ~/.dotfiles/.config/neomutt ~/.config/neomutt
ln -sf ~/.dotfiles/.config/sketchybar ~/.config/sketchybar
ln -sf ~/.dotfiles/.config/wireshark ~/.config/wireshark
ln -sf ~/.dotfiles/.config/zsh ~/.config/zsh

# Enable pre-commit security hook
git config core.hooksPath .githooks

echo "Dotfiles synced and symlinked."
echo "Run 'dotfiles-verify' to check everything is working."
