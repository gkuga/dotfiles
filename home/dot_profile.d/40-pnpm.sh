if [ "$(uname -s)" = Darwin ]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
path_prepend "$PNPM_HOME"
