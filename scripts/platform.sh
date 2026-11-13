#!/usr/bin/env bash
# Platform-specific system setup that does not fit into a package list.
#   darwin: nothing yet
#   wsl:    /etc/wsl.conf (systemd, default user); Docker comes from Docker Desktop
#   linux:  Docker Engine from the official Docker apt repository
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

PLATFORM="${PLATFORM:-$(detect_platform)}"

# Writes $2 to the root-owned file $1 when the content differs.
install_root_file() {
  local dest="$1" content="$2"
  if [ -f "$dest" ] && [ "$(cat "$dest")" = "$content" ]; then
    return 0
  fi
  log "updating $dest"
  if [ -f "$dest" ]; then
    diff -u "$dest" <(printf '%s\n' "$content") >&2 || true
  else
    printf '%s\n' "$content" >&2
  fi
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log "[dry-run] would write $dest"
    return 0
  fi
  confirm "write $dest?" || { warn "skipped $dest"; return 0; }
  printf '%s\n' "$content" | as_root tee "$dest" >/dev/null
  return 0
}

platform_wsl() {
  install_root_file /etc/wsl.conf "[boot]
systemd=true

[user]
default=$(id -un)

[interop]
appendWindowsPath=true"
  log "if /etc/wsl.conf changed, run 'wsl --shutdown' from Windows to apply it"

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
  local distro="${ID:-debian}" codename="${VERSION_CODENAME:-}"
  [ -n "$codename" ] || die "cannot detect the distribution codename"
  confirm "install Docker Engine from download.docker.com ($distro $codename)?" || {
    warn "skipped Docker Engine"
    return 0
  }
  as_root install -m 0755 -d /etc/apt/keyrings
  as_root curl -fsSL "https://download.docker.com/linux/$distro/gpg" -o /etc/apt/keyrings/docker.asc
  as_root chmod a+r /etc/apt/keyrings/docker.asc
  install_root_file /etc/apt/sources.list.d/docker.sources "Types: deb
URIs: https://download.docker.com/linux/$distro
Suites: $codename
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc"
  as_root apt-get update
  as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  as_root usermod -aG docker "$(id -un)"
  log "log out and back in to use docker without sudo"
}

case "$PLATFORM" in
  darwin) ;;
  wsl)    platform_wsl ;;
  linux)  platform_linux ;;
esac
