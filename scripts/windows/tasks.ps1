# Makes the Task Scheduler folder \dotfiles\ match scheduled-tasks/*.xml:
# a task is registered when it is missing or its XML changed, and a task in
# \dotfiles\ without an XML file is removed. Only tasks of the current user
# that run without administrator rights, so this never shows a UAC prompt.
. "$PSScriptRoot\lib.ps1"

$taskPath = '\dotfiles\'
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$sha = [Security.Cryptography.SHA256]::Create()

# The wanted tasks: name -> XML with this user's SID. The hash of that XML is
# stored in the task's Source field, to tell later whether it changed.
$want = @{}
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $env:REPO_DIR 'scheduled-tasks') -Filter *.xml)) {
  $xml = (Get-Content -LiteralPath $file.FullName -Raw).Replace('__USER_SID__', $sid)
  $hash = -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($xml)) | ForEach-Object { $_.ToString('x2') })
  $source = "dotfiles:sha256:$hash"
  $want[$file.BaseName] = @{
    Source = $source
    Xml    = $xml.Replace('<RegistrationInfo>', "<RegistrationInfo>`n    <Source>$source</Source>")
  }
}
$have = @(Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue)

$changed = $false
foreach ($name in @($want.Keys | Sort-Object)) {
  $task = $have | Where-Object { $_.TaskName -eq $name }
  if ($task -and $task.Source -eq $want[$name].Source) { continue }
  $changed = $true
  $verb = if ($task) { 'update' } else { 'register' }
  if (Test-DryRun) {
    Write-Host "[dry-run] $verb scheduled task $taskPath$name" -ForegroundColor DarkGray
  } elseif (Confirm-Action "$verb scheduled task $taskPath$name?") {
    Register-ScheduledTask -TaskName $name -TaskPath $taskPath -Xml $want[$name].Xml -Force | Out-Null
    Write-Log "$verb`: $taskPath$name"
  } else {
    Write-Warn "skipped $taskPath$name"
  }
}

foreach ($task in $have) {
  if ($want.ContainsKey($task.TaskName)) { continue }
  $changed = $true
  if (Test-DryRun) {
    Write-Host "[dry-run] remove scheduled task $taskPath$($task.TaskName) (no XML for it)" -ForegroundColor DarkGray
  } elseif (Confirm-Action "remove scheduled task $taskPath$($task.TaskName) (no XML for it)?") {
    Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $taskPath -Confirm:$false
    Write-Log "removed: $taskPath$($task.TaskName)"
  } else {
    Write-Warn "kept $taskPath$($task.TaskName)"
  }
}

if (-not $changed) { Write-Log "scheduled tasks in $taskPath are up to date" }
