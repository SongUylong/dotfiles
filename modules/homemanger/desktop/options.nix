{ lib, ... }:
{
  options.desktop.useCaelestia = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use the Caelestia shell (bar, launcher, notifications, idle). Set to false for the classic Waybar/Rofi/SwayNC stack.";
  };
}
