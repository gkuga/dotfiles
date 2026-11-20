# Checks WSL, the Hyper-V firewall rule for SSH into WSL, and the Debian
# distro, and adds what is missing. Installing WSL and adding the firewall
# rule are the only things in install.ps1 that need an administrator: each is
# done only when you agree at the prompt (one UAC prompt each, on a new PC),
# and with -Yes or in a dry run the command is printed instead, so that an
# unattended run never waits for a UAC prompt nobody sees.
. "$PSScriptRoot\lib.ps1"

if (-not (Test-Wsl)) {
  Write-Warn 'WSL is not installed'
  $installed = (Test-Path -LiteralPath $Wsl) -and
    (Invoke-Elevated 'install WSL now?' "& '$Wsl' --install --no-distribution; exit `$LASTEXITCODE")
  if ($installed) {
    Write-Log 'WSL is installed: restart Windows, then run install.ps1 again for Debian'
  } else {
    Write-Warn 'In an administrator PowerShell, run:'
    Write-Warn '  wsl --install --no-distribution'
    Write-Warn 'then restart Windows and run install.ps1 again.'
  }
  return
}

# With networkingMode=mirrored, the Hyper-V firewall drops incoming traffic to
# WSL by default; WSL itself only allows mDNS and ICMP. SSH into WSL needs an
# inbound rule for TCP 22.
$wslVmCreator = '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
$ruleCommand = "New-NetFirewallHyperVRule -Name 'WSL2-Mirrored-SSH' -DisplayName 'WSL2 Mirrored SSH' " +
  "-Direction Inbound -VMCreatorId '$wslVmCreator' -Protocol TCP -LocalPorts 22 -Action Allow"
function Test-SshRule {
  return [bool](Get-NetFirewallHyperVRule -PolicyStore PersistentStore -ErrorAction SilentlyContinue |
    Where-Object {
      "$($_.Enabled)" -eq 'True' -and "$($_.Direction)" -eq 'Inbound' -and "$($_.Action)" -eq 'Allow' -and
      "$($_.Protocol)" -in @('TCP', 'Any') -and (@($_.LocalPorts) | Where-Object { $_ -in @('22', 'Any') })
    })
}
if (-not (Test-Command Get-NetFirewallHyperVRule)) {
  Write-Warn 'this Windows has no Hyper-V firewall cmdlets; not checking the rule for SSH into WSL'
} elseif (Test-SshRule) {
  Write-Log 'the Hyper-V firewall allows SSH into WSL (TCP 22)'
} else {
  Write-Warn 'the Hyper-V firewall blocks SSH into WSL: no inbound rule for TCP 22'
  if ((Invoke-Elevated 'add the rule now?' $ruleCommand) -and (Test-SshRule)) {
    Write-Log 'added the Hyper-V firewall rule WSL2 Mirrored SSH (TCP 22)'
  } else {
    Write-Warn 'In an administrator PowerShell, run:'
    Write-Warn "  $ruleCommand"
  }
}

if ((Get-WslDistro) -contains 'Debian') {
  Write-Log 'the Debian distro is installed'
} elseif (Confirm-Action 'install the Debian distro (wsl --install -d Debian)?') {
  # wsl.exe prints UTF-16 unless told otherwise.
  $saved = $env:WSL_UTF8
  $env:WSL_UTF8 = '1'
  try {
    Invoke-Native $Wsl @('--install', '--distribution', 'Debian', '--no-launch')
  } finally {
    $env:WSL_UTF8 = $saved
  }
} else {
  Write-Warn 'skipped the Debian distro'
}
