if type brew &>/dev/null; then
  fpath=(
    ~/.zsh_completions
    $(brew --prefix)/share/zsh-completions:$FPATH
    $(brew --prefix)/share/zsh/site-functions
    $fpath
  )
  autoload -Uz compinit && compinit
  compdef -d make
  compdef _make_override make
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
