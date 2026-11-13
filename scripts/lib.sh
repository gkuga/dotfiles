# shellcheck shell=bash
# Shared helpers for the provisioning scripts.
# Must stay compatible with macOS /bin/bash 3.2 (no associative arrays,
# no mapfile, no ${var,,}, no |&).

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# DRY_RUN=1 prints every state-changing command instead of executing it.
run() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '\033[2m[dry-run]\033[0m %s\n' "$*" >&2
  else
    "$@"
  fi
}

has() { command -v "$1" >/dev/null 2>&1; }

# Downloads an installer script and runs it: run_installer SHELL URL [ARGS...]
# The whole script is fetched before it runs, so a broken download never runs
# half a script. In a dry run nothing is downloaded.
run_installer() {
  local shell="$1" url="$2" script
  shift 2
  if [ "${DRY_RUN:-0}" = 1 ]; then
    # shellcheck disable=SC2016 # print the command literally
    printf '\033[2m[dry-run]\033[0m %s -c "$(curl -fsSL %s)" -- %s\n' "$shell" "$url" "$*" >&2
    return 0
  fi
  script="$(curl -fsSL "$url")" || die "failed to download $url"
  "$shell" -c "$script" -- "$@"
}

# Prints one of: darwin, wsl, linux.
detect_platform() {
  case "$(uname -s)" in
    Darwin) echo darwin ;;
    Linux)
      if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
        echo wsl
      else
        echo linux
      fi
      ;;
    *) die "unsupported OS: $(uname -s)" ;;
  esac
}

# Runs a command as root, using sudo only when needed.
as_root() {
  if [ "$(id -u)" = 0 ]; then
    run "$@"
  else
    run sudo "$@"
  fi
}

# Reads a package list file, dropping comments and blank lines.
read_list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# Asks a yes/no question. Defaults to "no"; ASSUME_YES=1 answers "yes".
confirm() {
  # In a dry run every action is only printed, so show all of them.
  if [ "${ASSUME_YES:-0}" = 1 ] || [ "${DRY_RUN:-0}" = 1 ]; then
    return 0
  fi
  # Read from the terminal, not stdin: stdin is the script itself when
  # install.sh is piped from curl.
  if ! { : </dev/tty; } 2>/dev/null; then
    return 1
  fi
  printf '%s [y/N] ' "$1" >&2
  read -r reply </dev/tty
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}
