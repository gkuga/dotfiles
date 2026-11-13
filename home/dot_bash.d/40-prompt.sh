# shellcheck shell=bash
# Prompt:
#   host:~/dev/src/github.com/gkuga/workspace (main *)
#   $

for f in \
  "${HOMEBREW_PREFIX:-/nonexistent}/etc/bash_completion.d/git-prompt.sh" \
  /usr/lib/git-core/git-sh-prompt \
  /usr/share/git-core/contrib/completion/git-prompt.sh; do
  if [ -r "$f" ]; then
    . "$f"
    break
  fi
done
unset f

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM=auto

__prompt_command() {
  local status=$?
  # Share history between panes: append new lines, then read others' lines.
  history -a
  history -n

  local blue='\[\e[1;34m\]' green='\[\e[1;32m\]' red='\[\e[1;31m\]' reset='\[\e[0m\]'
  local git=""
  if declare -F __git_ps1 >/dev/null; then
    git="$(__git_ps1 ' (%s)')"
  fi
  local mark='\$'
  [ "$status" -ne 0 ] && mark="${red}[${status}]\$${reset}"
  PS1="${blue}\h:\w${green}${git}${reset}\n${mark} "
}
PROMPT_COMMAND=__prompt_command
