# ------------------------------------------------------------------------------
# Powerlevel10k Instant Prompt - Must stay at the top
# ------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------------------------
# Manual PATH additions
# ------------------------------------------------------------------------------
# XAMPP (if installed)
export PATH="/opt/lampp/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export PATH="$NVM_DIR/versions/node/$(nvm version 2>/dev/null)/bin:$PATH"

# Miniconda (if installed)
export PATH="$HOME/miniconda3/condabin:$PATH"

# Local binaries
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Composer
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# ------------------------------------------------------------------------------
# Zinit Setup (Plugin Manager)
# ------------------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  print -P "%F{33} Installing Zinit Plugin Manager…%f"
  command mkdir -p "${ZINIT_HOME%/*}" && command chmod g-rwX "${ZINIT_HOME%/*}"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
    print -P "%F{33} Installation successful.%f" || \
    print -P "%F{160} Clone failed.%f"
fi

source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ------------------------------------------------------------------------------
# Zinit Plugins & Snippets
# ------------------------------------------------------------------------------
zinit ice depth=1; zinit light romkatv/powerlevel10k

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light hlissner/zsh-autopair

zinit snippet OMZP::git
zinit snippet OMZP::command-not-found
zinit snippet OMZP::docker
zinit snippet OMZP::npm

autoload -U compinit && compinit
zinit cdreplay -q

# ------------------------------------------------------------------------------
# Prompt Configuration
# ------------------------------------------------------------------------------
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_NEX

# ------------------------------------------------------------------------------
# Key Bindings
# ------------------------------------------------------------------------------
bindkey '^p' history-beginning-search-backward
bindkey '^n' history-beginning-search-forward

# ------------------------------------------------------------------------------
# History Settings
# ------------------------------------------------------------------------------
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_dups
setopt histignorealldups

# ------------------------------------------------------------------------------
# Case-Insensitive Path Matching
# ------------------------------------------------------------------------------
setopt nocaseglob
setopt nocasematch

# ------------------------------------------------------------------------------
# Completion Setup & Styling
# ------------------------------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------
alias c='clear'
cursor() {
    # The '&' puts it in background, 'disown' detaches it completely
    ~/cursor/cursor.AppImage "$@" >/dev/null 2>&1 & disown
}
alias music='rmpc'
alias nvimd="sudo -E nvim"
alias ls='lsd -F --group-dirs first --sort extension'
alias ll='lsd -la --header --long --group-dirs first --sort extension'
alias la='lsd -a --group-dirs first --sort extension'
alias ld='lsd -d */'
alias lsize='lsd -l --blocks size --group-dirs first'
alias ldate='lsd -l --sort time --group-dirs first'
alias lgit='lsd -l --git --group-dirs first'
alias lt='tree -a'
alias nvid='neovide & disown'
alias airport='xdg-terminal-exec --app-id=com.omarchy.Omarchy --title=Omarchpods /usr/bin/python3 /opt/omarchpods/ui/main.py 2>&1'
# ------------------------------------------------------------------------------
# Fzf Integration
# ------------------------------------------------------------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(fzf --zsh)"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"

# ------------------------------------------------------------------------------
# Zoxide Integration
# ------------------------------------------------------------------------------
eval "$(zoxide init --cmd cd zsh)"

# ------------------------------------------------------------------------------
# TheFuck Integration
# ------------------------------------------------------------------------------
eval $(thefuck --alias fk)

# ------------------------------------------------------------------------------
# Editor
# ------------------------------------------------------------------------------
export EDITOR=nvim

# ------------------------------------------------------------------------------
# Yazi Function
# ------------------------------------------------------------------------------
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

. "$HOME/.local/share/../bin/env"
# eval "$(pyenv init -)"
# eval "$(mise activate zsh)"
export PATH="$HOME/.local/bin:$PATH"
