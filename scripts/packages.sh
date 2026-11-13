#!/usr/bin/env bash
# Installs system packages: Homebrew + Brewfile on macOS, apt on Debian-based Linux.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

PLATFORM="${PLATFORM:-$(detect_platform)}"
PKG_DIR="$REPO_DIR/packages"

packages_darwin() {
  if ! xcode-select -p >/dev/null 2>&1; then
    log "installing Xcode Command Line Tools (a GUI dialog will open)"
    run xcode-select --install
    die "re-run install.sh after the Command Line Tools installation finishes"
  fi

  # lib.sh already put an existing Homebrew on PATH.
  if ! has brew; then
    log "installing Homebrew"
    run_installer /bin/bash https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    if [ "${DRY_RUN:-0}" = 1 ]; then
      log "would run: brew bundle --file=$PKG_DIR/Brewfile"
      return
    fi
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  fi

  if [ "${DRY_RUN:-0}" = 1 ]; then
    log "packages not yet installed from Brewfile:"
    brew bundle check --verbose --file="$PKG_DIR/Brewfile" || true
  else
    brew bundle --file="$PKG_DIR/Brewfile"
  fi
}

# Installs the packages listed in the given files, skipping (with a warning)
# any package that does not exist in the configured apt repositories.
apt_install_lists() {
  local wanted="" missing="" pkg
  for list in "$@"; do
    [ -f "$list" ] || continue
    for pkg in $(read_list "$list"); do
      if apt-cache show "$pkg" >/dev/null 2>&1; then
        wanted="$wanted $pkg"
      else
        missing="$missing $pkg"
      fi
    done
  done
  [ -n "$missing" ] && warn "not available in apt, skipped:$missing"
  # shellcheck disable=SC2086 # word splitting is intended
  [ -n "$wanted" ] && as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $wanted
  return 0
}

packages_linux() {
  has apt-get || die "only Debian-based distributions are supported for now"
  as_root apt-get update
  apt_install_lists "$PKG_DIR/apt-common.txt" "$PKG_DIR/apt-$PLATFORM.txt"

  # Debian ships fd as "fdfind"; expose it under its upstream name.
  if has fdfind && ! has fd; then
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
}

case "$PLATFORM" in
  darwin)    packages_darwin ;;
  wsl|linux) packages_linux ;;
esac
