{ ... }:
{
  imports = [
    ./bat.nix                         # better cat command
    ./browser.nix                     # firefox based browser
    ./btop.nix                        # resouces monitor 
    ./cava.nix                        # audio visualizer
    ./discord.nix                     # discord
    ./fastfetch/fastfetch.nix         # fetch tool
    ./fzf.nix                         # fuzzy finder
    ./git.nix                         # version control
    ./gnome.nix                       # gnome apps
    ./gtk.nix                         # gtk theme
    ./hyprland                        # window manager
    ./lazygit.nix
    ./micro.nix                       # nano replacement
    ./nemo.nix                        # file manager
    ./nvim/nvim.nix                   # neovim editor
    ./p10k/p10k.nix
    ./packages                        # other packages
    ./rofi/rofi.nix                   # launcher
    ./../../scripts/scripts.nix       # personal scripts
    ./ssh.nix                         # ssh config
    ./spicetify.nix                   # spotify client
    ./yazi/yazi.nix                   # terminal file manager
    ./swaylock.nix                    # lock screen
    ./swayosd.nix                     # brightness / volume wiget
    ./swaync/swaync.nix               # notification deamon
    ./vscodium                        # vscode fork
    ./waybar                          # status bar
    ./waypaper.nix                    # GUI wallpaper picker
    ./wezterm/wezterm.nix             # terminal with multiplexer
    ./xdg-mimes.nix                   # xdg config
    ./zsh                             # shell
  ];
}
