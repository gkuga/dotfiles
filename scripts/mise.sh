#!/usr/bin/env bash
# Installs mise and the global tools defined in ~/.config/mise/config.toml
# (managed by chezmoi, so run the dotfiles step first).
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

export PATH="$HOME/.local/bin:$PATH"

if ! has mise; then
  if has brew; then
    run brew install mise
  else
    log "installing mise into ~/.local/bin"
    run_installer sh https://mise.run
  fi
fi

if [ ! -f "$HOME/.config/mise/config.toml" ]; then
  warn "$HOME/.config/mise/config.toml not found; run the dotfiles step first"
  exit 0
fi

if [ "${DRY_RUN:-0}" = 1 ]; then
  if has mise; then
    log "tools mise would install:"
    mise ls --global --missing 2>/dev/null || true
  fi
  exit 0
fi

mise install --yes
