#!/usr/bin/env bash
# Bootstrap a development environment on macOS, WSL or a Linux host.
#
#   curl -fsSL https://raw.githubusercontent.com/gkuga/dotfiles/master/install.sh | bash
#   ./install.sh [--dry-run] [--yes] [--only STEP[,STEP...]]
#
# Steps (in order): packages, dotfiles, mise, platform, shell
# Every step is idempotent and can be re-run safely.

set -euo pipefail

REPO_URL="https://github.com/gkuga/dotfiles.git"
REPO_DIR="${DOTFILES_DIR:-$HOME/dev/src/github.com/gkuga/dotfiles}"
ALL_STEPS="packages dotfiles mise platform shell"

# Not read from "$0": that is just "bash" when piped from curl.
usage() {
  cat >&2 <<'EOF'
Usage: install.sh [--dry-run] [--yes] [--only STEP[,STEP...]]

  -n, --dry-run  print what would change, change nothing
  -y, --yes      answer yes to every confirmation
      --only     run only the given steps
  -h, --help     show this help

Steps (in order): packages, dotfiles, mise, platform, shell
EOF
  exit "${1:-0}"
}

# Kept for the re-exec below; the option loop shifts "$@" away.
ORIG_ARGS=("$@")
STEPS="$ALL_STEPS"
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) export DRY_RUN=1 ;;
    -y|--yes)     export ASSUME_YES=1 ;;
    --only)       shift; STEPS="$(echo "${1:-}" | tr ',' ' ')" ;;
    -h|--help)    usage 0 ;;
    *)            echo "unknown option: $1" >&2; usage 1 ;;
  esac
  shift
done

# When piped from curl there is no checkout yet: clone it, then re-exec.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ ! -f "$SCRIPT_DIR/scripts/lib.sh" ]; then
  if [ "${DRY_RUN:-0}" = 1 ]; then
    # A dry run must not leave a checkout behind in $HOME.
    REPO_DIR="$(mktemp -d)/dotfiles"
    echo "dry-run: using a temporary checkout in $REPO_DIR" >&2
  elif [ -d "$REPO_DIR/.git" ]; then
    echo "using the existing checkout in $REPO_DIR (run git pull there to update it)" >&2
  fi
  if [ ! -d "$REPO_DIR/.git" ]; then
    command -v git >/dev/null 2>&1 || {
      echo "git is required. On macOS run: xcode-select --install" >&2
      echo "On Debian/Ubuntu run: sudo apt-get install -y git" >&2
      exit 1
    }
    git clone "$REPO_URL" "$REPO_DIR"
  fi
  # stdin is the curl pipe here. Hand the terminal to the real run so that
  # installers (Homebrew, sudo) can prompt instead of failing non-interactively.
  # ${a[@]+...} keeps bash 3.2 from failing on an empty array under set -u.
  if { : </dev/tty; } 2>/dev/null; then
    exec bash "$REPO_DIR/install.sh" ${ORIG_ARGS[@]+"${ORIG_ARGS[@]}"} </dev/tty
  fi
  exec bash "$REPO_DIR/install.sh" ${ORIG_ARGS[@]+"${ORIG_ARGS[@]}"}
fi
REPO_DIR="$SCRIPT_DIR"
export REPO_DIR

# shellcheck source=scripts/lib.sh
. "$REPO_DIR/scripts/lib.sh"

PLATFORM="$(detect_platform)"
export PLATFORM
log "platform: $PLATFORM, repo: $REPO_DIR"
[ "${DRY_RUN:-0}" = 1 ] && log "dry-run mode: nothing will be changed"

for step in $STEPS; do
  case " $ALL_STEPS " in
    *" $step "*) ;;
    *) die "unknown step: $step (valid: $ALL_STEPS)" ;;
  esac
  log "step: $step"
  bash "$REPO_DIR/scripts/$step.sh"
done

log "done. Open a new terminal (or run: exec \$SHELL -l)."
