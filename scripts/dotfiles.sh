#!/usr/bin/env bash
# Installs chezmoi and applies the dotfiles in home/ (see .chezmoiroot).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

if ! has chezmoi; then
  if has brew; then
    run brew install chezmoi
  else
    log "installing chezmoi into $BIN_DIR"
    run mkdir -p "$BIN_DIR"
    run sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
  fi
fi

if [ "${DRY_RUN:-0}" = 1 ]; then
  if has chezmoi; then
    log "changes chezmoi would make (nothing is written to \$HOME):"
    # Use a throwaway config and state so that a dry run leaves no trace.
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cz() { chezmoi --source "$REPO_DIR" --config "$tmp/chezmoi.toml" --persistent-state "$tmp/state.boltdb" "$@"; }
    cz init
    cz diff || true
  else
    log "would run: chezmoi init --apply --source $REPO_DIR"
  fi
  exit 0
fi

# Show what is going to change before touching existing files.
chezmoi init --source "$REPO_DIR"
if [ -n "$(chezmoi diff)" ]; then
  chezmoi diff
  confirm "apply these dotfile changes?" || die "aborted; nothing was applied"
fi
chezmoi apply
