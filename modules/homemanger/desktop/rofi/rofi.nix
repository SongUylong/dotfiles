{ pkgs, ... }:
{
  stylix.targets.rofi.enable = true;

  home.packages = with pkgs; [ rofi ];

  # Theme handled by Stylix
  xdg.configFile."rofi/config.rasi".source = ./config.rasi;
  xdg.configFile."rofi/theme.rasi".source = ./theme.rasi;
}
