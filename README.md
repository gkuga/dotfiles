# dotfiles

Scripts and dotfiles that set up my development environment on macOS, WSL and
Linux hosts (Debian-based), and the Windows side of a PC that runs WSL.

| Layer | Tool | Where |
|---|---|---|
| System packages | Homebrew (macOS), apt (Linux), winget (Windows) | [packages/](packages/) |
| Language runtimes and dev tools | [mise](https://mise.jdx.dev) | [home/dot_config/mise/config.toml](home/dot_config/mise/config.toml) |
| Dotfiles | [chezmoi](https://chezmoi.io) | [home/](home/) (see [.chezmoiroot](.chezmoiroot)) |
| Glue | bash (3.2 compatible); Windows PowerShell 5.1 on Windows | [install.sh](install.sh), [scripts/](scripts/); [install.ps1](install.ps1), [scripts/windows/](scripts/windows/) |

Environment: bash 5, tmux (screen kept for serial consoles), Neovim
(Vim with a minimal config as a fallback), Docker Desktop on macOS/WSL.

## Usage

```sh
# Fresh machine
curl -fsSL https://raw.githubusercontent.com/gkuga/dotfiles/main/install.sh | bash

# Windows (the first step on a new PC, in PowerShell; see docs/setup-windows.md)
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/gkuga/dotfiles/main/install.ps1)))

# From a checkout
./install.sh --dry-run          # print what would change, change nothing
./install.sh                    # all steps
./install.sh --only dotfiles    # a single step
```

Step-by-step guides, including keys and settings that stay out of this
repository:

- [docs/setup-mac.md](docs/setup-mac.md): a new Mac
- [docs/setup-windows.md](docs/setup-windows.md): Windows itself (winget, `.wslconfig`, WSL), before WSL
- [docs/setup-wsl.md](docs/setup-wsl.md): a new WSL distro
- [docs/migrate-mac.md](docs/migrate-mac.md): a Mac still on the old symlinked zsh/asdf setup

Steps run in this order; each one is idempotent:

| Step | macOS | WSL | Linux host |
|---|---|---|---|
| `packages` | Xcode CLT, Homebrew, `brew bundle` | apt: `apt-common.txt` + `apt-wsl.txt` | apt: `apt-common.txt` + `apt-linux.txt` |
| `dotfiles` | install chezmoi, show the diff, apply after confirmation | same | same |
| `mise` | install mise, `mise install` | same | same |
| `platform` | warn if Docker Desktop is missing | `/etc/wsl.conf` (systemd, default user); check `%USERPROFILE%\.wslconfig` | Docker Engine |
| `shell` | Homebrew bash as login shell | already bash 5 | already bash 5 |

On Windows, `install.ps1` takes the same options (`-DryRun`, `-Yes`, `-Only`)
and runs `packages` (winget, per user: `packages/winget.txt`), `dotfiles`
(chezmoi, with only `.wslconfig` and the coding-agent rules), `wsl` (installs
WSL and Debian), `debian` (the Linux user, SSH and mDNS, then `install.sh`
inside Debian) and `tasks` (Task Scheduler tasks from
[scheduled-tasks/](scheduled-tasks/), such as starting WSL at logon), without
administrator rights. See [docs/setup-windows.md](docs/setup-windows.md).

On the first `chezmoi init` you are asked for git name/email and GPG signing
settings (on Windows, only for a WSL memory limit). Answers are stored in
`~/.config/chezmoi/chezmoi.toml` only.
Without a terminal, pass them up front:

```sh
chezmoi init --source . \
  --promptString 'Git user.name=Your Name,Git user.email=you@example.com' \
  --promptBool 'Sign git commits with GPG=false'
```

## Rules for coding agents

`~/.config/agents/AGENTS.md` (source: [home/dot_config/agents/AGENTS.md](home/dot_config/agents/AGENTS.md))
holds the global rules for every coding agent: the language of commits, PRs and
code comments, and cleaning up after a task. Claude Code reads it through an
`@` import in `~/.claude/CLAUDE.md`. `~/.codex/AGENTS.md` is generated from it
by chezmoi, only on machines that use Codex. Windows gets the same two files,
for the Windows build of Claude Code. Rules for one agent only go in
that agent's own section (`~/.claude/CLAUDE.md`, or the "Codex-specific rules"
section of `home/private_dot_codex/AGENTS.md.tmpl`).

## Machine-specific settings

Kept out of this public repository on purpose:

- `~/.gitconfig.local`: work `url.insteadOf`, credential helpers, ...
- `~/.bashrc.local`: anything else for one machine

## AI in Neovim

Once per machine: `claude` (log in to Claude Code) and `:Copilot auth` in Neovim.

| Key | Mode | Action |
|---|---|---|
| `<Tab>` | insert | accept the Copilot suggestion (otherwise snippet jump / tab) |
| `<M-w>` / `<M-]>` / `<M-[>` / `<C-]>` | insert | accept a word / next / previous / dismiss |
| `<leader>ac` / `<leader>af` | normal | toggle / focus the Claude Code terminal |
| `<leader>ar` / `<leader>aC` | normal | start Claude with `--resume` / `--continue` |
| `<leader>am` | normal | select the Claude model |
| `<leader>as` | visual / oil | send the selection / add the file under the cursor |
| `<leader>ab` | normal | add the current buffer to Claude's context |
| `<leader>aa` / `<leader>ad` | normal | accept / deny Claude's proposed diff |
| `<C-q>` | Claude terminal | leave terminal mode (then `<C-w>h` etc. to move) |

While a suggestion is shown, `<Tab>` accepts it: press `<C-]>` first to insert
a real tab. `<M-...>` keys need "Use Option as Meta" in the macOS terminal
settings. Neovim starts the Claude Code IDE server on startup, so `claude` in
another tmux pane can connect with `/ide`.

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
packages/               Brewfile (every Mac), Brewfile.extra (optional), apt-*.txt
home/                   chezmoi source state (dot_bashrc -> ~/.bashrc, ...)
```
