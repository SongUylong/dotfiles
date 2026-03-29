{ pkgs, config, ... }:
let
  ddcutil-wrapper = pkgs.writeShellScriptBin "ddcutil" ''
    REAL_DDCUTIL="${pkgs.ddcutil}/bin/ddcutil"

    if [[ "$1" == "setvcp" && "$2" == "10" ]]; then
        shift 2
        value="$1"
        
        displays=$($REAL_DDCUTIL detect 2>/dev/null | grep "^Display" | sed 's/Display //')
        
        for display in $displays; do
            $REAL_DDCUTIL --display $display setvcp 10 $value 2>/dev/null &
        done
        wait
    else
        exec $REAL_DDCUTIL "$@"
    fi
  '';
in
{
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        (intel-vaapi-driver.override { enableHybridCodec = true; })
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    # NVIDIA GPU Configuration
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false; # Use proprietary driver (not open-source kernel module)
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
  };

  hardware.enableRedistributableFirmware = true;

  # Load NVIDIA driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # Bluetooth services
  services.blueman.enable = true;

  # Fan control and monitor brightness (ddcutil)
  environment.systemPackages = with pkgs; [ lm_sensors ] ++ [ ddcutil-wrapper ];

  # Create i2c group for ddcutil
  users.groups.i2c = { };

  # Udev rules for ddcutil (external monitor brightness control)
  services.udev.extraRules = ''
    SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
  '';

  # Enable kernel modules for fan control and ddcutil
  boot.kernelModules = [
    "coretemp"
    "nct6775"
    "i2c-dev"
  ];

  # Enable GPU fan control via Coolbits
  environment.etc."X11/xorg.conf.d/10-nvidia-coolbits.conf".text = ''
    Section "Device"
        Identifier "NVIDIA GPU"
        Driver "nvidia"
        Option "Coolbits" "4"
    EndSection
  '';
}
