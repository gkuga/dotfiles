#!/usr/bin/env bash
# Platform-specific system setup that does not fit into a package list.
#   darwin: Docker Desktop is installed by hand (it updates itself); warn if missing
#   wsl:    /etc/wsl.conf (systemd, default user) and the Windows-side
#           %USERPROFILE%\.wslconfig (mirrored networking, no idle shutdown,
#           ...); Docker comes from Docker Desktop
#   linux:  Docker Engine from the official Docker apt repository
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

PLATFORM="${PLATFORM:-$(detect_platform)}"

# Prints file $1 without carriage returns (Windows-edited files use CRLF), or
# nothing when it does not exist.
read_text() {
  if [ -f "$1" ]; then
    tr -d '\r' <"$1"
  fi
}

# Writes $2 to file $1 when the content differs, after showing the diff and
# asking. With $3 = root the file is written through sudo.
install_file() {
  local dest="$1" content="$2" owner="${3:-user}" current
  current="$(read_text "$dest")"
  if [ -f "$dest" ] && [ "$current" = "$content" ]; then
    return 0
  fi
  log "updating $dest"
  if [ -f "$dest" ]; then
    diff -u --label "$dest" --label "$dest (new)" \
      <(printf '%s\n' "$current") <(printf '%s\n' "$content") >&2 || true
  else
    printf '%s\n' "$content" >&2
  fi
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log "[dry-run] would write $dest"
    return 0
  fi
  confirm "write $dest?" || { warn "skipped $dest"; return 0; }
  if [ "$owner" = root ]; then
    printf '%s\n' "$content" | as_root tee "$dest" >/dev/null
  else
    printf '%s\n' "$content" >"$dest"
  fi
  return 0
}

# Reads an INI file on stdin and prints it with KEY=VALUE set in [SECTION].
# Everything else (other keys, sections, comments) is kept as it is.
ini_set() {
  awk -v sec="$1" -v key="$2" -v val="$3" '
    function emit() { if (insec && !done) { print key "=" val; done = 1 } }
    /^[[:space:]]*\[/ {
      emit()
      line = $0; gsub(/[[:space:]]/, "", line)
      insec = (line == "[" sec "]")
      print; next
    }
    insec {
      k = $0; sub(/=.*/, "", k); gsub(/[[:space:]]/, "", k)
      if (k == key && index($0, "=")) { if (!done) { print key "=" val; done = 1 }; next }
    }
    { print }
    END { emit(); if (!done) { if (NR) print ""; print "[" sec "]"; print key "=" val } }
  '
}

platform_darwin() {
  # Look for the app, not only the CLI: the CLI links appear on its first
  # launch, and with the "User" CLI location they live in ~/.docker/bin.
  if [ ! -d /Applications/Docker.app ] && [ ! -d "$HOME/Applications/Docker.app" ] && ! has docker; then
    warn "docker not found: install Docker Desktop from https://www.docker.com/products/docker-desktop/"
    warn "(not in the Brewfile: it updates itself)"
  fi
}

# Succeeds when the INI file on stdin has KEY in [SECTION].
ini_has() {
  awk -v sec="$1" -v key="$2" '
    /^[[:space:]]*\[/ { line = $0; gsub(/[[:space:]]/, "", line); insec = (line == "[" sec "]"); next }
    insec { k = $0; sub(/=.*/, "", k); gsub(/[[:space:]]/, "", k); if (k == key && index($0, "=")) found = 1 }
    END { exit !found }
  '
}

# Prints the Windows user profile directory as a WSL path (/mnt/c/Users/...).
# PowerShell is asked for UTF-8 so that non-ASCII user names survive.
windows_profile() {
  local ps win
  ps="$(command -v powershell.exe || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)"
  [ -x "$ps" ] || return 1
  win="$("$ps" -NoProfile -NonInteractive -Command \
    '[Console]::OutputEncoding=[Text.Encoding]::UTF8; [Environment]::GetFolderPath("UserProfile")' \
    </dev/null 2>/dev/null | tr -d '\r')"
  [ -n "$win" ] || return 1
  wslpath -u "$win"
}

platform_wsl() {
  local conf profile
  conf="$(read_text /etc/wsl.conf)"
  conf="$(printf '%s' "$conf" | ini_set boot systemd true)"
  conf="$(printf '%s' "$conf" | ini_set user default "$(id -un)")"
  conf="$(printf '%s' "$conf" | ini_set interop appendWindowsPath true)"
  install_file /etc/wsl.conf "$conf" root

  # .wslconfig (Windows side, all distros):
  #   networkingMode=mirrored   WSL shares the Windows IP address, so other
  #                             machines reach it directly and mDNS works
  #   instanceIdleTimeout=-1    keep the distro running when no session is
  #                             open, so SSH into WSL keeps working
  #   defaultVhdSize=128GB      virtual disk limit for newly created distros
  #   memory                    machine-specific: 12GB only when not set yet
  if profile="$(windows_profile)" && [ -d "$profile" ]; then
    conf="$(read_text "$profile/.wslconfig")"
    if ! printf '%s' "$conf" | ini_has wsl2 memory; then
      conf="$(printf '%s' "$conf" | ini_set wsl2 memory 12GB)"
    fi
    conf="$(printf '%s' "$conf" | ini_set wsl2 networkingMode mirrored)"
    conf="$(printf '%s' "$conf" | ini_set wsl2 defaultVhdSize 128GB)"
    conf="$(printf '%s' "$conf" | ini_set general instanceIdleTimeout -1)"
    install_file "$profile/.wslconfig" "$conf"
  else
    warn "Windows user profile not found: set networkingMode=mirrored under [wsl2]"
    warn "in %USERPROFILE%\\.wslconfig by hand"
  fi
  log "changes to /etc/wsl.conf or .wslconfig apply after 'wsl --shutdown' in Windows"
  log "(not while you depend on SSH into WSL: nothing starts WSL again by itself)"

  if ! has docker; then
    warn "docker not found: enable WSL integration for this distro in Docker Desktop"
    warn "(Settings > Resources > WSL integration)"
  fi
}

platform_linux() {
  if has docker; then
    return 0
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  # download.docker.com only knows debian and ubuntu; derivatives (Mint,
  # Pop!_OS, ...) use the repository of the distribution they are based on.
  local distro="" codename=""
  case "${ID:-}" in
    debian|ubuntu) distro="$ID" codename="${VERSION_CODENAME:-}" ;;
    *)
      case " ${ID_LIKE:-} " in
        *" ubuntu "*) distro=ubuntu codename="${UBUNTU_CODENAME:-}" ;;
        *" debian "*) distro=debian codename="${DEBIAN_CODENAME:-}" ;;
      esac
      ;;
  esac
  [ -n "$distro" ] && [ -n "$codename" ] ||
    die "cannot map ${ID:-this distribution} to a download.docker.com repository; install Docker Engine manually"
  confirm "install Docker Engine from download.docker.com ($distro $codename)?" || {
    warn "skipped Docker Engine"
    return 0
  }
  as_root install -m 0755 -d /etc/apt/keyrings
  as_root curl -fsSL "https://download.docker.com/linux/$distro/gpg" -o /etc/apt/keyrings/docker.asc
  as_root chmod a+r /etc/apt/keyrings/docker.asc
  install_file /etc/apt/sources.list.d/docker.sources "Types: deb
URIs: https://download.docker.com/linux/$distro
Suites: $codename
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc" root
  as_root apt-get update
  as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  as_root usermod -aG docker "$(id -un)"
  log "log out and back in to use docker without sudo"
}

case "$PLATFORM" in
  darwin) platform_darwin ;;
  wsl)    platform_wsl ;;
  linux)  platform_linux ;;
esac
