#!/bin/bash

set -e

BACKUP_DIR="$HOME/.config-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Backing up current configs to $BACKUP_DIR"

# Backup Neovim config
if [ -e "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$BACKUP_DIR/"
  echo "✅ Backed up ~/.config/nvim"
fi

# Backup WezTerm config (directory or single file)
if [ -e "$HOME/.config/wezterm" ]; then
  mv "$HOME/.config/wezterm" "$BACKUP_DIR/"
  echo "✅ Backed up ~/.config/wezterm"
elif [ -e "$HOME/.wezterm.lua" ]; then
  mv "$HOME/.wezterm.lua" "$BACKUP_DIR/"
  echo "✅ Backed up ~/.wezterm.lua"
fi

# Backup .zshrc
if [ -e "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$BACKUP_DIR/"
  echo "✅ Backed up ~/.zshrc"
fi

echo "🔗 Creating symlinks..."

# Symlink Neovim
ln -s "$HOME/dotfiles/config/nvim" "$HOME/.config/nvim"
echo "✅ Linked ~/.config/nvim"

# Symlink WezTerm directory
ln -s "$HOME/dotfiles/config/wezterm" "$HOME/.config/wezterm"
echo "✅ Linked ~/.config/wezterm"

# Symlink .zshrc
ln -s "$HOME/dotfiles/home/.zshrc" "$HOME/.zshrc"
echo "✅ Linked ~/.zshrc"

echo "🎉 All done! Backups saved in $BACKUP_DIR"
