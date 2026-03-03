{ ... }:
{
  programs.zsh = {
    shellAliases = {
      # Utils (NixOS-specific tools)
      cd = "z";
      tt = "gtrash put";
      cat = "bat";
      nano = "micro";
      code = "codium";
      o = "opencode";
      diff = "delta --diff-so-fancy --side-by-side";
      less = "bat";
      copy = "wl-copy";
      y = "yazi";
      py = "python";
      ipy = "ipython";
      icat = "kitten icat";
      dsize = "du -hs";
      pdf = "tdf";
      open = "xdg-open";
      space = "ncdu";
      man = "batman";

      l = "eza --icons -a --group-directories-first -1 --no-user --long"; # EZA_ICON_SPACING=2
      tree = "eza --icons --tree --group-directories-first";

      # NixOS
      nixconfig = "cd ~/nixos-config && nvim ~/nixos-config";
      ns = "nom-shell --run zsh";
      nd = "nom develop --command zsh";
      nb = "nom build";
      nc = "nh-notify nh clean all --keep 5";
      nft = "nh-notify nh os test";
      nfs = "nh-notify nh os switch";
      nfu = "nh-notify nh os switch --update";
      nsearch = "nh search";

      # Python
      piv = "python -m venv .venv";
      psv = "source .venv/bin/activate";

      # Note: c, nvimd, ls/ll/la/ld/lsize/ldate/lgit/lt, nvid, zellij (zl/za/zk/zd/zda/zka),
      # EDITOR, and y() are defined in shared/zsh/shared.zsh
    };
  };
}
