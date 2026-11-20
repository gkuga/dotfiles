#!/bin/sh
# Run as the Linux user in the Debian distro by install.ps1 (step debian):
#   sh debian-user.sh [install.sh options]
# Clones the dotfiles inside Linux (the Windows checkout is only used to start
# this script) and runs install.sh there, as on any other WSL machine.
set -eu
repo="$HOME/dev/src/github.com/gkuga/dotfiles"
if [ ! -d "$repo/.git" ]; then
  git clone https://github.com/gkuga/dotfiles.git "$repo"
fi
cd "$repo"
exec bash ./install.sh "$@"
