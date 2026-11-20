# Makes this user's Task Scheduler folder \dotfiles\<user SID>\ match
# scheduled-tasks/*.xml: a task is registered when it is missing, its XML
# changed, or it was disabled by hand, and a task that this script registered
# but whose XML file is gone is removed. Tasks run as the current user
# without administrator rights, so this never shows a UAC prompt.
. "$PSScriptRoot\lib.ps1"

$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
# One folder per user: every user of the PC shares the Task Scheduler tree.
$taskPath = "\dotfiles\$sid\"
$sourcePrefix = 'dotfiles:sha256:'
$sha = [Security.Cryptography.SHA256]::Create()
$ns = 'http://schemas.microsoft.com/windows/2004/02/mit/task'

# The wanted tasks: name -> XML for this user. A hash of that XML is stored in
# the task's RegistrationInfo/Source, to tell later whether it changed.
$want = @{}
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $env:REPO_DIR 'scheduled-tasks') -Filter *.xml)) {
  $text = (Get-Content -LiteralPath $file.FullName -Raw).Replace('__USER_SID__', $sid)
  $hash = -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)) | ForEach-Object { $_.ToString('x2') })
  $doc = New-Object System.Xml.XmlDocument
  $doc.LoadXml($text)
  $info = $doc.DocumentElement['RegistrationInfo']
  if (-not $info) {
    $info = $doc.CreateElement('RegistrationInfo', $ns)
    [void]$doc.DocumentElement.PrependChild($info)
  }
  # An exported task may carry a Source already: replace it.
  if ($info['Source']) { [void]$info.RemoveChild($info['Source']) }
  $node = $doc.CreateElement('Source', $ns)
  $node.InnerText = $sourcePrefix + $hash
  [void]$info.AppendChild($node)
  $settings = $doc.DocumentElement['Settings']
  $enabled = -not ($settings -and $settings['Enabled'] -and $settings['Enabled'].InnerText -eq 'false')
  $want[$file.BaseName] = @{ Source = $node.InnerText; Xml = $doc.OuterXml; Enabled = $enabled }
}
$have = @(Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue)

# Register-ScheduledTask creates the folder too. A standard user may not be
# allowed to create folders under the Task Scheduler root on some PCs.
function Register-DotfilesTask([string]$Name, [string]$Xml) {
  try {
    Register-ScheduledTask -TaskName $Name -TaskPath $taskPath -Xml $Xml -Force | Out-Null
    return $true
  } catch {
    Write-Warn "could not register $taskPath$Name`: $($_.Exception.Message)"
    return $false
  }
}

$changed = $false
foreach ($name in @($want.Keys | Sort-Object)) {
  $task = $have | Where-Object { $_.TaskName -eq $name }
  $current = $task -and $task.Source -eq $want[$name].Source -and
    (($task.State -ne 'Disabled') -eq $want[$name].Enabled)
  if ($current) { continue }
  $changed = $true
  $verb = if ($task) { 'update' } else { 'register' }
  if (Test-DryRun) {
    Write-Host "[dry-run] $verb scheduled task $taskPath$name" -ForegroundColor DarkGray
  } elseif (-not (Confirm-Action "$verb scheduled task $taskPath$name?")) {
    Write-Warn "skipped $taskPath$name"
  } elseif (Register-DotfilesTask $name $want[$name].Xml) {
    Write-Log "$verb`: $taskPath$name"
  }
}

# Remove only tasks that this script registered (by their Source), never
# one that was added to the folder by hand.
foreach ($task in $have) {
  if ($want.ContainsKey($task.TaskName)) { continue }
  if (-not ("$($task.Source)".StartsWith($sourcePrefix))) { continue }
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
