{ config, lib, ... }:
lib.mkIf (!config.desktop.useCaelestia) {
  stylix.targets.waybar.enable = false;

  programs.waybar = {
    enable = true;
  };
}
