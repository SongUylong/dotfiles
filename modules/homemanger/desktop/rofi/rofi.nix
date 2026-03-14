{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (!config.desktop.useCaelestia) {
  home.packages = with pkgs; [ rofi ];

  stylix.targets.rofi.enable = true;

  # Theme handled by Stylix
  xdg.configFile."rofi/config.rasi".source = ./config.rasi;
  xdg.configFile."rofi/theme.rasi".source = ./theme.rasi;
}
