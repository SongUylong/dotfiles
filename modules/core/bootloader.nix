{ pkgs, lib, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot";
      };
      timeout = null;

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        efiInstallAsRemovable = true;
        configurationLimit = 5;
        theme = lib.mkDefault pkgs.catppuccin-grub;
        # Increase timeout to select OS
        gfxmodeEfi = "2560x1440";
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = [ "ntfs" ];

    # Hibernate support
    resumeDevice = "/dev/disk/by-uuid/b4c132d2-c0c2-4991-a3bd-32d04f62c370";
  };

  # Ensure os-prober can detect Windows
  services.gvfs.enable = true;
}
