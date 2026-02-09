{ ... }:
{
  programs.micro = {
    enable = true;

    settings = {
      "colorscheme" = "catppuccin-mocha";
      "*.nix" = {
        "tabsize" = 2;
      };
      "*.ml" = {
        "tabsize" = 2;
      };
      "*.asm" = {
        "tabsize" = 2;
      };
      "ft:asm" = {
        "commenttype" = "; %s";
      };
      "makefile" = {
        "tabstospaces" = false;
      };
      "tabstospaces" = true;
      "tabsize" = 4;
      "mkparents" = true;
      "colorcolumn" = 80;
    };
  };

  xdg.configFile."micro/bindings.json".text = ''
    {
      "Ctrl-Up": "CursorUp,CursorUp,CursorUp,CursorUp,CursorUp",
      "Ctrl-Down": "CursorDown,CursorDown,CursorDown,CursorDown,CursorDown",
      "Ctrl-Backspace": "DeleteWordLeft",
      "Ctrl-Delete": "DeleteWordRight",
      "CtrlShiftUp": "ScrollUp,ScrollUp,ScrollUp,ScrollUp,ScrollUp",
      "CtrlShiftDown": "ScrollDown,ScrollDown,ScrollDown,ScrollDown,ScrollDown"
    }
  '';

  xdg.configFile."micro/colorschemes/catppuccin-mocha.micro".text = ''
    color-link default "#cdd6f4"
    color-link comment "#6c7086"
    color-link symbol "#f9e2af"
    color-link constant "#f5c2e7"
    color-link constant.string "#a6e3a1"
    color-link constant.string.char "#a6e3a1"
    color-link identifier "#94e2d5"
    color-link statement "#f38ba8"
    color-link preproc "#f38ba8,#1e1e2e"
    color-link type "#f38ba8"
    color-link special "#f9e2af"
    color-link underlined "underline #1e1e2e"
    color-link error "#f38ba8"
    color-link hlsearch "#1e1e2e,#f9e2af"
    color-link diff-added "#a6e3a1"
    color-link diff-modified "#fab387"
    color-link diff-deleted "#f38ba8"
    color-link gutter-error "#f38ba8"
    color-link gutter-warning "#f9e2af"
    color-link line-number "#585b70"
    color-link current-line-number "#94e2d5"
    color-link cursor-line "#313244"
    color-link color-column "#585b70"
    color-link statusline "#94e2d5"
    color-link tabbar "#cdd6f4,#585b70"
    color-link type "#fab387"
    color-link todo "#f9e2af"
  '';
}
