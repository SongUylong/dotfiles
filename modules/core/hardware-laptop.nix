{ pkgs, lib, ... }:
{
  # Laptop-specific kernel modules — override the shared hardware.nix defaults.
  # coretemp is Intel-only; k10temp is the correct AMD sensor for Ryzen.
  # nct6775 is a desktop superIO chip not present on the ROG G713IM.
  boot.kernelModules = lib.mkForce [
    "k10temp"
    "i2c-dev"
  ];

  # Disable the desktop fan PWM service — the ROG laptop uses asusd (asus_wmi)
  # for fan control via pwm1/pwm2, not nct6795/pwm6.
  systemd.services.fan-pwm-set.enable = false;
}
