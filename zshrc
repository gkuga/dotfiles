# prompt settings
source ~/.git-prompt.zsh
precmd () { __git_ps1 "%n" ":%~$ " "|%s" }

# go
export GOPATH=$HOME/dev
export PATH=$PATH:$(go env GOPATH)/bin

# Flutter
export PATH=$PATH:$HOME/fvm/default/bin

##############################################
# Aliases
##############################################

# change 'ls' color
export LSCOLORS=Gxfxcxdxbxegedabagacad
alias ls="ls -G"
alias ll="ls -lG"
alias la="ls -laG"
