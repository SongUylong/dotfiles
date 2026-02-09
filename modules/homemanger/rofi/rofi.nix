{ pkgs, ... }:
{
  home.packages = with pkgs; [ rofi ];

  # Theme handled by Stylix
  xdg.configFile."rofi/config.rasi".source = ./config.rasi;
}
