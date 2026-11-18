# Setting up a new WSL distro

From an empty Debian distro on Windows 11 to the same environment as the other
machines: bash 5, chezmoi-managed dotfiles, mise, the same git identity and
signing key, and `*.local` names over mDNS.

Placeholders: `<keyid>` is the GPG signing key ID, `<email>` the git email,
`<old>` an already set-up machine (usually the Mac), `<new>` the SSH alias of
the new WSL distro.

## 1. Windows: create the distro

In PowerShell:

```powershell
wsl --install -d Debian
```

Create the Linux user when the distro first starts.

Mirrored networking lets WSL share the Windows IP address, so other machines
on the LAN reach WSL directly and mDNS works. Add this to
`%USERPROFILE%\.wslconfig`, then run `wsl --shutdown` and start the distro again:

```ini
[wsl2]
networkingMode=mirrored
```

> [!WARNING]
> `wsl --shutdown`, `wsl --unregister` and `reboot` inside WSL stop the distro,
> and nothing starts it again by itself. If you only reach WSL over SSH, you
> lose access until someone starts it at the PC. Do these at the console or
> over Remote Desktop.

## 2. Distro console: the minimum for remote access

These need the distro console (or Remote Desktop); everything after this can
run over SSH.

```sh
grep -A1 '^\[boot\]' /etc/wsl.conf          # systemd=true (the default for new distros)
sudo apt-get update
sudo apt-get install -y openssh-server avahi-daemon libnss-mdns
install -d -m 700 ~/.ssh
echo '<your ssh public key>' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

`avahi-daemon` and `libnss-mdns` make `<windows-hostname>.local` resolvable on
the LAN (they are also in `packages/apt-wsl.txt`). WSL's DNS tunneling does not
pass on the mDNS answers that Windows gets, so Linux has to speak mDNS itself.
WSL ships the Hyper-V firewall rules that allow it.

Optional, to let the setup run unattended over SSH:

```sh
echo "$(id -un) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(id -un) >/dev/null
sudo chmod 440 /etc/sudoers.d/$(id -un)
sudo visudo -c -f /etc/sudoers.d/$(id -un)
```

On `<old>`, add an alias to `~/.ssh/config`, with `ProxyJump` when the LAN is
only reachable through a jump host:

```
Host <new>
HostName <windows-hostname>.local
User <linux-user>
```

## 3. Install the packages

```sh
sudo apt-get install -y git curl ca-certificates
git clone https://github.com/gkuga/dotfiles.git ~/dev/src/github.com/gkuga/dotfiles
cd ~/dev/src/github.com/gkuga/dotfiles
./install.sh --only packages
```

`wslu` is skipped on distros that do not ship it (Debian 13 does not).

## 4. Copy keys and machine-specific settings from `<old>`

Run these on `<old>`. With `ProxyJump` the data is encrypted end to end;
jump hosts only relay it.

```sh
scp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub ~/.ssh/config <new>:.ssh/
scp ~/.ssh/<other-keys>.pem <new>:.ssh/           # keys that ~/.ssh/config refers to
ssh <new> 'chmod 600 ~/.ssh/id_ed25519 ~/.ssh/config ~/.ssh/*.pem'
scp ~/.gitconfig.local <new>:
gpg --export-secret-keys --armor <keyid> | ssh <new> 'gpg --batch --import'
gpg --export-ownertrust | ssh <new> 'gpg --import-ownertrust'
```

Exporting the GPG key asks for its passphrase on `<old>`. `gpg` on `<new>`
comes from the packages step, so step 3 must be done first.

`ProxyCommand` lines in `~/.ssh/config` that point to macOS paths (for example
`/opt/homebrew/bin/...`) do not work on WSL; use the bare command name so that
`PATH` finds it on both.

## 5. Dotfiles, tools and checks

Interactively:

```sh
cd ~/dev/src/github.com/gkuga/dotfiles && ./install.sh
```

| Prompt | Answer |
|---|---|
| Git user.name | Enter (the default) |
| Git user.email | `<email>`; do not leave it empty |
| Sign git commits with GPG | Enter (`true`) |
| GPG signing key ID | `<keyid>` |
| apply these dotfile changes? | `y` after reading the diff |
| write /etc/wsl.conf? | `y` only at the console; it takes effect after `wsl --shutdown` |

Unattended over SSH (needs the passwordless sudo from step 2): write the answers
first, then skip the `platform` step, which edits `/etc/wsl.conf`:

```sh
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
[data]
  name = "Gaku Yasui"
  email = "<email>"
  gpgsign = true
  signingkey = "<keyid>"
EOF
./install.sh --yes --only dotfiles,mise,shell > /tmp/install.log 2>&1
```

`chezmoi init` keeps those answers and adds `sourceDir`. Redirecting the output
to a file keeps the install running if the SSH connection drops.

Check in a new login shell (`exec bash -l` on its own line first):

```sh
chezmoi status && chezmoi verify        # no output, then success
ssh -T git@github.com                   # "Hi <user>!"
echo test | gpg --clearsign >/dev/null && echo "gpg signing OK"
getent hosts <some-device>.local
command -v peco nvim claude             # all under ~/.local
```

GitHub's ED25519 host key fingerprint is
`SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`; compare before answering
`yes`.

## 6. Once, by hand

- `nvim`: plugins install on the first start; then `:Copilot auth`.
- `claude`: log in to Claude Code.
- Docker: enable this distro under Docker Desktop's Settings > Resources > WSL
  integration on Windows. Docker is not installed inside WSL.
- `/etc/wsl.conf` (`[user] default=`, `[interop] appendWindowsPath=true`):
  `./install.sh --only platform` at the console, then `wsl --shutdown`.

## Windows from WSL

WSL can run Windows programs as the Windows user (`powershell.exe`, `cmd.exe`,
`winget.exe`, `clip.exe`, `explorer.exe`) and read `/mnt/c`. Commands that need
administrator rights cannot be approved over SSH, because the UAC prompt
appears on the Windows screen; use Remote Desktop for those. In scripts, give
`powershell.exe` `</dev/null`, or it reads the rest of the script from stdin.

Windows' own OpenSSH Server is not a good way in: with OpenSSH for Windows 9.5
an Entra ID account whose name contains non-ASCII characters could not log in
(the connection was closed before authentication), and in mirrored mode its
port 22 clashes with the WSL sshd.
