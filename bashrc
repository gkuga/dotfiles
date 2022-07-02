# If not running interactively, don't do anything.
# for screen command in this script
[[ "$-" != *i* ]] && return

if [ -d "${HOME}/.bash.d" ] ; then
  for script in "${HOME}"/.bash.d/*.sh ; do
    [ -O "$script" ] && . "$script" && echo load "$script"
  done
  unset script
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

# prompt for screen

if [ $TERM == 'screen' ]; then
  PS1=${PS1}'\[\ek\W\e\\\]'
fi

# User specific aliases and functions

# screen
# if [ -z "$STY" ] && then screen -xRS yasui
screen -xRS yasui

# Aliases

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
bind -x '"\201": ghql'
bind '"\C-g":"\201 \C-j"'
