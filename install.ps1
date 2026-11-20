# Bootstraps the Windows side of the development environment: winget
# packages, dotfiles (chezmoi: .wslconfig and the coding-agent rules) and WSL.
#
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/gkuga/dotfiles/main/install.ps1)))
#   powershell -ExecutionPolicy Bypass -File install.ps1 [-DryRun] [-Yes] [-Only STEP[,STEP...]]
#
# Steps (in order): packages, dotfiles, wsl. Every step can be re-run safely.
# Runs in Windows PowerShell 5.1. Keep it ASCII: 5.1 reads a script without a
# BOM in the ANSI code page.
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Yes,
  [string[]]$Only = @(),
  [switch]$Help
)
$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/gkuga/dotfiles.git'
$AllSteps = @('packages', 'dotfiles', 'wsl')

if ($Help) {
  Write-Host @'
Usage: install.ps1 [-DryRun] [-Yes] [-Only STEP[,STEP...]]

  -DryRun  print what would change, change nothing
  -Yes     answer yes to every confirmation
  -Only    run only the given steps
  -Help    show this help

Steps (in order): packages, dotfiles, wsl
'@
  return
}

# Started from irm there is no checkout yet: clone it, then run its copy.
$here = $PSScriptRoot
if (-not $here -or -not (Test-Path -LiteralPath (Join-Path $here 'scripts\windows\lib.ps1'))) {
  $repoDir = $env:DOTFILES_DIR
  if (-not $repoDir) { $repoDir = Join-Path $HOME 'dev\src\github.com\gkuga\dotfiles' }
  if ($DryRun) {
    # A dry run must not leave a checkout behind in the user profile.
    $repoDir = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-' + [guid]::NewGuid())
    Write-Host "dry-run: using a temporary checkout in $repoDir"
  } elseif (Test-Path -LiteralPath (Join-Path $repoDir '.git')) {
    Write-Host "using the existing checkout in $repoDir (run git pull there to update it)"
  }
  if (-not (Test-Path -LiteralPath (Join-Path $repoDir '.git'))) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
      if ($DryRun) { throw 'git is required: winget install --id Git.Git --exact' }
      Write-Host 'installing Git with winget, to clone the repository'
      winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
      if ($LASTEXITCODE -ne 0) { throw "failed to install Git (exit code $LASTEXITCODE)" }
      $env:Path = @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [Environment]::GetEnvironmentVariable('Path', 'User')
      ) -join ';'
    }
    git clone $RepoUrl $repoDir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit code $LASTEXITCODE)" }
  }
  # Text run through irm skips the execution policy, but the checkout's
  # script files do not: allow them for this process only. A policy set by
  # an administrator (Group Policy) still wins.
  try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  } catch {
    Write-Host "warning: could not relax the execution policy: $($_.Exception.Message)"
  }
  & (Join-Path $repoDir 'install.ps1') @PSBoundParameters
  return
}

$steps = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($steps.Count -eq 0) { $steps = $AllSteps }
foreach ($step in $steps) {
  if ($AllSteps -notcontains $step) { throw "unknown step: $step (steps: $($AllSteps -join ', '))" }
}

# The steps read these, like the bash scripts do. They are restored at the
# end, so that the PowerShell session is left as it was.
$saved = @{}
foreach ($name in 'REPO_DIR', 'DRY_RUN', 'ASSUME_YES') {
  $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
try {
  $env:REPO_DIR = $here
  $env:DRY_RUN = $(if ($DryRun) { '1' } else { $null })
  $env:ASSUME_YES = $(if ($Yes) { '1' } else { $null })
  . (Join-Path $here 'scripts\windows\lib.ps1')

  Write-Log "platform: windows, repo: $here"
  if ($DryRun) { Write-Log 'dry-run mode: nothing will be changed' }
  foreach ($step in $AllSteps) {
    if ($steps -contains $step) {
      Write-Log "step: $step"
      & (Join-Path $here "scripts\windows\$step.ps1")
    }
  }
  Write-Log 'done'
} finally {
  foreach ($name in $saved.Keys) {
    [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process')
  }
}
