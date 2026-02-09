{ pkgs, ... }:
{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };

  # Link the WezTerm Lua configuration
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}
