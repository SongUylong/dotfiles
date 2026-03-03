{ pkgs, ... }:

pkgs.code-cursor.overrideAttrs (oldAttrs: rec {
  version = "2.2.44";
  
  src = pkgs.fetchurl {
    url = "https://downloader.cursor.sh/linux/appImage/x64";
    name = "cursor-${version}.AppImage";
    # You'll need to update this hash after the first build attempt
    # Run: nix-prefetch-url https://downloader.cursor.sh/linux/appImage/x64
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
})
