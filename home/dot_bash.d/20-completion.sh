# shellcheck shell=bash
# bash-completion v2 (Homebrew bash-completion@2 on macOS, bash-completion on Debian).

# bash-completion v2 needs bash 4+, so skip it on macOS /bin/bash 3.2.
if [ "${BASH_VERSINFO[0]}" -ge 4 ] && ! shopt -oq posix; then
  for f in \
    "${HOMEBREW_PREFIX:-/nonexistent}/etc/profile.d/bash_completion.sh" \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion; do
    if [ -r "$f" ]; then
      . "$f"
      break
    fi
  done
  unset f
fi
