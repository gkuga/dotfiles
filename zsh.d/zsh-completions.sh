if type brew &>/dev/null; then
  fpath=(
    $(brew --prefix)/share/zsh-completions:$FPATH
    $(brew --prefix)/share/zsh/site-functions
    ~/.zsh_completions
    $fpath
  )
  autoload -Uz compinit
  compinit
  zstyle ':completion:*' verbose yes
  zstyle ':completion:*' format '%B%d%b'
  zstyle ':completion:*:warnings' format 'No matches for: %d'
  zstyle ':completion:*' group-name ''
fi

# You may also need to force rebuild `zcompdump`:
# 
#   rm -f ~/.zcompdump; compinit
# 
# Additionally, if you receive "zsh compinit: insecure directories" warnings when attempting
# to load these completions, you may need to run these commands:
#
#   chmod go-w '/opt/homebrew/share'
#   chmod -R go-w '/opt/homebrew/share/zsh'
