# workspace

Scripts and dotfiles that set up my development environment on macOS, WSL and
Linux hosts (Debian-based).

| Layer | Tool | Where |
|---|---|---|
| System packages | Homebrew (macOS), apt (Linux) | [packages/](packages/) |
| Language runtimes and dev tools | [mise](https://mise.jdx.dev) | [home/dot_config/mise/config.toml](home/dot_config/mise/config.toml) |
| Dotfiles | [chezmoi](https://chezmoi.io) | [home/](home/) (see [.chezmoiroot](.chezmoiroot)) |
| Glue | bash (3.2 compatible) | [install.sh](install.sh), [scripts/](scripts/) |

Environment: bash 5, tmux (screen kept for serial consoles), Neovim
(Vim with a minimal config as a fallback), Docker Desktop on macOS/WSL.

## Usage

```sh
# Fresh machine
curl -fsSL https://raw.githubusercontent.com/gkuga/workspace/master/install.sh | bash

# From a checkout
./install.sh --dry-run          # print what would change, change nothing
./install.sh                    # all steps
./install.sh --only dotfiles    # a single step
```

Steps run in this order; each one is idempotent:

| Step | macOS | WSL | Linux host |
|---|---|---|---|
| `packages` | Xcode CLT, Homebrew, `brew bundle` | apt: `apt-common.txt` + `apt-wsl.txt` | apt: `apt-common.txt` + `apt-linux.txt` |
| `dotfiles` | install chezmoi, show the diff, apply after confirmation | same | same |
| `mise` | install mise, `mise install` | same | same |
| `platform` | - | `/etc/wsl.conf` (systemd, default user) | Docker Engine |
| `shell` | Homebrew bash as login shell | already bash 5 | already bash 5 |

On the first `chezmoi init` you are asked for git name/email and GPG signing
settings. Answers are stored in `~/.config/chezmoi/chezmoi.toml` only.

## Machine-specific settings

Kept out of this public repository on purpose:

- `~/.gitconfig.local`: work `url.insteadOf`, credential helpers, ...
- `~/.bashrc.local`: anything else for one machine

## Day-to-day

```sh
chezmoi edit ~/.bashrc     # edit the source in home/, then
chezmoi diff               # review
chezmoi apply              # apply
chezmoi re-add             # copy back files changed in place (e.g. nvim/lazy-lock.json)
```

## Layout

```
install.sh              entry point
scripts/                one script per step + lib.sh
packages/               Brewfile, apt-*.txt
home/                   chezmoi source state (dot_bashrc -> ~/.bashrc, ...)
legacy/                 previous Ansible setup, to be removed
```
