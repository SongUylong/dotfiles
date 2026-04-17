if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── macOS ZSH config ──────────────────────────────────────────────────────────
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/config.zsh"
