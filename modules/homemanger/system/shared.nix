{ config, ... }:
let
  sharedDir = "${config.home.homeDirectory}/nixos-config/shared";
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  home.file = {
    # Zellij
    "${config.xdg.configHome}/zellij".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/shared/zellij";

    # Zsh — shared config for both NixOS and macOS
    "${config.xdg.configHome}/zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/shared/zsh";

    # OpenCode — shared config for both NixOS and macOS
    "${config.xdg.configHome}/opencode".source =
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/opencode";

    # Yazi plugins
    "${config.xdg.configHome}/yazi/plugins".source =
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/plugins";

    # Yazi config files
    "${config.xdg.configHome}/yazi/yazi.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/yazi.toml";

    "${config.xdg.configHome}/yazi/keymap.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/keymap.toml";

    "${config.xdg.configHome}/yazi/package.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/package.toml";
  };
}
