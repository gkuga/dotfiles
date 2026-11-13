#!/usr/bin/env bash
# Makes bash 5 the login shell.
#   macOS ships bash 3.2 (the last GPLv2 release), so use Homebrew's bash.
#   Debian already ships bash 5 as /bin/bash.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

PLATFORM="${PLATFORM:-$(detect_platform)}"

case "$PLATFORM" in
  darwin)
    target=""
    for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash; do
      [ -x "$candidate" ] && target="$candidate" && break
    done
    [ -n "$target" ] || die "Homebrew bash not found; run the packages step first"
    current="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"
    ;;
  wsl|linux)
    target="/bin/bash"
    current="$(getent passwd "$(id -un)" | cut -d: -f7)"
    ;;
esac

if [ "$current" = "$target" ]; then
  log "login shell is already $target"
  exit 0
fi

if ! grep -qx "$target" /etc/shells; then
  log "adding $target to /etc/shells"
  if [ "${DRY_RUN:-0}" = 1 ]; then
    run "echo $target | sudo tee -a /etc/shells"
  else
    echo "$target" | as_root tee -a /etc/shells >/dev/null
  fi
fi

# Plain `chsh` asks for the user's password through PAM and fails without a
# terminal; through sudo it does not, and sudo is needed above anyway.
if [ "${DRY_RUN:-0}" = 1 ]; then
  as_root chsh -s "$target" "$(id -un)"
  exit 0
fi
confirm "change login shell from $current to $target?" || { warn "login shell unchanged"; exit 0; }
as_root chsh -s "$target" "$(id -un)"
