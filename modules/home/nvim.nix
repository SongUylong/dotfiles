{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;
    
    # Additional packages needed for LazyVim
    extraPackages = with pkgs; [
      # Lua runtime and tools (5.1 required for image.nvim)
      lua5_1
      luajitPackages.luarocks
      
      # Image support for image.nvim
      imagemagick
      
      # LSP servers
      lua-language-server
      nil # Nix LSP
      
      # Formatters
      stylua
      nixpkgs-fmt
      
      # Tools
      ripgrep
      fd
      lazygit
      
      # Clipboard support
      wl-clipboard
    ];
  };

  # Copy nvim configuration to make it writable for LazyVim
  # This allows LazyVim to manage lazyvim.json and lazy-lock.json
  home.activation.nvimConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Create nvim config directory if it doesn't exist
    mkdir -p ${config.home.homeDirectory}/.config/nvim
    
    # Sync the config from the repo, making files writable
    ${pkgs.rsync}/bin/rsync -av --chmod=u+w \
      ${../../nvim}/ \
      ${config.home.homeDirectory}/.config/nvim/
  '';
}
