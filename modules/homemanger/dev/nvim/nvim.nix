{
  config,
  pkgs,
  lib,
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
      "${config.xdg.configHome}/nvim/init.lua".source = lib.mkForce (
        config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/init.lua"
      );

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

      "${config.xdg.configHome}/nvim/.prettierrc".source =
        config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/.prettierrc";

      "${config.xdg.configHome}/nvim/.clang-format".source =
        config.lib.file.mkOutOfStoreSymlink "${nvimConfDir}/.clang-format";
    };
  };

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # for nixd lsp

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;
  };
}
