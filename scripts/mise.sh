#!/usr/bin/env bash
# Installs mise and the global tools defined in ~/.config/mise/config.toml
# (managed by chezmoi, so run the dotfiles step first), and the Claude Code CLI.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

# Same lookup as a login shell, so that tools installed through mise (e.g. a
# claude from npm) are found as well.
export PATH="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims:$HOME/.local/bin:$PATH"

if ! has mise; then
  if has brew; then
    run brew install mise
  else
    log "installing mise into ~/.local/bin"
    run_installer sh https://mise.run
  fi
fi

# Claude Code CLI (used directly and by claudecode.nvim). The native installer
# puts it in ~/.local/bin and keeps it up to date by itself, so it is not a
# mise tool.
if ! has claude; then
  log "installing Claude Code into ~/.local/bin"
  run_installer bash https://claude.ai/install.sh
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
