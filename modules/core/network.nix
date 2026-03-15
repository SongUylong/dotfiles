{
  pkgs,
  host,
  lib,
  ...
}:
{
  # 1. Kernel tweaks to handle 8%+ packet loss and high latency
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr"; # Best for high latency/loss
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_mtu_probing" = 1; # Automatically detects if packets are too big
  };

  # Disable NetworkManager-wait-online to speed up boot
  systemd.services.NetworkManager-wait-online.enable = false;

  networking = {
    hostName = "${host}";
    networkmanager.enable = true;

    # Force a safe MTU for your physical ethernet interface (eno1)
    # This prevents packet fragmentation which causes "hanging" websites
    # Only apply to desktop - laptop uses WiFi and may not have eno1
    interfaces = lib.mkIf (host != "laptop") {
      eno1.mtu = 1492;
    };

    nameservers = [
      "1.1.1.1" # Prioritizing Cloudflare (usually faster in SE Asia)
      "8.8.8.8"
      "8.8.4.4"
    ];

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
        59010
        59011
      ];
      allowedUDPPorts = [
        59010
        59011
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    mtr # Traceroute + Ping tool
    nload # Bandwidth monitor
  ];
}
