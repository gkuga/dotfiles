# Sets up the Debian distro far enough for SSH, then runs install.sh in it:
#   1. as root (debian-root.sh): packages for SSH and mDNS, the Linux user and
#      its password, /etc/wsl.conf, authorized_keys from GitHub;
#   2. a restart of the distro when /etc/wsl.conf changed;
#   3. as the user (debian-user.sh): clone the dotfiles and run install.sh,
#      until it has once gone through (debian-user.sh leaves a marker).
# Every part is skipped when it is done already. A failure here is reported
# and the remaining steps (tasks) still run.
. "$PSScriptRoot\lib.ps1"

$distro = 'Debian'
$defaultUser = 'gkuga'
# authorized_keys come from https://github.com/<this>.keys (public keys).
$githubUser = 'gkuga'

if ((Get-WslDistro) -notcontains $distro) {
  Write-Warn "the $distro distro is not installed yet; skipped (the wsl step installs it)"
  return
}

# Runs a command in the distro, with its output and input on the console
# (apt, passwd and install.sh are interactive), and leaves the exit code in
# $script:DistroExit. Never assign its result: that would capture the output.
# The early commands run as root, so that the first start never runs the
# distro's own user-creation prompt (OOBE); it skips that later anyway once
# the user exists.
$script:DistroExit = 0
function Invoke-Distro([string]$User, [string]$Command, [int[]]$Ok = @(0)) {
  # --exec: no second shell that would split $Command again.
  & $Wsl --distribution $distro --user $User --cd $env:REPO_DIR --exec sh -c $Command
  $script:DistroExit = $LASTEXITCODE
  if ($Ok -notcontains $script:DistroExit) {
    throw "in $distro as $User`: $Command failed (exit code $($script:DistroExit))"
  }
}

# Runs one of the scripts next to this file in the distro. A copy without
# carriage returns is run, so that a checkout with CRLF line endings works
# too. Arguments must not contain spaces or quotes.
function Invoke-DistroScript([string]$User, [string]$Script, [string[]]$Arguments, [int[]]$Ok = @(0)) {
  $command = 'f=$(mktemp) && tr -d \\015 <scripts/windows/' + $Script +
    ' >$f && sh $f ' + ($Arguments -join ' ') + '; r=$?; rm -f $f; exit $r'
  Invoke-Distro $User $command $Ok
}

if (Test-DryRun) {
  Write-Host "[dry-run] in $distro as root: packages for SSH and mDNS, the Linux user (default $defaultUser), /etc/wsl.conf, keys from github.com/$githubUser.keys" -ForegroundColor DarkGray
  Write-Host "[dry-run] in $distro as the user: clone the dotfiles and run install.sh, until it has once gone through" -ForegroundColor DarkGray
  return
}

try {
  # The Linux user: the one with uid 1000 (the first one created), or a new one.
  $user = "$(& $Wsl --distribution $distro --user root --exec sh -c 'id -nu 1000 2>/dev/null || true')".Trim()
  if (-not $user) {
    $user = $defaultUser
    if ($env:ASSUME_YES -ne '1') {
      $answer = "$(Read-Host "Linux user name for $distro [$defaultUser]")".Trim()
      if ($answer) { $user = $answer }
    }
  }
  # -cnotmatch: case-sensitive; Debian refuses upper-case user names.
  if ($user -cnotmatch '^[a-z_][a-z0-9_-]{0,31}$') { throw "not a valid Linux user name: $user" }

  Write-Log "preparing $distro for SSH (user $user)"
  Invoke-DistroScript 'root' 'debian-root.sh' @($user, $githubUser) @(0, 120)
  if ($script:DistroExit -eq 120) {
    # /etc/wsl.conf (systemd, default user) takes effect after a restart. It
    # also stops sshd for a moment, so not with -Yes (that may run over SSH).
    if ($env:ASSUME_YES -ne '1' -and (Confirm-Action "restart $distro now to apply /etc/wsl.conf? (stops SSH sessions into WSL)")) {
      & $Wsl --terminate $distro | Out-Null
      Invoke-Distro 'root' 'true'
      Write-Log "$distro restarted"
    } else {
      Write-Warn "restart $distro later to apply /etc/wsl.conf: wsl --terminate $distro"
    }
  }

  # The marker that debian-user.sh leaves after a successful install.sh. (dash
  # has no ~user, and a double quote would not survive Windows PowerShell 5.1's
  # native argument passing.)
  Invoke-Distro 'root' "test -f `$(getent passwd $user | cut -d: -f6)/.local/state/dotfiles/installed-by-install.ps1" @(0, 1)
  if ($script:DistroExit -eq 0) {
    Write-Log "$distro is set up already; to update it, run install.sh inside $distro"
  } elseif (Confirm-Action "run install.sh in $distro as ${user}? (asks for the sudo password and the chezmoi settings)") {
    $options = @()
    if ($env:ASSUME_YES -eq '1') { $options += '--yes' }
    Invoke-DistroScript $user 'debian-user.sh' $options
  } else {
    Write-Warn "skipped install.sh in $distro"
  }
  Write-Log "next: copy keys and machine settings from another machine (docs/setup-wsl.md, step 4)"
} catch {
  Write-Warn "the $distro setup stopped: $($_.Exception.Message)"
  Write-Warn 'fix the cause and run install.ps1 again; the parts that are done are skipped'
}
