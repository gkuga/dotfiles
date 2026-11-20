#!/bin/sh
# Run as the Linux user in the Debian distro by install.ps1 (step debian):
#   sh debian-user.sh [install.sh options]
# Clones the dotfiles inside Linux (the Windows checkout is only used to start
# this script) and runs install.sh there, as on any other WSL machine. After a
# successful run it leaves a marker, so that install.ps1 runs it only until
# it has once gone through.
set -eu
marker="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/installed-by-install.ps1"
repo="$HOME/dev/src/github.com/gkuga/dotfiles"
if [ ! -d "$repo/.git" ]; then
  git clone https://github.com/gkuga/dotfiles.git "$repo"
fi
cd "$repo"
bash ./install.sh "$@"
case " $* " in
  *" --dry-run "*|*" -n "*) ;;
  *) mkdir -p "$(dirname "$marker")" && date >"$marker" ;;
esac
