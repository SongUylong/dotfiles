{ pkgs, ... }:
{
  stylix.targets.tmux.enable = false;
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 50000;
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    focusEvents = true;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      tmux-sessionx
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum;
        extraConfig = "set -g @continuum-restore 'on'";
      }
      catppuccin
    ];

    extraConfig = ''
      # Enable True color support
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -gq allow-passthrough on

      --bind 'tab:down,btab:up' \
      set -g pane-base-index 1
      set -g detach-on-destroy off

      # Utility bindings
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf

      unbind %
      bind | split-window -h -c "#{pane_current_path}"

      unbind '"'
      bind - split-window -v -c "#{pane_current_path}"

      unbind v
      bind v copy-mode

      # Kill pane without confirmation

      # vim shell navigations and selects in tmux panes
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection

      # Sesh keybinds
      # sesh w/ gum dir selector
      bind-key "K" display-popup -E -w 40% "sesh connect \"$(
          sesh list -i | gum filter --no-strip-ansi --limit 1 --placeholder 'Pick session' --prompt='🛸 '
      )\""

      # sesh w/ (tmux fzf)
      bind-key "T" run-shell "sesh connect \"$(
              sesh list --icons | fzf-tmux -p 90%,80% \
              --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
              --header '🔑 ^a all | ^t tmux | ^g conf | ^x zoxide | ^d tmux kill | ^f find' \
              --bind 'ctrl-a:change-prompt(🛸  )+reload(sesh list --icons)' \
              --bind 'ctrl-t:change-prompt(◧  )+reload(sesh list -t --icons)' \
              --bind 'ctrl-g:change-prompt(⛯  )+reload(sesh list -c --icons)' \
              --bind 'ctrl-x:change-prompt(🗃  )+reload(sesh list -z --icons)' \
              --bind 'ctrl-f:change-prompt(🔭  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
              --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(👽  )+reload(sesh list --icons)' \
              --preview-window 'right:55%' \
              --preview 'sesh preview {}'
      )\""

      # tmux goodies
      bind-key -r f run-shell "tmux neww ~/scripts/tmux-sessionizer.sh"
      bind-key n command-prompt "new-session -s '%%'"

      # tmux display popups
      bind-key C-y display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "yazi"
      bind-key C-t display-popup -d "#{pane_current_path}" -w 80% -h 80% -E "zsh"
      bind-key C-g display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "lazygit"
      bind-key C-m display-popup -w 95% -h 95% -E "rmpc"

      # Drag copy using mouse
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # Configure SessionX
      set -g @sessionx-bind 'o'

      # Configure Catppuccin
      set -g @catppuccin_flavor "mocha"
      set -g @catppuccin_status_background "none"
      set -g @catppuccin_window_status_style "none"
      set -g @catppuccin_pane_status_enabled "off"
      set -g @catppuccin_pane_border_status "off"

      # status left look and feel
      set -g status-left-length 100
      set -g status-left ""
      set -ga status-left "#{?client_prefix,#{#[bg=#{ @thm_red},fg=#{ @thm_bg},bold]  #S },#{#[bg=#{ @thm_bg},fg=#{ @thm_green}]  #S }}"
      set -ga status-left "#[bg=#{ @thm_bg},fg=#{ @thm_overlay_0},none]│"
      set -ga status-left "#[bg=#{ @thm_bg},fg=#{ @thm_blue}]  #{=/-32/...:#{s|$USER|~|:#{b:pane_current_path}}} "
      set -ga status-left "#[bg=#{ @thm_bg},fg=#{ @thm_overlay_0},none]#{?window_zoomed_flag,│,}"
      set -ga status-left "#[bg=#{ @thm_bg},fg=#{ @thm_yellow}]#{?window_zoomed_flag,  zoom ,}"

      # status right look and feel
      set -g status-right-length 250
      set -g status-right ""

      # Configure Tmux
      set -g status-position bottom
      set -g status-style "bg=#{ @thm_bg}"
      set -g status-justify "absolute-centre"

      # window look and feel
      set -wg automatic-rename on
      set -g automatic-rename-format "#{pane_current_command}"

      set -g window-status-format " #I#{?#{!=:#{window_name},Window},: #W,} "
      set -g window-status-style "bg=#{ @thm_bg},fg=#{ @thm_overlay_0}"
      set -g window-status-last-style "bg=#{ @thm_bg},fg=#{ @thm_overlay_1}"

      set -g window-status-activity-style "bg=#{ @thm_red},fg=#{ @thm_bg}"
      set -g window-status-bell-style "bg=#{ @thm_red},fg=#{ @thm_bg},bold"
      set -gF window-status-separator "#[bg=#{ @thm_bg},fg=#{ @thm_overlay_0}]│"

      set -g window-status-current-format " #I#{?#{!=:#{window_name},Window},: #W,} "
      set -g window-status-current-style "bg=#{ @thm_blue},fg=#{ @thm_bg},bold"

      # Active Pane Highlighting (Differentiate inactive vs active)
      set -g window-style "fg=#585b70,bg=#11111b" # Inactive: Dimmer text, Crust background
      set -g window-active-style "fg=#cdd6f4,bg=#1e1e2e" # Active: Bright text, Base background
      
      # Pane border lines (Thicker border)
      set -g pane-border-lines heavy
      set -g pane-active-border-style "fg=#fab387"
      set -g pane-border-style "fg=#313244"
    '';
  };
}
