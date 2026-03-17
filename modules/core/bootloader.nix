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
        configurationLimit = 3;
        theme = starWarsGrubTheme;
        # Increase timeout to select OS
        gfxmodeEfi = "2560x1440";
      };
    };
    plymouth = {
      enable = true;
    };

    supportedFilesystems = [ "ntfs" ];
  };

  # Ensure os-prober can detect Windows
  services.gvfs.enable = true;
}
