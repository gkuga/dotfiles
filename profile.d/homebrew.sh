#!/bin/sh

script_name=$(basename "$0")
echo $script_name

if [ "$(uname)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
elif [ "$(uname)" = "Darwin" ] && [ "$(uname -m)" = "x86_64" ]; then
  export PATH="/usr/local/bin:$PATH"
else
  echo "skip $script_name"
fi
