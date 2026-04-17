# ──────────────────────────────────────────────────────────────────────────────
# Shared ZSH config — macOS
# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
export PATH="$PATH:$HOME/.composer/vendor/bin"
export PATH="$PATH:$HOME/.spicetify"
export PATH="$HOME/miniconda3/condabin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# ── Zinit ─────────────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  command mkdir -p "${ZINIT_HOME%/*}" && command chmod g-rwX "${ZINIT_HOME%/*}"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ── Plugins ───────────────────────────────────────────────────────────────────
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

fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
# Cache compinit for speed (full check only once every 24h)
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
zinit cdreplay -q

# ── Prompt ────────────────────────────────────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups \
       hist_save_no_dups hist_find_no_dups hist_ignore_dups histignorealldups

# ── Completion ────────────────────────────────────────────────────────────────
setopt nocaseglob nocasematch
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ── Key bindings ──────────────────────────────────────────────────────────────
bindkey '^p' history-beginning-search-backward
bindkey '^n' history-beginning-search-forward
unset ZVM_READKEY_ENGINE
bindkey -e

# ── FZF ───────────────────────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(fzf --zsh)"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"

# ── Zoxide ────────────────────────────────────────────────────────────────────
eval "$(zoxide init --cmd cd zsh)"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias c='clear'
alias music='rmpc'
alias nvimd="sudo -E nvim"
alias ls='eza -F --group-directories-first --sort=extension'
alias ll='eza -la --header --group-directories-first --sort=extension'
alias la='eza -a --group-directories-first --sort=extension'
alias ld='eza -d */'
alias lsize='eza -l --sort=size --group-directories-first'
alias ldate='eza -l --sort=modified --group-directories-first'
alias lgit='eza -l --git --group-directories-first'
alias lt='tree -a'
alias nvid='neovide & disown && exit'
alias mux='tmuxinator'
alias cursor='open -a Cursor'
alias webai='open-webui serve --port 1234'

export EDITOR=nvim

# ── SSL / Node ────────────────────────────────────────────────────────────────
export NODE_EXTRA_CA_CERTS=$HOME/.ssl/system-certs.pem

# ── NVM (Lazy Loaded) ─────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
_lazy_load_nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ]           && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ]  && source "$NVM_DIR/bash_completion"
}
for cmd in nvm node npm npx; do
  eval "${cmd}() { _lazy_load_nvm; ${cmd} \"\$@\"; }"
done

# Auto-switch node version from .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    nvm use default 2>/dev/null
  fi
}
add-zsh-hook chpwd load-nvmrc
# REMOVED: startup `load-nvmrc` call to keep launch instant

# ── TheFuck (Lazy Loaded) ─────────────────────────────────────────────────────
fk() {
  unset -f fk
  eval $(thefuck --alias fk)
  fk "$@"
}

# ── Pyenv ─────────────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --no-rehash -)"

# ── Yazi helper ───────────────────────────────────────────────────────────────
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
