{ lib, ... }:
let
  # Bump after `dnf update kernel` (match basename of /mnt/vmlinuz-* on Fedora /boot ext4).
  fedoraKernelRelease = "6.17.1-300.fc43.x86_64";

  fedoraRootUuid = "e2216dbb-8cee-45ea-b987-98e3d07496fa";

  # Everything after `linux /vmlinuz-…` on the GRUB linux line (edit until Fedora boots).
  #
  # `noresume` avoids dracut waiting on a stale/wrong resume= swap (common when dual-booting).
  # `rootfstype=btrfs` helps dracut mount the root fs reliably.
  #
  # Best source (from NixOS, Fedora /boot mounted on /mnt):
  #   grep -E "linux /vmlinuz-${fedoraKernelRelease}" /mnt/grub2/grub.cfg
  # Copy the args after the vmlinuz path; drop $variables — use literals only.
  #
  # If that line uses $kernelopts, boot a Fedora live USB once and run: cat /proc/cmdline
  # Or inspect root mount options (try subvol=@, then subvol=root):
  #   sudo mount /dev/disk/by-uuid/e2216dbb-8cee-45ea-b987-98e3d07496fa /mnt -o subvol=@
  #   grep -v '^#' /mnt/etc/fstab | grep -E 'btrfs|swap'
  fedoraKernelArgs = "root=UUID=${fedoraRootUuid} ro rootfstype=btrfs rootflags=subvol=@ noresume";
in
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  powerManagement.cpuFreqGovernor = "performance";

  boot.resumeDevice = "/dev/disk/by-uuid/b4c132d2-c0c2-4991-a3bd-32d04f62c370";

  boot.loader.grub.useOSProber = lib.mkForce false;

  # At boot: press e on a Fedora entry to add e.g. rd.break=pre-mount for debugging.
  boot.loader.grub.extraEntries = ''
    menuentry "Windows" {
      insmod part_gpt
      insmod fat
      search --no-floppy --fs-uuid --set=root 52F1-0CC8
      chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    }
    menuentry "Fedora" {
      insmod gzio
      insmod part_gpt
      insmod ext2
      search --no-floppy --fs-uuid --set=root 6cd0e68b-63c5-400f-80f3-eeb832806bf5
      linux /vmlinuz-${fedoraKernelRelease} root=UUID=${fedoraRootUuid} ro rootfstype=btrfs rootflags=subvol=root noresume
      initrd /initramfs-${fedoraKernelRelease}.img
    }
  '';

  # One-time: sudo rm -rf /boot/EFI/fedora ; efibootmgr -v
}
