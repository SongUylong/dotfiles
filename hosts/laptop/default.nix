{ pkgs, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    acpi
    brightnessctl
    cpupower-gui
    powertop
    mangohud
    gamemode
    polychromatic
    (pkgs.writeScriptBin "network" (builtins.readFile ../../scripts/scripts/network.sh))
  ];

  services = {
    power-profiles-daemon.enable = false;

    thermald.enable = true;

    upower.enable = true;

    earlyoom.enable = true;
    earlyoom.extraArgs = [
      "-m"
      "10"
      "-s"
      "10"
    ];

    logind.settings.Login = {
      HoldoffTimeoutSec = "0s";
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend-then-hibernate";
      HandleLidSwitchDocked = "ignore";
    };

    tlp.settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "power";

      AMD_GPU_MIN_FREQ_ON_AC = "low";
      AMD_GPU_MIN_FREQ_ON_BAT = "low";

      GPU_BOOST_ON_AC = 1;
      GPU_BOOST_ON_BAT = 0;

      NVIDIA_POWER_PROFILE_ON_AC = 0;
      NVIDIA_POWER_PROFILE_ON_BAT = 3;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";

  systemd.sleep.extraConfig = "HibernateDelaySec=10min";

  systemd.services.create-swapfile = {
    description = "Create swapfile for hibernation";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '\
        if [ ! -f /swapfile ]; then \
          truncate -s 32G /swapfile; \
          chmod 600 /swapfile; \
          mkswap /swapfile; \
        fi; \
        swapon /swapfile 2>/dev/null || true'";
    };
  };

  boot = {
    kernelModules = [
      "acpi_call"
      "asus_nb_wmi"
      "hid_asus"
      "asus_wmi"
      "leds-asus-nb-wmi"
      "hid_rog"
      "usbhid"
    ];
    extraModulePackages =
      with config.boot.kernelPackages;
      [
        acpi_call
        cpupower
      ]
      ++ [ pkgs.cpupower-gui ];
    kernelParams = [
      # "nousb"  # Disabled - slows boot
      "usbcore.autosuspend=-1"
      "usbcore.old_scheme_first=y"
      "atkbd.reset=x"
      "i8042.nomux=1"
      "i8042.reset=1"
      "amd_iommu=soft"
      "processor.max_cstate=1"
      "amd_pstate=active"
      "rtc_cmos.use_acpi_alarm=1"
      "transparent_hugepage=always"
      "nohz_full=1-15"
      "rcu_nocbs=1-15"
      "isolcpus=1-15"
      "mitigations=off"
      "sysctl.fs.file-max=524288"
      "vm.swappiness=10"
      "vm.vfs_cache_pressure=50"
    ];

    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

  # Optimize NVIDIA for laptops
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = pkgs.linuxPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
      };
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:6:0:0";
    };
  };

  systemd.services.disable-usb-port = {
    description = "Disable faulty USB port 3-4";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 3-4 > /sys/bus/usb/drivers/usb/unbind 2>/dev/null || true'";
    };
  };

  services.udev = {
    extraRules = ''
      # Disable faulty USB port 3-4 on boot
      ACTION=="add", SUBSYSTEM=="usb", ATTR{../port}=="3-4", ATTR{authorized}="0"
    '';
  };

  systemd.services.keyboard-backlight = {
    description = "Enable keyboard backlight";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'for led in /sys/class/leds/*:kbd_backlight; do [ -f $led/brightness ] && echo 3 > $led/brightness 2>/dev/null; done'";
    };
  };
}
