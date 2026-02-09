{pkgs}:
with pkgs; [
  # Core tools
  fd
  fzf
  ripgrep
  lazygit
  wl-clipboard
  
  # Lua runtime and tools
  lua5_1
  luajitPackages.luarocks
  
  # Image support for image.nvim
  imagemagick

  tmux
  lsof

  # Hypr
  hyprls

  # Nix
  nixd
  alejandra
  statix

  # Python
  pyright
  ruff

  # JavaScript/TypeScript
  vtsls
  biome

  # Lua
  lua-language-server
  stylua

  # Markdown
  markdown-toc
  markdownlint-cli2
  marksman

  # Shell/Bash
  bash-language-server
  shellcheck
  shfmt

  # Docker
  docker-compose-language-service
  dockerfile-language-server
  hadolint

  # SQL
  sqlfluff
  prisma-language-server

  # CSS/HTML/Frontend
  tailwindcss-language-server

  # Tree-sitter
  tree-sitter

  # YAML
  yaml-language-server
]
