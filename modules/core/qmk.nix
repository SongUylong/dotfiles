{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    via
    vial
    qmk
    qmk-udev-rules
  ];

  services.udev.packages = with pkgs; [
    via
    vial
    qmk-udev-rules
  ];

  # qmk-udev-rules references the 'plugdev' group; create it so udevd
  # doesn't log "Unknown group 'plugdev'" warnings on every udev reload.
  users.groups.plugdev = { };
}
