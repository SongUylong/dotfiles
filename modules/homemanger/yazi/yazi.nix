{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # Install optional tools for enhanced previews
  home.packages = with pkgs; [
    exiftool      # for metadata
    fd            # faster find
    ripgrep       # faster grep
    fzf           # fuzzy finder
    zoxide        # directory jumper
    poppler-utils # for PDF previews
    ffmpegthumbnailer # for video thumbnails
    imagemagick   # for image processing
  ];
}
