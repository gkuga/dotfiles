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
  -Yes     answer yes to every confirmation (chezmoi still asks its own
           questions on the first init)
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
  $tempCheckout = $null
  if ($DryRun) {
    # A dry run must not leave a checkout behind: it is removed at the end.
    $repoDir = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-' + [guid]::NewGuid())
    $tempCheckout = $repoDir
    Write-Host "dry-run: using a temporary checkout in $repoDir"
  } elseif (Test-Path -LiteralPath (Join-Path $repoDir '.git')) {
    Write-Host "using the existing checkout in $repoDir (run git pull there to update it)"
  }
  if (-not (Test-Path -LiteralPath (Join-Path $repoDir '.git'))) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
      if ($DryRun) { throw 'git is required: winget install --id Git.Git --exact' }
      if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget not found: install or update "App Installer" from the Microsoft Store'
      }
      Write-Host 'installing Git with winget, to clone the repository'
      winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
      # -1978335189 / -1978335135: no applicable upgrade / already installed
      # (Git is there, but not on this session's PATH yet).
      if (@(0, -1978335189, -1978335135) -notcontains $LASTEXITCODE) {
        throw "failed to install Git (exit code $LASTEXITCODE)"
      }
      $env:Path += ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine') +
        ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
      if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is still not on PATH: open a new PowerShell and run this again'
      }
    }
    git clone $RepoUrl $repoDir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit code $LASTEXITCODE)" }
  }
  # Text run through irm skips the execution policy, but the checkout's
  # script files do not: allow them for this process while they run. A policy
  # set by an administrator (Group Policy) still wins.
  $policy = Get-ExecutionPolicy -Scope Process
  try {
    try {
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    } catch {
      Write-Host "warning: could not relax the execution policy: $($_.Exception.Message)"
    }
    & (Join-Path $repoDir 'install.ps1') @PSBoundParameters
  } finally {
    try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy $policy -Force } catch { }
    if ($tempCheckout) { Remove-Item -LiteralPath $tempCheckout -Recurse -Force -ErrorAction SilentlyContinue }
  }
  return
}

$steps = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($steps.Count -eq 0) { $steps = $AllSteps }
foreach ($step in $steps) {
  if ($AllSteps -notcontains $step) { throw "unknown step: $step (steps: $($AllSteps -join ', '))" }
}

# The steps read these environment variables, like the bash scripts do. They
# and the console encoding (set by lib.ps1) are restored at the end. PATH is
# not: it keeps what the installers added, so that new tools work right away.
$saved = @{}
foreach ($name in 'REPO_DIR', 'DRY_RUN', 'ASSUME_YES') {
  $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$savedEncoding = [Console]::OutputEncoding
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
  try { [Console]::OutputEncoding = $savedEncoding } catch { }
}
