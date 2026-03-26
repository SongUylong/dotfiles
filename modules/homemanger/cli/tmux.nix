{
  config,
  pkgs,
  lib,
  ...
}:
let
  sharedDir = "${config.home.homeDirectory}/dotfiles/shared";
in
{
  stylix.targets.tmux.enable = false;
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
  };

  home.file."${config.xdg.configHome}/tmux/tmux.conf".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${sharedDir}/tmux/tmux.conf"
  );

  home.file."${config.xdg.configHome}/tmuxinator".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink "${sharedDir}/tmuxinator"
  );
}
