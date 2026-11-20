#!/usr/bin/env bash
# Platform-specific system setup that does not fit into a package list.
#   darwin: Docker Desktop is installed by hand (it updates itself); warn if missing
#   wsl:    /etc/wsl.conf (systemd, default user); checks the Windows-side
#           %USERPROFILE%\.wslconfig, which install.ps1 manages on Windows;
#           Docker comes from Docker Desktop
#   linux:  Docker Engine from the official Docker apt repository
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

PLATFORM="${PLATFORM:-$(detect_platform)}"

# Prints file $1 without carriage returns (Windows-edited files use CRLF) and
# without a leading UTF-8 BOM (Windows editors may add one). Prints nothing for
# a missing file, and fails for one that cannot be read, so that callers never
# mistake an unreadable file for an empty one.
read_text() {
  [ -e "$1" ] || return 0
  [ -r "$1" ] || return 1
  tr -d '\r' <"$1" | sed $'1s/^\xef\xbb\xbf//'
}

# Writes $2 to file $1 when the content differs, after showing the diff and
# asking. With $3 = root the file is written through sudo. A file whose first
# line ends with CRLF is written back with CRLF on every line. A file that
# cannot be read is left unchanged with a warning.
install_file() {
  local dest="$1" content="$2" owner="${3:-user}" current crlf=""
  if ! current="$(read_text "$dest")"; then
    warn "cannot read $dest; leaving it unchanged"
    return 0
  fi
  if [ -f "$dest" ] && [ "$current" = "$content" ]; then
    return 0
  fi
  if [ -f "$dest" ] && head -n 1 "$dest" | grep -q $'\r$'; then
    crlf=1
  fi
  log "updating $dest${crlf:+ (written with CRLF line endings)}"
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
#   - Section and key names match case-insensitively, as WSL reads them, and a
#     comment after a section header is ignored.
#   - A line that already has the wanted value is kept as it is (key spelling,
#     inline comment); a different value is replaced, and later duplicates of
#     KEY in [SECTION] are dropped. Values compare case-sensitively (user names
#     are case-sensitive).
#   - A key missing from the file goes after the section's last line, but before a blank line and
#     the comments after it, which usually introduce the next section. A missing
#     section is appended. Everything else is kept.
ini_set() {
  awk -v sec="$1" -v key="$2" -v val="$3" '
    function isheader(l) { return l ~ /^[[:space:]]*\[/ }
    function header(l) { sub(/\].*/, "]", l); gsub(/[[:space:]]/, "", l); return tolower(l) }
    function keyof(l) {
      if (l ~ /^[[:space:]]*[#;]/ || !index(l, "=")) return ""
      sub(/=.*/, "", l); gsub(/[[:space:]]/, "", l); return tolower(l)
    }
    function valueof(l) {
      sub(/^[^=]*=/, "", l); sub(/[[:space:]]+[#;].*/, "", l)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", l); return l
    }
    function release() { for (i = 1; i <= n; i++) print held[i]; n = 0; holding = 0 }
    function close_section() { if (insec && !done && !found) { print key "=" val; done = 1 }; release() }
    { line[NR] = $0 }
    END {
      want = "[" tolower(sec) "]"; lkey = tolower(key)
      # Is KEY set in any [SECTION] (it may appear more than once)? Then it is
      # updated where it is, not added.
      s = 0
      for (r = 1; r <= NR; r++) {
        if (isheader(line[r])) s = (header(line[r]) == want)
        else if (s && keyof(line[r]) == lkey) found = 1
      }
      for (r = 1; r <= NR; r++) {
        l = line[r]
        if (isheader(l)) { close_section(); insec = (header(l) == want); print l; continue }
        if (insec && keyof(l) == lkey) {
          release()
          if (!done) { if (valueof(l) == val) print l; else print key "=" val }
          done = 1; continue
        }
        if (insec && l ~ /^[[:space:]]*$/) { holding = 1; held[++n] = l; continue }
        if (insec && holding && l ~ /^[[:space:]]*[#;]/) { held[++n] = l; continue }
        release(); print l
      }
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
  local conf profile want
  # An unreadable file gives empty input here; install_file then leaves it.
  conf="$(read_text /etc/wsl.conf || true)"
  conf="$(printf '%s' "$conf" | ini_set boot systemd true)"
  conf="$(printf '%s' "$conf" | ini_set user default "$(id -un)")"
  conf="$(printf '%s' "$conf" | ini_set interop appendWindowsPath true)"
  install_file /etc/wsl.conf "$conf" root

  # .wslconfig (Windows side, all distros) is managed by chezmoi on Windows
  # (install.ps1, home/dot_wslconfig.tmpl). Only check the settings that SSH
  # into WSL depends on, so that two places never write the same file.
  if ! profile="$(windows_profile)" || [ ! -d "$profile" ]; then
    warn "Windows user profile not found; cannot check %USERPROFILE%\\.wslconfig"
  else
    if ! conf="$(read_text "$profile/.wslconfig")"; then
      warn "cannot read $profile/.wslconfig; not checked"
    elif want="$(printf '%s' "$conf" | ini_set wsl2 networkingMode mirrored | ini_set general instanceIdleTimeout -1)" &&
      [ "$want" != "$conf" ]; then
      warn "$profile/.wslconfig lacks [wsl2] networkingMode=mirrored or [general] instanceIdleTimeout=-1"
      warn "  run install.ps1 on Windows (docs/setup-windows.md), then 'wsl --shutdown'"
    fi
  fi
  log "changes to /etc/wsl.conf apply after 'wsl --shutdown' in Windows"
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
