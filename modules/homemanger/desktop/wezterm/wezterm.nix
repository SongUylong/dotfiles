{ pkgs, ... }:
{
  stylix.targets.wezterm.enable = true;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ../../../../shared/wezterm/wezterm.lua;
  };
}
