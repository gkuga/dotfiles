# peco
function ghql() {
  local git_base_path=$(realpath "$HOME/dev/src/github.com")
  local selected_file=$(ghq list --full-path | sed -e "s|${git_base_path}/||" | peco)
  if [ -n "$selected_file" ]; then
    cd ${git_base_path}/${selected_file}
    pwd
    zle reset-prompt
  fi
}
zle -N ghql
bindkey '^G' ghql
