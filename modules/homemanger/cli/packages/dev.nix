{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Compiler
    gcc

    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

    ## Python
    python3
    python312Packages.ipython

    ## Node.js
    nodejs_22 # or nodejs_20, nodejs_18
    playwright-driver
    chromium
    # nodePackages.npm  # included with nodejs
    # nodePackages.yarn
    nodePackages.pnpm
    bun


    ## AI Tools
    opencode

    ## Code Editors
    code-cursor
    zed-editor

    ## Rust
    rustc
    cargo
  ];

  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
  };
}
