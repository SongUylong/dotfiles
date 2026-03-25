{ ... }:
{
  stylix.targets.wezterm.enable = true;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    # Path corrected to reach root/shared/wezterm/wezterm.lua
    extraConfig = builtins.readFile ../../../../shared/wezterm/wezterm.lua;
  };
}