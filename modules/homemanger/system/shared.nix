{ config, ... }:
let
  sharedDir = "${config.home.homeDirectory}/dotfiles/shared";
in
{
  home.file = {
    # Zellij
    "${config.xdg.configHome}/zellij".source =
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/zellij";

    # Zsh — shared config for both NixOS and macOS
    "${config.xdg.configHome}/zsh".source = config.lib.file.mkOutOfStoreSymlink "${sharedDir}/zsh";

    # OpenCode config file
    "${config.xdg.configHome}/opencode/opencode.json".source =
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/opencode/opencode.json";

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
