{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
      # Disable Firefox's built-in tracking protection since uBlock handles it
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      
      # Restore previous session on startup
      Preferences = {
        "browser.startup.page" = {
          Value = 3;
          Status = "locked";
        };
        "browser.sessionstore.persist_closed_tabs_between_sessions" = {
          Value = true;
          Status = "locked";
        };
        "browser.sessionstore.closedTabsFromAllWindows" = {
          Value = true;
          Status = "locked";
        };
        "browser.sessionstore.closedTabsFromClosedWindows" = {
          Value = true;
          Status = "locked";
        };
      };
    };
  };

  xdg.mimeApps = {
    associations.added = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}
