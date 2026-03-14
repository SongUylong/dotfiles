{
  config,
  pkgs,
  inputs,
  ...
}:
let
  nvimConfDir = "${config.home.homeDirectory}/dotfiles/shared/nvim";
in
{
  stylix.targets.neovim.enable = false;
  home = {
    sessionVariables = {
      EDITOR = "nvim";
    };

    packages = import ./packages.nix { inherit pkgs; };

    # Symlink nvim config files (LazyVim needs writable lock files)
    file = {
      "${config.xdg.configHome}/nvim/lua" = {
        source = config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/lua";
        recursive = true;
      };

      "${config.xdg.configHome}/nvim/lazy-lock.json".source =
        config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/lazy-lock.json";

      "${config.xdg.configHome}/nvim/lazyvim.json".source =
        config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/lazyvim.json";

      "${config.xdg.configHome}/nvim/stylua.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/stylua.toml";

      "${config.xdg.configHome}/nvim/.neoconf.json".source =
        config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/.neoconf.json";
    };
  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # for nixd lsp

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    # Inline init.lua - just bootstraps lazy.nvim
    initLua = ''
      -- bootstrap lazy.nvim, LazyVim and your plugins
      require("config.lazy")
    '';
  };
}
