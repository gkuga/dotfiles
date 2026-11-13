# shellcheck shell=bash
# WSL only.
grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null || return 0

# Open URLs and files with Windows apps (gh auth login, xdg-open, ...).
if command -v wslview >/dev/null 2>&1; then
  export BROWSER=wslview
fi
