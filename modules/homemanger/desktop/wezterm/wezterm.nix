{ config, lib, ... }:
let
  sharedDir = "${config.home.homeDirectory}/dotfiles/shared";
in
{
  stylix.targets.wezterm.enable = true;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file."${config.xdg.configHome}/wezterm/wezterm.lua".source =
    lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${sharedDir}/wezterm/wezterm.lua");
}