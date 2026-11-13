#!/usr/bin/env bash
# Bootstrap a development environment on macOS, WSL or a Linux host.
#
#   curl -fsSL https://raw.githubusercontent.com/gkuga/workspace/master/install.sh | bash
#   ./install.sh [--dry-run] [--yes] [--only STEP[,STEP...]]
#
# Steps (in order): packages, dotfiles, mise, platform, shell
# Every step is idempotent and can be re-run safely.

set -euo pipefail

REPO_URL="https://github.com/gkuga/workspace.git"
REPO_DIR="${WORKSPACE_DIR:-$HOME/dev/src/github.com/gkuga/workspace}"
ALL_STEPS="packages dotfiles mise platform shell"

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

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
  if [ ! -d "$REPO_DIR/.git" ]; then
    command -v git >/dev/null 2>&1 || {
      echo "git is required. On macOS run: xcode-select --install" >&2
      echo "On Debian/Ubuntu run: sudo apt-get install -y git" >&2
      exit 1
    }
    git clone "$REPO_URL" "$REPO_DIR"
  fi
  exec bash "$REPO_DIR/install.sh" "$@"
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
