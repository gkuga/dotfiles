# Shared helpers for the Windows steps: . "$PSScriptRoot\lib.ps1"
# Runs in Windows PowerShell 5.1. Keep every .ps1 file ASCII: 5.1 reads a
# script without a BOM in the ANSI code page.

$ErrorActionPreference = 'Stop'

# winget, chezmoi and git print UTF-8, and the user profile path may hold
# non-ASCII characters. Without a console (output redirected) this can fail.
try {
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
} catch {
}

function Write-Log([string]$Message) { Write-Host "==> $Message" -ForegroundColor Blue }
function Write-Warn([string]$Message) { Write-Host "warn: $Message" -ForegroundColor Yellow }

function Test-DryRun { return ($env:DRY_RUN -eq '1') }
function Test-Command([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# Runs a native program, or only prints it in a dry run. Throws on a non-zero
# exit code.
function Invoke-Native {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$ArgumentList = @()
  )
  if (Test-DryRun) {
    Write-Host "[dry-run] $FilePath $($ArgumentList -join ' ')" -ForegroundColor DarkGray
    return
  }
  & $FilePath @ArgumentList
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath $($ArgumentList -join ' ') failed (exit code $LASTEXITCODE)"
  }
}

# Asks a yes/no question. Defaults to "no"; -Yes (ASSUME_YES=1) answers "yes",
# and a dry run says "yes" so that every action is printed.
function Confirm-Action([string]$Question) {
  if ($env:ASSUME_YES -eq '1' -or (Test-DryRun)) { return $true }
  $reply = Read-Host "$Question [y/N]"
  return ($reply -match '^(y|yes)$')
}

# Reads a package list file, dropping comments and blank lines.
function Read-List([string]$Path) {
  Get-Content -LiteralPath $Path |
    ForEach-Object { ($_ -replace '#.*', '').Trim() } |
    Where-Object { $_ }
}

# Picks up PATH entries that installers added to the user or machine PATH,
# keeping the entries this session already has.
function Update-Path {
  $have = @($env:Path -split ';' | Where-Object { $_ })
  foreach ($scope in 'Machine', 'User') {
    foreach ($dir in @([Environment]::GetEnvironmentVariable('Path', $scope) -split ';' | Where-Object { $_ })) {
      if ($have -notcontains $dir) { $have += $dir }
    }
  }
  $env:Path = $have -join ';'
}

$Wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'

# True when WSL itself is installed. Looks for the WSL package instead of
# running wsl.exe: without WSL, wsl.exe is missing (Windows 10) or a stub that
# waits for a key and then installs WSL (Windows 11). `wsl --status` would
# also fail while WSL has no distro yet, right after
# `wsl --install --no-distribution`.
# WSL comes as a Store package (`wsl --install`) or as an MSI from its GitHub
# releases, which installs into Program Files\WSL.
function Test-Wsl {
  if (-not (Test-Path -LiteralPath $Wsl)) { return $false }
  if (Test-Path -LiteralPath (Join-Path $env:ProgramFiles 'WSL\wsl.exe')) { return $true }
  return [bool](Get-AppxPackage -Name 'MicrosoftCorporationII.WindowsSubsystemForLinux' -ErrorAction SilentlyContinue)
}

# The names of the installed WSL distros (empty without WSL).
function Get-WslDistro {
  if (-not (Test-Wsl)) { return @() }
  # wsl.exe prints UTF-16 unless told otherwise.
  $saved = $env:WSL_UTF8
  $env:WSL_UTF8 = '1'
  try {
    return @(& $Wsl --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  } finally {
    $env:WSL_UTF8 = $saved
  }
}

# Runs a PowerShell command as administrator, after asking: one UAC prompt on
# this screen. Never with -Yes or in a dry run, where nobody may see the
# prompt; returns $false then, or when it was declined or failed, so that the
# caller can print the command to run by hand.
function Invoke-Elevated([string]$Question, [string]$Command) {
  if ((Test-DryRun) -or $env:ASSUME_YES -eq '1') { return $false }
  if (-not (Confirm-Action "$Question (asks for an administrator once, on this screen)")) { return $false }
  # The elevated window closes when the command ends, so its error is written
  # to a file and shown here.
  $log = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-elevated-' + [guid]::NewGuid() + '.log')
  $wrapped = "`$ErrorActionPreference = 'Stop'; try { $Command } catch { (`$_ | Out-String) | Set-Content -LiteralPath '$log'; exit 1 }"
  # -EncodedCommand: Start-Process joins -ArgumentList without quoting.
  $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wrapped))
  try {
    $p = Start-Process -FilePath powershell.exe -Verb RunAs -Wait -PassThru `
      -ArgumentList '-NoProfile', '-EncodedCommand', $encoded
  } catch {
    # Also when the UAC prompt is declined.
    Write-Warn "did not run as administrator: $($_.Exception.Message)"
    return $false
  }
  $failed = $p.ExitCode -ne 0
  if ($failed) { Write-Warn "the administrator command failed (exit code $($p.ExitCode))" }
  if (Test-Path -LiteralPath $log) {
    Get-Content -LiteralPath $log | ForEach-Object { Write-Warn "  $_" }
    Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
  }
  return -not $failed
}

$WingetCommon = @('--exact', '--accept-source-agreements', '--disable-interactivity')
# winget exit codes that mean the package is there already: "no applicable
# upgrade" and "already installed". They come up for apps that `winget list`
# cannot match to their winget ID.
$WingetAlreadyInstalled = @(-1978335189, -1978335135)
# "Installed, but a restart is needed to finish."
$WingetRebootRequired = -1978334967

# Installs one winget package by ID for the current user, which needs no
# administrator (printed only in a dry run).
function Install-WingetPackage([string]$Id) {
  $arguments = @('install', '--id', $Id, '--source', 'winget', '--scope', 'user', '--accept-package-agreements') + $WingetCommon
  if (Test-DryRun) {
    Write-Host "[dry-run] winget $($arguments -join ' ')" -ForegroundColor DarkGray
    return
  }
  if (-not (Test-Command winget)) {
    throw 'winget not found: install or update "App Installer" from the Microsoft Store'
  }
  & winget @arguments
  if ($LASTEXITCODE -eq $WingetRebootRequired) {
    Write-Warn "$Id is installed; restart Windows to finish"
    return
  }
  if ($LASTEXITCODE -ne 0 -and $WingetAlreadyInstalled -notcontains $LASTEXITCODE) {
    throw "winget install $Id failed (exit code $LASTEXITCODE)"
  }
}
