#!/bin/sh

if [ "$(uname)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
  . /opt/homebrew/opt/asdf/libexec/asdf.sh
else
  . "$HOME/.asdf/asdf.sh"
  . "$HOME/.asdf/completions/asdf.bash"
fi
