#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# macOS dotfile installer
# Symlinks shared/ and macos/ configs into ~/.config/
# Run from the repo root: bash install-macos.sh
# ──────────────────────────────────────────────────────────────────────────────

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED="$REPO_DIR/shared"
MACOS="$REPO_DIR/macos"
CONFIG="$HOME/.config"

echo "→ Repo: $REPO_DIR"

# Helper: symlink with backup
link() {
	local src="$1"
	local dst="$2"
	mkdir -p "$(dirname "$dst")"
	if [ -e "$dst" ] && [ ! -L "$dst" ]; then
		echo "  backing up $dst → $dst.bak"
		mv "$dst" "$dst.bak"
	fi
	ln -sfn "$src" "$dst"
	echo "  linked $dst"
}

echo ""
echo "── Shared configs ──"

# Wezterm (~/.wezterm.lua on macOS)
link "$SHARED/wezterm/wezterm.lua" "$HOME/.wezterm.lua"

# Neovim
link "$SHARED/nvim" "$CONFIG/nvim"

# Zellij
link "$SHARED/zellij" "$CONFIG/zellij"

# OpenCode
link "$SHARED/opencode" "$CONFIG/opencode"

# Yazi (full config + plugins)
link "$SHARED/yazi" "$CONFIG/yazi"

echo ""
echo "── macOS-only configs ──"

# AeroSpace
link "$MACOS/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"

# Borders
link "$MACOS/borders/.config/borders/bordersrc" "$CONFIG/borders/bordersrc"

# SketchyBar
link "$MACOS/sketchybar/.config/sketchybar" "$CONFIG/sketchybar"

# Neovide
link "$MACOS/neovide/.config/neovide" "$CONFIG/neovide"

# Fastfetch (macOS version)
link "$MACOS/fastfetch/.config/fastfetch" "$CONFIG/fastfetch"

echo ""
echo "── Zsh ──"
link "$SHARED/zsh/shared.zsh" "$CONFIG/zsh/shared.zsh"

ZSHRC="$HOME/.zshrc"
SOURCE_LINE="source \"$CONFIG/zsh/shared.zsh\""

if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
	echo "  shared.zsh already sourced in ~/.zshrc"
else
	echo "" >>"$ZSHRC"
	echo "# nixos-config shared zsh" >>"$ZSHRC"
	echo "$SOURCE_LINE" >>"$ZSHRC"
	echo "  added source line to ~/.zshrc"
fi

echo ""
echo "Done. Restart your shell or run: source ~/.zshrc"
