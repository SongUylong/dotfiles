{ config, pkgs, ... }:
let
  colors = config.lib.stylix.colors;
in
{
  stylix.targets.firefox = {
    enable = true;
    profileNames = [ "default" ];
  };

  home.packages = with pkgs; [ google-chrome ];

  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      userChrome = ''
        /* ============================================
         * Modern Minimal Firefox — Stylix Catppuccin
         * Native Vertical Tabs, Clean Toolbar
         * ============================================ */

        /* ── Base Variables ── */
        :root {
          --uc-bg: #${colors.base00};
          --uc-bg-alt: #${colors.base01};
          --uc-bg-hover: #${colors.base02};
          --uc-border: #${colors.base03};
          --uc-fg: #${colors.base05};
          --uc-fg-dim: #${colors.base04};
          --uc-accent: #${colors.base0D};
          --uc-accent-hover: #${colors.base0C};
          --uc-radius: 12px;
          --uc-transition: 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        }

        /* ── Hide native horizontal tab bar ── */
        #TabsToolbar {
          visibility: collapse !important;
          height: 0 !important;
        }

        /* ── Hide title bar spacers and buttons ── */
        .titlebar-spacer,
        .titlebar-buttonbox-container {
          display: none !important;
        }

        /* ── Navigation toolbar — clean and compact ── */
        #nav-bar {
          background: var(--uc-bg) !important;
          border-bottom: 1px solid var(--uc-border) !important;
          padding: 4px 8px !important;
          box-shadow: none !important;
        }

        /* ── URL bar styling ── */
        #urlbar-background {
          background: var(--uc-bg-alt) !important;
          border: 1px solid var(--uc-border) !important;
          border-radius: var(--uc-radius) !important;
          transition: border-color var(--uc-transition),
                      box-shadow var(--uc-transition) !important;
        }

        #urlbar[focused="true"] > #urlbar-background {
          border-color: var(--uc-accent) !important;
          box-shadow: 0 0 0 1px var(--uc-accent) !important;
        }

        #urlbar-input {
          color: var(--uc-fg) !important;
          font-family: inherit !important;
        }

        #tracking-protection-icon-container {
          display: none !important;
        }

        #page-action-buttons {
          display: none !important;
        }

        #reader-mode-button,
        #star-button-box,
        #urlbar-zoom-button {
          display: none !important;
        }

        /* ── Simplify identity box (site info) ── */
        #identity-box {
          padding-inline: 4px !important;
        }

        #identity-icon-box {
          padding-inline: 2px !important;
        }

        /* ── Toolbar buttons — subtle styling ── */
        toolbarbutton {
          transition: background var(--uc-transition) !important;
        }

        toolbarbutton:hover {
          background: var(--uc-bg-hover) !important;
          border-radius: 8px !important;
        }

        /* ── Hide bookmarks toolbar ── */
        #PersonalToolbar {
          display: none !important;
        }

        /* ── Menu/hamburger button ── */
        #PanelUI-button {
          opacity: 0.7;
          transition: opacity var(--uc-transition) !important;
        }

        #PanelUI-button:hover {
          opacity: 1;
        }

        /* ── Findbar styling ── */
        .findbar-container {
          background: var(--uc-bg-alt) !important;
          border-radius: var(--uc-radius) !important;
          padding: 4px !important;
        }

        /* ── Context menus and panels ── */
        menupopup,
        panel {
          --panel-background: var(--uc-bg-alt) !important;
          --panel-border-color: var(--uc-border) !important;
          border-radius: var(--uc-radius) !important;
        }

        /* ── Autocomplete popup (URL suggestions) ── */
        #urlbar .urlbarView {
          background: var(--uc-bg-alt) !important;
          border: 1px solid var(--uc-border) !important;
          border-radius: var(--uc-radius) !important;
          margin-top: 4px !important;
        }

        .urlbarView-row:hover {
          background: var(--uc-bg-hover) !important;
          border-radius: 8px !important;
        }

        .urlbarView-row[selected] {
          background: var(--uc-accent) !important;
          border-radius: 8px !important;
        }

        /* ── Window drag space ── */
        #navigator-toolbox {
          border-bottom: none !important;
          background: var(--uc-bg) !important;
        }

        /* ── Remove extra spacing on top ── */
        #titlebar {
          appearance: none !important;
          -moz-default-appearance: none !important;
        }

        /* ── Compact notification/popup bars ── */
        notification-message {
          background: var(--uc-bg-alt) !important;
          border-radius: var(--uc-radius) !important;
        }
      '';

      userContent = ''
        /* ============================================
         * Style Firefox internal pages
         * ============================================ */

        /* ── New Tab page ── */
        @-moz-document url("about:newtab"), url("about:home") {
          body {
            background-color: #${colors.base00} !important;
            color: #${colors.base05} !important;
          }

          .search-wrapper input {
            background-color: #${colors.base01} !important;
            color: #${colors.base05} !important;
            border: 1px solid #${colors.base03} !important;
            border-radius: 12px !important;
          }

          .search-wrapper input:focus {
            border-color: #${colors.base0D} !important;
            box-shadow: 0 0 0 1px #${colors.base0D} !important;
          }

          /* Hide sponsored content */
          .ds-card-grid,
          section[data-section-id="topstories"] {
            display: none !important;
          }
        }

        /* ── Blank page ── */
        @-moz-document url("about:blank") {
          body {
            background-color: #${colors.base00} !important;
          }
        }

        /* ── Private browsing page ── */
        @-moz-document url("about:privatebrowsing") {
          body {
            background-color: #${colors.base00} !important;
            color: #${colors.base05} !important;
          }
        }
      '';
    };

    policies = {
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };

      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;

      Preferences = {
        # Restore previous session on startup
        "browser.startup.page" = {
          Value = 3;
          Status = "locked";
        };
        # Enable userChrome.css / userContent.css
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };

        # Session restore
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

        # Compact UI mode
        "browser.uidensity" = {
          Value = 1;
          Status = "locked";
        };
        "browser.compactmode.show" = {
          Value = true;
          Status = "locked";
        };

        # Hide bookmarks toolbar
        "browser.toolbars.bookmarks.visibility" = {
          Value = "never";
          Status = "locked";
        };

        # ── Enable Native Vertical Tabs (Sidebar Revamp) ──
        "sidebar.revamp" = {
          Value = true;
          Status = "locked";
        };
        "sidebar.verticalTabs" = {
          Value = true;
          Status = "locked";
        };
        "sidebar.main.tools" = {
          Value = "tabs";
          Status = "locked";
        };
        "sidebar.expanded" = {
          Value = true;
          Status = "locked";
        };

        # Disable new tab page clutter
        "browser.newtabpage.activity-stream.feeds.section.topstories" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.feeds.topsites" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.showSponsored" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = {
          Value = false;
          Status = "locked";
        };

        # Smooth scrolling
        "general.smoothScroll" = {
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
