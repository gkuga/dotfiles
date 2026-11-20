# Checks WSL and the Debian distro, and installs what is missing. Installing
# WSL itself is the only thing in install.ps1 that needs an administrator:
# it is done only when you agree at the prompt (one UAC prompt, on a new PC),
# and with -Yes or in a dry run the command is printed instead, so that an
# unattended run never waits for a UAC prompt nobody sees.
. "$PSScriptRoot\lib.ps1"

if (-not (Test-Wsl)) {
  Write-Warn 'WSL is not installed'
  $asked = (Test-Path -LiteralPath $Wsl) -and -not (Test-DryRun) -and $env:ASSUME_YES -ne '1'
  if ($asked -and (Confirm-Action 'install WSL now? (asks for an administrator once, on this screen)')) {
    try {
      $p = Start-Process -FilePath $Wsl -ArgumentList '--install', '--no-distribution' -Verb RunAs -Wait -PassThru
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

if ((Get-WslDistro) -contains 'Debian') {
  Write-Log 'the Debian distro is installed'
} elseif (Confirm-Action 'install the Debian distro (wsl --install -d Debian)?') {
  Invoke-Native $Wsl @('--install', '--distribution', 'Debian', '--no-launch')
  if (-not (Test-DryRun)) { Write-Log "start it with 'wsl -d Debian' and create the Linux user" }
} else {
  Write-Warn 'skipped the Debian distro'
}
Write-Log 'next: set up Debian itself with install.sh (docs/setup-wsl.md)'
