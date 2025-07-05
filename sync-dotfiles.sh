#!/bin/bash
# Sync dotfiles and recreate all symlinks

cd ~/.dotfiles

# Pull latest changes
git pull origin main

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
ln -sf ~/.dotfiles/.hyper.js ~/.hyper.js

# Config directories
ln -sf ~/.dotfiles/.config/nvim ~/.config/nvim
ln -sf ~/.dotfiles/.config/ghostty ~/.config/ghostty
ln -sf ~/.dotfiles/.config/yazi ~/.config/yazi
ln -sf ~/.dotfiles/.config/btop ~/.config/btop
ln -sf ~/.dotfiles/.config/minimal-prompt.zsh ~/.config/minimal-prompt.zsh

echo "✅ All dotfiles symlinked successfully!"