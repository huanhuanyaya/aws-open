export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

fpath+=${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

alias bat="batcat"
command -v starship >/dev/null && eval "$(starship init zsh)"
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
