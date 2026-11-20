# Checks WSL and the Debian distro, and installs what is missing. Installing
# WSL itself is the only thing in install.ps1 that needs an administrator:
# it is done only when you agree at the prompt (one UAC prompt, on a new PC),
# and with -Yes or in a dry run the command is printed instead, so that an
# unattended run never waits for a UAC prompt nobody sees.
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
    Write-Warn 'WSL is not installed'
    $asked = (Test-Path -LiteralPath $wsl) -and -not (Test-DryRun) -and $env:ASSUME_YES -ne '1'
    if ($asked -and (Confirm-Action 'install WSL now? (asks for an administrator once, on this screen)')) {
      try {
        $p = Start-Process -FilePath $wsl -ArgumentList '--install', '--no-distribution' -Verb RunAs -Wait -PassThru
        if ($p.ExitCode -eq 0) {
          Write-Log 'WSL is installed: restart Windows, then run install.ps1 again for Debian'
          return
        }
        Write-Warn "wsl --install failed (exit code $($p.ExitCode))"
      } catch {
        # Also when the UAC prompt is declined.
        Write-Warn "wsl --install did not run: $($_.Exception.Message)"
      }
    }
    Write-Warn 'In an administrator PowerShell, run:'
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
