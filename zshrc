if [ -d "${HOME}/.zsh.d" ] ; then
  for script in "${HOME}"/.zsh.d/*.sh ; do
    [ -O "$script" ] && . "$script" && echo load "$script"
  done
  unset script
fi

# prompt settings
source ~/.git-prompt.zsh
precmd () { 
  __git_ps1 "%n" ":%~
$ " "|%s"
}

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
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
