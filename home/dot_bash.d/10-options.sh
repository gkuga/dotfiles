# shellcheck shell=bash

shopt -s checkwinsize cdspell no_empty_cmd_completion
# bash 4+ only; ignored quietly on macOS /bin/bash 3.2.
shopt -s globstar autocd dirspell 2>/dev/null # ** recursion, cd by typing a dir name

# History: large, deduplicated, shared between tmux panes (see 40-prompt.sh).
shopt -s histappend cmdhist
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '
HISTIGNORE='ls:ll:la:pwd:exit:clear:history'
