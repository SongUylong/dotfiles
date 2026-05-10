if [[ "$VSCODE_RESOLVING_ENVIRONMENT" == "1" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/config.zsh"
  return 0
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Shared ZSH (see config.zsh)
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/config.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
