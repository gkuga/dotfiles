# Setting up Windows

The Windows side of a PC that runs WSL: the apps installed with winget, the
files that live in the Windows user profile (`%USERPROFILE%\.wslconfig` and
the coding-agent rules for the Windows build of Claude Code), and WSL itself.
Debian inside WSL is set up afterwards with [setup-wsl.md](setup-wsl.md).

`install.ps1` runs in the Windows PowerShell 5.1 that comes with Windows.

## 1. Run install.ps1

At the PC or over Remote Desktop, not over SSH: some installers, and
`wsl --install`, show a UAC prompt on the Windows screen.

On a new PC, in PowerShell:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/gkuga/dotfiles/main/install.ps1)))
```

It installs Git with winget if needed, clones the repository into
`%USERPROFILE%\dev\src\github.com\gkuga\dotfiles` and runs the checkout's
`install.ps1`. With options, or from an existing checkout:

```powershell
cd $HOME\dev\src\github.com\gkuga\dotfiles
powershell -ExecutionPolicy Bypass -File install.ps1 -DryRun   # change nothing
powershell -ExecutionPolicy Bypass -File install.ps1           # all steps
powershell -ExecutionPolicy Bypass -File install.ps1 -Only dotfiles
```

`-ExecutionPolicy Bypass` applies to that one run. If an administrator has set
the policy with Group Policy, it wins, and the scripts may not run at all.

| Step | What it does |
|---|---|
| `packages` | `winget install` for each ID in `packages/winget.txt` that is missing; warns if Docker Desktop is missing |
| `dotfiles` | installs chezmoi, shows the diff, applies it after confirmation |
| `wsl` | checks that WSL is installed; installs the Debian distro after confirmation |

| Prompt | Answer |
|---|---|
| WSL memory limit such as 12GB | a limit that fits the PC's RAM, or Enter for the WSL default (half of the RAM) |
| install with winget: ...? | `y` |
| apply these dotfile changes? | `y` after reading the diff |
| install the Debian distro? | `y` on a new PC |

## 2. What chezmoi manages on Windows

The same `home/` as on the other machines, but Windows only gets what
`home/.chezmoiignore` leaves for it:

- `%USERPROFILE%\.wslconfig`, from `home/dot_wslconfig.tmpl`: mirrored
  networking, no idle shutdown, `defaultVhdSize=128GB`, and `memory` when one
  was given on `chezmoi init`. The whole file is managed: a change made in the
  file or in the WSL Settings app is undone by the next `chezmoi apply`, so
  change the template instead. It takes effect after `wsl --shutdown`.
- `%USERPROFILE%\.config\agents\AGENTS.md` and `%USERPROFILE%\.claude\CLAUDE.md`:
  the rules for coding agents, the same as on the Mac and WSL.
- `%USERPROFILE%\.claude\settings.json`, only when it does not exist yet.

The answer to the memory prompt is stored in
`%USERPROFILE%\.config\chezmoi\chezmoi.toml` only. To change it, edit
`wslMemory` there and run `chezmoi apply`.

> [!WARNING]
> `wsl --shutdown` stops every distro, and nothing starts them again by
> itself. If you only reach WSL over SSH, you lose access until someone starts
> it at the PC.

## 3. WSL

If WSL itself is missing, the `wsl` step prints the command for an
administrator PowerShell (`wsl --install --no-distribution`); restart Windows
and run `install.ps1` again. The Debian distro is installed without starting
it: run `wsl -d Debian` once to create the Linux user, then continue with
[setup-wsl.md](setup-wsl.md).

## 4. Once, by hand

- Docker Desktop: install it from docker.com (it updates itself, so it is not
  in `winget.txt`), then enable the Debian distro under Settings > Resources >
  WSL integration.
- Windows Terminal: Settings > Startup > Default profile: Debian, so that a
  new terminal opens WSL. (Not managed: after a distro is created again, the
  old profile stays in the list under the same name.)
- Claude Code (Windows build) and Claude: log in.

## Updating

```powershell
cd $HOME\dev\src\github.com\gkuga\dotfiles
git pull
powershell -ExecutionPolicy Bypass -File install.ps1
```

Apps update through winget (`winget upgrade`) or by themselves.
