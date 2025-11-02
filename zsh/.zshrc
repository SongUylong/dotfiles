# ------------------------------------------------------------------------------
# Powerlevel10k Instant Prompt - Must stay at the top
# ------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------------------------
# Manual PATH additions (match Bash config)
# ------------------------------------------------------------------------------
export PATH="/opt/lampp/bin:$PATH"
export PATH="$HOME/.nvm/versions/node/v23.6.0/bin:$PATH"
export PATH="$HOME/miniconda3/condabin:$PATH"
export PATH="$HOME/bin:$PATH"
# ------------------------------------------------------------------------------
# Zinit Setup (Plugin Manager)
# ------------------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
  command mkdir -p "${ZINIT_HOME%/*}" && command chmod g-rwX "${ZINIT_HOME%/*}"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
    print -P "%F{33} %F{34}Installation successful.%f%b" || \
    print -P "%F{160} The clone has failed.%f%b"
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
alias cursor='~/Applications/cursor.AppImage --no-sandbox'
alias nvid='neovide & disown && exit'
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
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'"
  export PATH="$HOME/.local/bin:$PATH"

# ------------------------------------------------------------------------------
# Zoxide Integration
# ------------------------------------------------------------------------------
eval "$(zoxide init --cmd cd zsh)"

# ------------------------------------------------------------------------------
# TheFuck Integration
# ------------------------------------------------------------------------------

export PATH="$PATH:$HOME/.config/composer/vendor/bin"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
export PATH="$HOME/.local/bin:$PATH"

export EDITOR=nvim
## yazi

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

eval $(thefuck --alias fk)
eval "$(pyenv init -)"
export PATH="$PATH:/Users/eric/.composer/vendor/bin"
