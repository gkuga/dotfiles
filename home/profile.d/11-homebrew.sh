#!/bin/sh

if [ "$(uname)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="/opt/homebrew/sbin:$PATH"
elif [ "$(uname)" = "Darwin" ] && [ "$(uname -m)" = "x86_64" ]; then
  export PATH="/usr/local/bin:$PATH"
  export PATH="/usr/local/sbin:$PATH"
else
  echo "skip homebrew script"
fi
