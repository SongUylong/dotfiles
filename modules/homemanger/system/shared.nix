{ config, lib, ... }:
let
  sharedDir = "${config.home.homeDirectory}/dotfiles/shared";
in
{
  home.file = {
    # Zsh — shared config for both NixOS and macOS
    "${config.xdg.configHome}/zsh".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/zsh"
    );

    # OpenCode config file
    "${config.xdg.configHome}/opencode/opencode.json".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/opencode/opencode.json"
    );

    "${config.xdg.configHome}/opencode/tui.json".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/opencode/tui.json"
    );

    # CodeUtility agent skills
    "${config.home.homeDirectory}/.agents/skills".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/codeUtility/.agents/skills"
    );

    # Yazi plugins
    "${config.xdg.configHome}/yazi/plugins".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/plugins"
    );

    # Yazi config files
    "${config.xdg.configHome}/yazi/yazi.toml".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/yazi.toml"
    );

    "${config.xdg.configHome}/yazi/keymap.toml".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/keymap.toml"
    );

    "${config.xdg.configHome}/yazi/package.toml".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${sharedDir}/yazi/package.toml"
    );
  };
}
