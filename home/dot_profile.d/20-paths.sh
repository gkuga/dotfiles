# User-level bin directories. Missing directories are skipped.

export GOPATH="$HOME/dev"

for d in \
  "$HOME/opt/aws-sam-cli" \
  "$HOME/.antigravity/antigravity/bin" \
  "$HOME/.tiup/bin" \
  "$HOME/fvm/default/bin" \
  "$HOME/.pub-cache/bin" \
  "$GOPATH/bin" \
  "$HOME/.cargo/bin" \
  "$HOME/.local/bin" \
  "$HOME/bin"; do
  path_prepend "$d"
done
unset d
