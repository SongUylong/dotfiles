{ pkgs, lib, ... }:
let
  starWarsGrubTheme = pkgs.stdenv.mkDerivation {
    name = "star-wars-grub-theme";
    src = lib.cleanSourceWith {
      src = ../../star-wars-posters-grub-theme;
      filter =
        path: type:
        let
          baseName = baseNameOf path;
        in
        baseName != ".git";
    };
    installPhase = ''
      cp -r $src $out
      chmod -R 755 $out
    '';
  };
in
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
        theme = starWarsGrubTheme;
        # Increase timeout to select OS
        gfxmodeEfi = "2560x1440";
      };
    };
    plymouth = {
      enable = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = [ "ntfs" ];

    # Hibernate support
    resumeDevice = "/dev/disk/by-uuid/b4c132d2-c0c2-4991-a3bd-32d04f62c370";
  };

  # Ensure os-prober can detect Windows
  services.gvfs.enable = true;
}
