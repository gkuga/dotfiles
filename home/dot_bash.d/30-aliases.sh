# shellcheck shell=bash

# GNU ls (Linux) and recent BSD ls (macOS) both understand --color.
if ls --color=auto / >/dev/null 2>&1; then
  alias ls='ls -hF --color=auto'
else
  export LSCOLORS=Gxfxcxdxbxegedabagacad
  alias ls='ls -hFG'
fi
alias ll='ls -l'
alias la='ls -lA'
alias l='ls -CF'

alias df='df -h'
alias du='du -h'
alias less='less -R'
alias grep='grep --color=auto'
alias whence='type -a'

# Fall back to plain vim (minimal ~/.vimrc) where neovim is not installed.
command -v nvim >/dev/null 2>&1 && alias vim='nvim'
alias k='kubectl'
