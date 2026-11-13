# shellcheck shell=bash
# Show the pinentry prompt in the current terminal (also inside tmux/screen).

GPG_TTY="$(tty)"
export GPG_TTY
if command -v gpg-connect-agent >/dev/null 2>&1; then
  gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
fi

alias gpg-unlock='echo unlocking | gpg --clearsign >/dev/null'
