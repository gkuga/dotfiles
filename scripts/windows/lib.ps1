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

$WingetCommon = @('--exact', '--accept-source-agreements', '--disable-interactivity')
# winget exit codes that mean the package is there already: "no applicable
# upgrade" and "already installed". They come up for apps that `winget list`
# cannot match to their winget ID.
$WingetAlreadyInstalled = @(-1978335189, -1978335135)

# Installs one winget package by ID (printed only in a dry run).
function Install-WingetPackage([string]$Id) {
  $arguments = @('install', '--id', $Id, '--source', 'winget', '--accept-package-agreements') + $WingetCommon
  if (Test-DryRun) {
    Write-Host "[dry-run] winget $($arguments -join ' ')" -ForegroundColor DarkGray
    return
  }
  if (-not (Test-Command winget)) {
    throw 'winget not found: install or update "App Installer" from the Microsoft Store'
  }
  & winget @arguments
  if ($LASTEXITCODE -ne 0 -and $WingetAlreadyInstalled -notcontains $LASTEXITCODE) {
    throw "winget install $Id failed (exit code $LASTEXITCODE)"
  }
}
