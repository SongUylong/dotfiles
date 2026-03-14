{ pkgs, ... }:
{
  services = {
    gvfs.enable = true;

    gnome = {
      tinysparql.enable = true;
      gnome-keyring.enable = true;
    };

    dbus.enable = true;
    fstrim.enable = true;

    # needed for GNOME services outside of GNOME Desktop
    dbus.packages = with pkgs; [
      gcr
      gnome-settings-daemon
    ];

    logind.settings.Login = {
      # don't shutdown when power button is short-pressed
      HandlePowerKey = "ignore";
    };

    udisks2.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP-LaserJet-M26a";
        location = "Local";
        deviceUri = "usb://HP/LaserJet%20Pro%20MFP%20M26a?serial=CNBKK81FN9&interface=1";
        model = "drv:///hp/hpcups.drv/hp-laserjet_pro_mfp_m26a.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "HP-LaserJet-M26a";
  };
}
