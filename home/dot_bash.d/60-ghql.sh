# shellcheck shell=bash
# Ctrl-G: pick a ghq repository with peco and cd into it.

ghql() {
  local root selected
  root="$(cd "${GHQ_ROOT:-$HOME/dev/src}" && pwd -P)" || return
  selected="$(ghq list --full-path | sed -e "s|^${root}/||" | peco)"
  if [ -n "$selected" ]; then
    cd "${root}/${selected}" || return
  fi
}

bind '"\C-g": "\C-a\C-kghql\C-m"'
