# Checks WSL and the Debian distro, and installs the distro when it is
# missing. WSL itself needs an administrator, which this script never asks
# for: it prints the command to run instead.
. "$PSScriptRoot\lib.ps1"

$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
# wsl.exe prints UTF-16 unless told otherwise.
$savedUtf8 = $env:WSL_UTF8
$env:WSL_UTF8 = '1'
try {
  # Look for the WSL package instead of running wsl.exe: without WSL,
  # wsl.exe is missing (Windows 10) or a stub that waits for a key and then
  # installs WSL (Windows 11). `wsl --status` would also fail while WSL has no
  # distro yet, right after `wsl --install --no-distribution`.
  $installed = (Test-Path -LiteralPath $wsl) -and
    [bool](Get-AppxPackage -Name 'MicrosoftCorporationII.WindowsSubsystemForLinux' -ErrorAction SilentlyContinue)
  if (-not $installed) {
    Write-Warn 'WSL is not installed. In an administrator PowerShell, run:'
    Write-Warn '  wsl --install --no-distribution'
    Write-Warn 'then restart Windows and run install.ps1 again.'
    return
  }

  $distros = @(& $wsl --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  if ($distros -contains 'Debian') {
    Write-Log 'the Debian distro is installed'
  } elseif (Confirm-Action 'install the Debian distro (wsl --install -d Debian)?') {
    Invoke-Native $wsl @('--install', '--distribution', 'Debian', '--no-launch')
    if (-not (Test-DryRun)) { Write-Log "start it with 'wsl -d Debian' and create the Linux user" }
  } else {
    Write-Warn 'skipped the Debian distro'
  }
  Write-Log 'next: set up Debian itself with install.sh (docs/setup-wsl.md)'
} finally {
  $env:WSL_UTF8 = $savedUtf8
}
