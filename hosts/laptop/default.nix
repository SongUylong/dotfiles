{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    ./../../modules/core/hardware-laptop.nix
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
    asusctl
    (pkgs.writeScriptBin "network" (builtins.readFile ../../scripts/scripts/network.sh))
  ];

  services = {
    power-profiles-daemon.enable = false;

    # thermald is Intel-only and has no effect on AMD CPUs (ROG G17 uses Ryzen)
    thermald.enable = false;

    # asusctl: ASUS ROG fan curve, power profiles, and keyboard lighting control
    asusd.enable = true;
    asusd.enableUserService = true;

    # supergfxctl: manages NVIDIA dGPU power state (Hybrid/Integrated/vfio)
    # Keeping dGPU in Integrated mode when unused is the biggest thermal/battery win
    supergfxd.enable = true;

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
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # AMD GPU: let the driver manage clocks dynamically; avoid pinning min freq to low
      # on AC so the GPU can ramp when needed without thermal spikes from sudden jumps
      AMD_GPU_MIN_FREQ_ON_AC = "low";
      AMD_GPU_MIN_FREQ_ON_BAT = "low";
      AMD_GPU_MAX_FREQ_ON_BAT = "low";

      GPU_BOOST_ON_AC = 1;
      GPU_BOOST_ON_BAT = 0;

      # NVIDIA dGPU: on battery use max power saving (Runtime D3 handled by fine-grained PM)
      NVIDIA_POWER_PROFILE_ON_AC = 0;
      NVIDIA_POWER_PROFILE_ON_BAT = 3;

      # Runtime PM for PCIe devices (lets NVIDIA dGPU enter D3 when idle on AC too)
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";

      # Disk: aggressive power saving on battery
      DISK_APM_LEVEL_ON_BAT = "128";
      DISK_SPINDOWN_TIMEOUT_ON_BAT = "1";

      # Battery longevity: keep charge between 20-80% (avoids top/bottom stress)
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
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
      # Use writeShellScript to avoid quoting conflicts in NixOS string escaping
      ExecStart = pkgs.writeShellScript "create-swapfile" ''
        if [ ! -f /swapfile ]; then
          truncate -s 32G /swapfile
          chmod 600 /swapfile
          mkswap /swapfile
        fi
        swapon /swapfile 2>/dev/null || true
      '';
    };
  };

  boot = {
    kernelModules = [
      "acpi_call"
      "asus_nb_wmi"
      "hid_asus"
      "asus_wmi"
      # leds-asus-nb-wmi removed: module not found on this kernel, causes boot error
      # hid_rog removed: module not found on this kernel, causes boot error
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
      # atkbd.reset=x removed: '=x' is invalid, causes 19x error/retry spam at boot
      # amd_iommu=soft removed: unknown AMD-Vi option, causes boot warning
      "i8042.nomux=1"
      "i8042.reset=1"
      # processor.max_cstate=1 removed: capping C-states at C1 prevents deep CPU sleep,
      # keeps the CPU warmer, and wastes power. AMD CPUs manage C-states well natively.
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

  # Optimize NVIDIA for laptops (PRIME offload + fine-grained power management)
  # Fine-grained power management allows the dGPU to fully power off when idle,
  # which is the single biggest source of heat reduction in PRIME offload mode.
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = lib.mkForce true;
    powerManagement.finegrained = lib.mkForce true;
    open = false;
    nvidiaSettings = true;
    package = pkgs.linuxPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # adds `nvidia-offload` helper command
      };
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:5:0:0"; # boot log confirms AMD iGPU at bus 05 (was wrongly set to 6)
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
