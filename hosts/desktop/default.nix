{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # Hibernate resume device (swap partition on desktop)
  boot.resumeDevice = "/dev/disk/by-uuid/b4c132d2-c0c2-4991-a3bd-32d04f62c370";

}
