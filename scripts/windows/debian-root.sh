#!/bin/sh
# Run as root in the Debian distro by install.ps1 (step debian):
#   sh debian-root.sh USER GITHUB_USER
# Prepares what SSH into WSL needs: the packages for SSH and mDNS (as in
# packages/apt-wsl.txt) and for install.sh, the Linux user with a password for
# sudo, /etc/wsl.conf ([boot] systemd, [user] default), and authorized_keys
# from https://github.com/GITHUB_USER.keys. Every part is skipped when it is
# done already. Exits with 3 when /etc/wsl.conf changed: that takes effect
# after the distro restarts.
set -eu
user="$1"
github="$2"
restart=0

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*"; }

missing=""
for p in openssh-server avahi-daemon libnss-mdns sudo git curl ca-certificates; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed' ||
    missing="$missing $p"
done
if [ -n "$missing" ]; then
  log "installing:$missing"
  apt-get update
  # shellcheck disable=SC2086 # one word per package
  DEBIAN_FRONTEND=noninteractive apt-get install -y $missing
fi

if ! id -u "$user" >/dev/null 2>&1; then
  log "creating the user $user (in the sudo group)"
  useradd --create-home --shell /bin/bash --groups sudo "$user"
fi
# passwd -S prints P in the second field when a usable password is set.
if [ "$(passwd -S "$user" | cut -d' ' -f2)" != P ]; then
  if [ -t 0 ]; then
    log "set a password for $user (sudo asks for it)"
    until passwd "$user"; do :; done
  else
    warn "no terminal: set a password for $user later with: sudo passwd $user"
  fi
fi

# Only missing sections are added; install.sh (step platform) merges the
# rest of /etc/wsl.conf.
conf=/etc/wsl.conf
touch "$conf"
if ! grep -q '^[[:space:]]*\[boot\]' "$conf"; then
  printf '\n[boot]\nsystemd=true\n' >>"$conf"
  restart=1
fi
if ! grep -q '^[[:space:]]*\[user\]' "$conf"; then
  printf '\n[user]\ndefault=%s\n' "$user" >>"$conf"
  restart=1
fi
[ "$restart" = 0 ] || log "updated $conf"

if [ -n "$github" ]; then
  home="$(getent passwd "$user" | cut -d: -f6)"
  group="$(id -gn "$user")"
  file="$home/.ssh/authorized_keys"
  install -d -m 700 -o "$user" -g "$group" "$home/.ssh"
  [ -e "$file" ] || install -m 600 -o "$user" -g "$group" /dev/null "$file"
  if keys="$(curl -fsSL "https://github.com/$github.keys")"; then
    before="$(wc -l <"$file")"
    printf '%s\n' "$keys" | while IFS= read -r key; do
      [ -z "$key" ] || grep -qxF "$key" "$file" || printf '%s\n' "$key" >>"$file"
    done
    after="$(wc -l <"$file")"
    [ "$before" = "$after" ] || log "added $((after - before)) key(s) from github.com/$github.keys to $file"
  else
    warn "could not fetch https://github.com/$github.keys; add keys to $file by hand"
  fi
fi

[ "$restart" = 0 ] || exit 3
