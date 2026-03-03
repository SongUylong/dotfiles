{ ... }:
{
  imports = [ ./default.nix ];

  # ---------------------------------------------------------------------------
  # Desktop shell toggle
  # Set to true  → Caelestia shell (bar, launcher, notifications, idle)
  # Set to false → Classic stack  (Waybar, Rofi, SwayNC, hypridle)
  # ---------------------------------------------------------------------------
  desktop.useCaelestia = false;
}
