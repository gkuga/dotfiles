# If not running interactively, don't do anything.
# for screen command in this script
[[ "$-" != *i* ]] && return

if [ -d "${HOME}/.bash.d" ] ; then
  for script in "${HOME}"/.bash.d/*.sh ; do
    [ -O "$script" ] && . "$script" && echo load "$script"
  done
  unset script
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# prompt settings
function parse_git_branch {
    git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ [\1]/'
}

function prompt {
  local BLUE="\[\e[1;34m\]"
  local GREEN="\[\e[1;32m\]"
  local RESET="\[\e[0m\]"
  PS1="${BLUE}\h:\w${GREEN}\$(parse_git_branch)${RESET}\$ "
}

prompt

# User specific aliases and functions

# Default to human readable figures
alias df='df -h'
alias du='du -h'

# Misc :)
alias less='less -r'                          # raw control characters
alias whence='type -a'                        # where, of a sort
alias grep='grep --color'                     # show differences in colour
alias egrep='egrep --color=auto'              # show differences in colour
alias fgrep='fgrep --color=auto'              # show differences in colour

# Some shortcuts for different directory listings
alias ls='ls -hF --color=tty'                 # classify files in colour
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
alias ll='ls -l'                              # long list
alias la='ls -A'                              # all but . and ..
alias l='ls -CF'                              #

# k8s
alias k='kubectl'

# peco
function ghql() {
  local git_base_path=`echo $HOME/dev/src/github.com`
  local selected_file=$(ghq list --full-path | sed -e "s|${git_base_path}/||" | peco)
  if [ -n "$selected_file" ]; then
    cd ${git_base_path}/${selected_file}
    pwd
  fi
}

bind '"\C-g":"ghql \C-j"'

# AWS
function aws-configure() {
  local selected_profile=$(aws configure list-profiles | peco)
  if [ -n "$selected_profile" ]; then
    export AWS_PROFILE=$selected_profile
  fi
}
# bind -x '"\202": aws-configure'
# bind '"\C-l\C-a":"\202 \C-j"'
bind '"\C-laws":"aws-configure \C-j"'

# Usacloud
function usacloud-configure() {
  local selected_profile=$(usacloud config list | grep -v '* ' | peco)
  #usacloud config use $selected_profile
  echo $selected_profile
}
bind '"\C-lusa":"usacloud-configure \C-j"'
