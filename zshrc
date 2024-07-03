if [ -d "${HOME}/.profile.d" ] ; then
  for script in "${HOME}"/.profile.d/*.sh ; do
    [ -O "$script" ] && . "$script" && echo load "$script"
  done
  unset script
fi

if [ -d "${HOME}/.zsh.d" ] ; then
  for script in "${HOME}"/.zsh.d/*.sh ; do
    [ -O "$script" ] && . "$script" && echo load "$script"
  done
  unset script
fi

# prompt settings
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
RPROMPT=\$vcs_info_msg_0_
# PROMPT=\$vcs_info_msg_0_'%# '
zstyle ':vcs_info:git:*' formats '%b'

# peco
function ghql() {
  local git_base_path=`echo $HOME/dev/src/github.com`
  local selected_file=$(ghq list --full-path | sed -e "s|${git_base_path}/||" | peco)
  if [ -n "$selected_file" ]; then
    cd ${git_base_path}/${selected_file}
    pwd
    zle reset-prompt
  fi
}
zle -N ghql
bindkey '^G' ghql

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# go
export GOPATH=$HOME/dev
export PATH=$PATH:$(go env GOPATH)/bin

# Google Cloud SDK
# source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
# source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

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
