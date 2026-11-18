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
# nothing when it does not exist or cannot be read.
read_text() {
  if [ -f "$1" ]; then
    { tr -d '\r' <"$1"; } 2>/dev/null || true
  fi
}

# Writes $2 to file $1 when the content differs, after showing the diff and
# asking. With $3 = root the file is written through sudo. A file that used
# CRLF line endings is written with CRLF again.
install_file() {
  local dest="$1" content="$2" owner="${3:-user}" current crlf=""
  current="$(read_text "$dest")"
  if [ -f "$dest" ] && [ "$current" = "$content" ]; then
    return 0
  fi
  if [ -f "$dest" ] && grep -q $'\r' "$dest" 2>/dev/null; then
    crlf=1
  fi
  log "updating $dest${crlf:+ (CRLF line endings kept)}"
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
  if [ -n "$crlf" ]; then
    content="$(printf '%s\n' "$content" | sed 's/$/\r/')"
  fi
  if [ "$owner" = root ]; then
    printf '%s\n' "$content" | as_root tee "$dest" >/dev/null
  else
    printf '%s\n' "$content" >"$dest"
  fi
  return 0
}

# Reads an INI file on stdin and prints it with KEY=VALUE set in [SECTION].
# With a 4th argument "if-missing", an existing KEY keeps its value.
# Section and key names match case-insensitively (WSL reads them that way),
# and a comment after a section header is ignored. A new key goes right after
# the section's last key, before blank lines and comments that precede the
# next section; a missing section is appended. Everything else is kept.
ini_set() {
  awk -v sec="$1" -v key="$2" -v val="$3" -v mode="${4:-}" '
    function header(l) { sub(/\].*/, "]", l); gsub(/[[:space:]]/, "", l); return tolower(l) }
    function keyof(l) {
      if (l ~ /^[[:space:]]*[#;]/ || !index(l, "=")) return ""
      sub(/=.*/, "", l); gsub(/[[:space:]]/, "", l); return tolower(l)
    }
    function release() { for (i = 1; i <= n; i++) print held[i]; n = 0 }
    function close_section() { if (insec && !done) { print key "=" val; done = 1 }; release() }
    BEGIN { want = "[" tolower(sec) "]"; lkey = tolower(key) }
    /^[[:space:]]*\[/ { close_section(); insec = (header($0) == want); print; next }
    insec && keyof($0) == lkey {
      release()
      if (mode == "if-missing") print
      else if (!done) print key "=" val
      done = 1; next
    }
    insec && ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]*[#;]/) { held[++n] = $0; next }
    { release(); print }
    END {
      close_section()
      if (!done) { if (NR) print ""; print "[" sec "]"; print key "=" val }
    }
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

# Prints the Windows user profile directory as a WSL path (/mnt/c/Users/...).
# PowerShell is asked for UTF-8 without a BOM so that non-ASCII user names
# survive; a BOM is stripped anyway in case one slips through.
windows_profile() {
  local ps win
  ps="$(command -v powershell.exe || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)"
  [ -x "$ps" ] || return 1
  # shellcheck disable=SC2016 # $false is PowerShell's, not a shell variable
  win="$("$ps" -NoProfile -NonInteractive -Command \
    '[Console]::OutputEncoding=(New-Object System.Text.UTF8Encoding $false); [Environment]::GetFolderPath("UserProfile")' \
    </dev/null 2>/dev/null | tr -d '\r' | sed $'1s/^\xef\xbb\xbf//')"
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
  #   defaultVhdSize=128GB      disk limit for distros created later; only
  #                             when not set, so a machine can choose another
  # memory is not managed: the right limit depends on the PC's RAM.
  if profile="$(windows_profile)" && [ -d "$profile" ]; then
    conf="$(read_text "$profile/.wslconfig")"
    conf="$(printf '%s' "$conf" | ini_set wsl2 networkingMode mirrored)"
    conf="$(printf '%s' "$conf" | ini_set wsl2 defaultVhdSize 128GB if-missing)"
    conf="$(printf '%s' "$conf" | ini_set general instanceIdleTimeout -1)"
    install_file "$profile/.wslconfig" "$conf"
  else
    warn "Windows user profile not found: in %USERPROFILE%\\.wslconfig, set by hand"
    warn "  [wsl2] networkingMode=mirrored and [general] instanceIdleTimeout=-1"
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
