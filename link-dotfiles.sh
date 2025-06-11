
#!/bin/bash

set -e

echo "🔗 Creating symlinks for dotfiles..."

# Symlink for Neovim
if [ -d "$HOME/.config/nvim" ]; then
  echo "❌ ~/.config/nvim already exists. Skipping..."
else
  ln -s "$HOME/dotfiles/config/nvim" "$HOME/.config/nvim"
  echo "✅ Linked nvim config"
fi

# Symlink for WezTerm
if [ -d "$HOME/.config/wezterm" ]; then
  echo "❌ ~/.config/wezterm already exists. Skipping..."
else
  ln -s "$HOME/dotfiles/config/wezterm" "$HOME/.config/wezterm"
  echo "✅ Linked wezterm config"
fi

# Symlink for .zshrc
if [ -f "$HOME/.zshrc" ]; then
  echo "❌ ~/.zshrc already exists. Skipping..."
else
  ln -s "$HOME/dotfiles/home/.zshrc" "$HOME/.zshrc"
  echo "✅ Linked .zshrc"
fi

echo "🎉 All done!"
