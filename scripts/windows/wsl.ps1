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
$ruleName = 'WSL2-Mirrored-SSH'
# Removes a rule of that name first (it may be disabled or edited), so that
# the command can always be run again.
$ruleCommand = "Remove-NetFirewallHyperVRule -Name '$ruleName' -ErrorAction SilentlyContinue; " +
  "New-NetFirewallHyperVRule -Name '$ruleName' -DisplayName 'WSL2 Mirrored SSH' " +
  "-Direction Inbound -VMCreatorId '$wslVmCreator' -Protocol TCP -LocalPorts 22 -Action Allow | Out-Null"
# $true when inbound TCP 22 reaches WSL: the WSL VM allows inbound by default,
# or an enabled allow rule for WSL (or any VM) covers TCP 22. Throws when the
# firewall cannot be read, so that this is never mistaken for a missing rule.
function Test-SshAllowed {
  $vm = Get-NetFirewallHyperVVMSetting -PolicyStore ActiveStore -Name $wslVmCreator -ErrorAction Stop
  if ("$($vm.DefaultInboundAction)" -eq 'Allow') { return $true }
  return [bool](Get-NetFirewallHyperVRule -PolicyStore PersistentStore -ErrorAction Stop |
    Where-Object {
      "$($_.Enabled)" -eq 'True' -and "$($_.Direction)" -eq 'Inbound' -and "$($_.Action)" -eq 'Allow' -and
      "$($_.VMCreatorId)" -in @($wslVmCreator, 'Any') -and
      "$($_.Protocol)" -in @('TCP', '6', 'Any') -and (@($_.LocalPorts) | Where-Object { "$_" -in @('22', 'Any') })
    })
}
# The same, with $null when the firewall cannot be read.
function Get-SshAllowed {
  try {
    return Test-SshAllowed
  } catch {
    Write-Warn "could not read the Hyper-V firewall settings: $($_.Exception.Message)"
    return $null
  }
}
if (-not (Test-Command Get-NetFirewallHyperVRule)) {
  Write-Warn 'this Windows has no Hyper-V firewall cmdlets; not checking the rule for SSH into WSL'
} else {
  $allowed = Get-SshAllowed
  if ($allowed) {
    Write-Log 'the Hyper-V firewall allows SSH into WSL (TCP 22)'
  } elseif ($null -ne $allowed) {
    Write-Warn 'the Hyper-V firewall blocks SSH into WSL: no inbound rule for TCP 22'
    if ((Invoke-Elevated 'add the rule now?' $ruleCommand) -and (Get-SshAllowed)) {
      Write-Log 'added the Hyper-V firewall rule WSL2 Mirrored SSH (TCP 22)'
    } else {
      Write-Warn 'In an administrator PowerShell, run:'
      Write-Warn "  $ruleCommand"
    }
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
