# ------------------------------------------------------------------------------
# Powerlevel10k Instant Prompt - Must stay at the top
# ------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------------------------
# Shared config (macOS + NixOS)
# ------------------------------------------------------------------------------
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/shared.zsh"
