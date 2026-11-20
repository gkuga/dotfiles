# Installs chezmoi and applies the Windows part of home/: .wslconfig and the
# coding-agent rules (home/.chezmoiignore lists what Windows does not get).
. "$PSScriptRoot\lib.ps1"

if (-not (Test-Command chezmoi)) {
  # The packages step installs it; this covers -Only dotfiles.
  Write-Log 'installing chezmoi with winget'
  Install-WingetPackage 'twpayne.chezmoi'
  Update-Path
}

# Runs chezmoi with the given arguments and throws when it fails.
function Invoke-Chezmoi([string[]]$ArgumentList) {
  & chezmoi @ArgumentList
  if ($LASTEXITCODE -ne 0) { throw "chezmoi $($ArgumentList -join ' ') failed (exit code $LASTEXITCODE)" }
}

if (Test-DryRun) {
  if (-not (Test-Command chezmoi)) {
    Write-Log "would run: chezmoi init --apply --source $env:REPO_DIR"
    return
  }
  Write-Log 'changes chezmoi would make (nothing is written to the user profile):'
  # Use a throwaway config and state so that a dry run leaves no trace.
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('chezmoi-dry-run-' + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  # Start from the saved answers, so that the dry run neither asks again nor
  # shows a diff that the real run would not make.
  $config = Join-Path $HOME '.config\chezmoi\chezmoi.toml'
  if (Test-Path -LiteralPath $config) { Copy-Item -LiteralPath $config -Destination (Join-Path $tmp 'chezmoi.toml') }
  try {
    $cz = @('--source', $env:REPO_DIR, '--config', (Join-Path $tmp 'chezmoi.toml'),
      '--persistent-state', (Join-Path $tmp 'state.boltdb'))
    Invoke-Chezmoi ($cz + 'init')
    Invoke-Chezmoi ($cz + @('diff', '--no-pager'))
  } finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force
  }
  return
}

# Show what is going to change before touching existing files. `chezmoi init`
# writes only chezmoi's own config (the answers to its questions) first.
$cz = @('--source', $env:REPO_DIR)
Invoke-Chezmoi ($cz + 'init')
$changes = (& chezmoi @cz diff --no-pager) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'chezmoi diff failed' }
if ($changes) {
  Write-Host $changes
  if (-not (Confirm-Action 'apply these dotfile changes?')) {
    Write-Warn 'skipped the dotfiles; nothing was applied'
    return
  }
}
Invoke-Chezmoi ($cz + 'apply')
if ($changes -match '\.wslconfig') {
  Write-Log ".wslconfig changed: it takes effect after 'wsl --shutdown'"
  Write-Log '(not while you depend on SSH into WSL: nothing starts WSL again by itself)'
}
