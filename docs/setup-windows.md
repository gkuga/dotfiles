# Setting up Windows

The Windows side of a PC that runs WSL: the apps installed with winget, the
files that live in the Windows user profile (`%USERPROFILE%\.wslconfig` and
the coding-agent rules for the Windows build of Claude Code), WSL itself, and
a scheduled task that starts WSL at logon.
Debian inside WSL is set up afterwards with [setup-wsl.md](setup-wsl.md).

`install.ps1` runs in the Windows PowerShell 5.1 that comes with Windows.

## A new PC, in order

At the PC or over Remote Desktop, until SSH into WSL works:

1. In PowerShell (not as administrator: elevated, `install.ps1` warns and
   asks first), run the one-liner from step 1. It installs the apps, writes
   `.wslconfig`, and offers to install WSL: answer `y` and approve the one UAC
   prompt. Restart Windows. The logon task is not registered yet: it waits
   for Debian.
2. Run `install.ps1` again (see "From an existing checkout" below). It
   adds the Hyper-V firewall rule that lets SSH into WSL (a second UAC
   prompt), installs Debian, then sets it up (step `debian`): the Linux user and its
   password, `openssh-server` and mDNS, `authorized_keys` from
   `github.com/gkuga.keys`, a restart of the distro, and `install.sh` inside
   it, where you answer the chezmoi prompts. Last, it registers the logon
   task.
3. Stay logged on to Windows. From now on, the rest can run over SSH: copy
   the keys and machine settings (step 4 of [setup-wsl.md](setup-wsl.md)),
   and run `install.ps1` again through `powershell.exe` when this repository
   changes.

## 1. Run install.ps1

Nothing in `install.ps1` needs an administrator except installing WSL
itself and adding the Hyper-V firewall rule for SSH into WSL, which it does
only after you answer `y` (one UAC prompt each, on a new PC; with `-Yes` it
prints the commands instead). Apps are installed with
`winget --scope user`; every package in `winget.txt` has a per-user installer
(check a new one with `winget show --id ID --scope user`, and keep out one
whose installer still asks for elevation). So later runs do not show a UAC
prompt and also work over SSH (through WSL, with `powershell.exe`). An app
whose winget package has no per-user installer (`Google.Chrome`) is the other
exception: on a PC where it is not installed yet, install it once by hand.

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
| `packages` | `winget install --scope user` for each ID in `packages/winget.txt` that is missing; warns if Docker Desktop is missing |
| `dotfiles` | installs chezmoi, shows the diff, applies it after confirmation |
| `wsl` | installs WSL (one UAC prompt), adds the Hyper-V firewall rule for SSH into WSL (one UAC prompt), and installs the Debian distro, each after confirmation |
| `debian` | in Debian: packages for SSH and mDNS, the Linux user, `/etc/wsl.conf`, `authorized_keys` from GitHub; then `install.sh` inside it, until chezmoi is set up there |
| `tasks` | makes the Task Scheduler folder `\dotfiles-<user SID>\` match `scheduled-tasks/*.xml` |

| Prompt | Answer |
|---|---|
| WSL memory limit with GB or MB such as 12GB | a limit that fits the PC's RAM, or Enter for the WSL default (half of the RAM) |
| install with winget: ...? | `y` |
| apply these dotfile changes? | `y` after reading the diff |
| install WSL now? | `y` on a new PC, then approve the UAC prompt and restart Windows |
| add the rule now? (Hyper-V firewall, TCP 22) | `y`, then approve the UAC prompt |
| install the Debian distro? | `y` on a new PC |
| Linux user name for Debian | Enter for `gkuga` |
| New password (in Debian) | the password for `sudo` |
| restart Debian now to apply /etc/wsl.conf? | `y` at the PC (it stops SSH sessions into WSL) |
| run install.sh in Debian as ...? | `y`; then answer as in step 5 of [setup-wsl.md](setup-wsl.md) |
| register / update scheduled task ...? | `y` |
| remove scheduled task ... (no XML for it)? | `y`, unless you still want it |

## 2. What chezmoi manages on Windows

The same `home/` as on the other machines, but Windows only gets what
`home/.chezmoiignore` leaves for it:

- `%USERPROFILE%\.wslconfig`, from `home/dot_wslconfig.tmpl`: mirrored
  networking, no idle shutdown, `defaultVhdSize=128GB`, and `memory` when one
  was given on `chezmoi init`. The whole file is managed: a change made in the
  file or in the WSL Settings app is undone by the next `chezmoi apply`, so
  change the template instead. Settings that are only in an existing file
  (`processors`, `swap`, ...) are dropped: the diff shows them before
  `apply`, so move what you want to keep into the template first. It takes
  effect after `wsl --shutdown`.
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

If WSL itself is missing, the `wsl` step offers to run
`wsl --install --no-distribution` as administrator (one UAC prompt). With
`-Yes`, in a dry run, or when the UAC prompt is declined, it prints that
command for an administrator PowerShell instead. Restart Windows afterwards and
run `install.ps1` again. The Debian distro is installed without starting
it, and the `debian` step creates the Linux user: do not start it with
`wsl -d Debian` before that, or its own prompt creates a user first.

The `debian` step runs the scripts `scripts/windows/debian-root.sh` (as
root) and `debian-user.sh` (as the Linux user) inside Debian. Every part is
skipped when it is done; `install.sh` runs until it has once gone through
(`debian-user.sh` then leaves `~/.local/state/dotfiles/installed-by-install.ps1`
in Debian), so later runs leave an installed Debian alone (update it with
`install.sh` inside Debian). The distro is restarted, after confirmation,
while `/etc/wsl.conf` changed or systemd is not running; with `-Yes` it is
not, because that may cut the SSH session the run comes through. If the step
fails, it says why, and the `tasks` step still runs.

## 4. Scheduled tasks

Each `scheduled-tasks/NAME.xml` is a Task Scheduler task (the format that
Task Scheduler's own Export writes), registered as `\dotfiles-<user SID>\NAME`
for the user who runs `install.ps1` (one folder per user, since all users
share the Task Scheduler tree). The step is idempotent: it registers a task
that is missing, whose XML changed (a hash of the XML is kept in the task's
Source field) or that was disabled by hand, leaves the others alone, and
removes a task it registered whose XML file is gone; a task added to the
folder by hand is left alone, even under the same name. A task whose action
runs `wsl.exe` is registered only once the Debian distro exists, on the next
`install.ps1` run. Other changes made in Task Scheduler (a trigger, an
action) are not detected: change the XML instead. To add a task, create it
in Task Scheduler, export it, replace the user ID with `__USER_SID__`, and put
the file there.

- `start-wsl`: starts the Debian distro 30 seconds after you log on to
  Windows, without opening a window, so that SSH into WSL works without
  opening a terminal; `instanceIdleTimeout=-1` keeps it running after that.
  It does not run while nobody is logged on: after a restart, someone has to
  log on (at the PC or over Remote Desktop) first.

## 5. Once, by hand

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
