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
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
#export PATH="/opt/homebrew/opt/binutils/bin:$PATH"
export PATH="$PATH:$(brew --prefix)/opt/binutils/bin"
export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"

# for gpg over screen
export GPG_TTY=$(tty)

export PATH=/Users/gkuga/.tiup/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

# AsyncAPI CLI Autocomplete

ASYNCAPI_AC_ZSH_SETUP_PATH=/Users/gkuga/Library/Caches/@asyncapi/cli/autocomplete/zsh_setup && test -f $ASYNCAPI_AC_ZSH_SETUP_PATH && source $ASYNCAPI_AC_ZSH_SETUP_PATH; # asyncapi autocomplete setup



# Added by Antigravity
export PATH="/Users/gkuga/.antigravity/antigravity/bin:$PATH"

# Added by Cargo
export PATH="/Users/gkuga/.cargo/bin:$PATH"
