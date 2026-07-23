
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── macOS ZSH config ──────────────────────────────────────────────────────────
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/config.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Added by Antigravity
export PATH="/Users/eric/.antigravity/antigravity/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Added by Antigravity IDE
export PATH="/Users/eric/.antigravity-ide/antigravity-ide/bin:$PATH"


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

# OpenClaw Completion
[ -f "/Users/eric/.openclaw/completions/openclaw.zsh" ] && source "/Users/eric/.openclaw/completions/openclaw.zsh"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/eric/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Node Version Manager (NVM) — lazy-loaded in ~/.config/zsh/config.zsh, don't re-source here

# Force OpenClaw Path
export PATH="$HOME/.nvm/versions/node/v24.13.0/bin:$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<



# Added by Antigravity CLI installer
export PATH="/Users/eric/.local/bin:$PATH"
