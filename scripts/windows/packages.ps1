# Installs the packages in packages/winget.txt that are not installed yet.
. "$PSScriptRoot\lib.ps1"

if (-not (Test-Command winget)) {
  throw 'winget not found: install or update "App Installer" from the Microsoft Store'
}

$missing = @()
foreach ($id in @(Read-List (Join-Path $env:REPO_DIR 'packages\winget.txt'))) {
  # Also finds apps installed without winget (by their own installer).
  winget list --id $id @WingetCommon | Out-Null
  if ($LASTEXITCODE -ne 0) { $missing += $id }
}

if ($missing.Count -eq 0) {
  Write-Log 'all winget packages are installed'
} elseif (-not (Confirm-Action "install with winget: $($missing -join ', ')?")) {
  Write-Warn 'skipped the winget packages'
} else {
  $failed = @()
  foreach ($id in $missing) {
    try {
      Install-WingetPackage $id
    } catch {
      Write-Warn $_.Exception.Message
      $failed += $id
    }
  }
  Update-Path
  if ($failed.Count -gt 0) {
    Write-Warn "not installed: $($failed -join ', ') (see the winget output above)"
    Write-Warn 'If winget found no applicable installer, the package has no per-user installer:'
    Write-Warn 'install it once at the PC, which asks for an administrator:'
    foreach ($id in $failed) { Write-Warn "  winget install --id $id --exact --source winget" }
  }
}

# Docker Desktop updates itself, so it is installed by hand (as on macOS).
if (-not (Test-Path -LiteralPath (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'))) {
  Write-Warn 'Docker Desktop not found: install it from https://www.docker.com/products/docker-desktop/'
  Write-Warn '(not in winget.txt: it updates itself)'
}
