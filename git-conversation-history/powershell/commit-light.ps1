# Usage: powershell commit-light.ps1 "feat: title" ["optional description"]
# Saves only new conversation lines since the last commit's history.
# Falls back to full save if no prior history exists.
param(
  [Parameter(Mandatory)][string]$Title,
  [string]$Description = ""
)
if ($Description) {
  git commit -m $Title -m $Description
} else {
  git commit -m $Title
}
$CommitSha = git rev-parse HEAD
$PrevSha = git rev-parse HEAD~1 2>$null
$HistoryDir = ".claude/git-conversation-history"
New-Item -ItemType Directory -Force -Path $HistoryDir | Out-Null

$SessionFile = Get-ChildItem "$env:USERPROFILE\.claude\projects" -Filter "*.jsonl" -Recurse -ErrorAction SilentlyContinue `
  | Sort-Object LastWriteTime -Descending `
  | Select-Object -First 1 -ExpandProperty FullName

$HistoryFile = "$HistoryDir\$CommitSha.jsonl"

if (-not $SessionFile -or -not (Test-Path $SessionFile)) {
  Write-Host "WARNING: No Claude Code session found -- commit saved without history."
} else {
  $PrevHistoryFile = if ($PrevSha) { "$HistoryDir\$PrevSha.jsonl" } else { $null }
  if ($PrevHistoryFile -and (Test-Path $PrevHistoryFile)) {
    $LastLine = Get-Content $PrevHistoryFile -Last 1
    $SessionLines = Get-Content $SessionFile
    $FoundIdx = [Array]::IndexOf($SessionLines, $LastLine)
    if ($FoundIdx -ge 0 -and $FoundIdx -lt $SessionLines.Count - 1) {
      $NewLines = $SessionLines[($FoundIdx + 1)..($SessionLines.Count - 1)]
      $NewLines | Set-Content $HistoryFile
      Write-Host "Light history saved: $($NewLines.Count) new lines -> $HistoryFile"
    } elseif ($FoundIdx -eq $SessionLines.Count - 1) {
      Write-Host "No new conversation since last commit. Empty history saved."
      "" | Set-Content $HistoryFile
    } else {
      Write-Host "Could not locate prior history in session -- saving full session as fallback."
      Copy-Item $SessionFile $HistoryFile
    }
  } else {
    Write-Host "No prior history found -- saving full session."
    Copy-Item $SessionFile $HistoryFile
  }

  # Stage the history file and amend it into the commit
  git add $HistoryFile
  git commit --amend --no-edit | Out-Null
  $CommitSha = git rev-parse HEAD
  Write-Host "History file amended into commit."
}

Write-Host "Committed: $Title ($CommitSha)"
