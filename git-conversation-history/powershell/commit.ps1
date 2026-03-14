# Usage: pwsh commit.ps1 "feat: title" ["optional description"]
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
$HistoryDir = ".claude/git-conversation-history"
New-Item -ItemType Directory -Force -Path $HistoryDir | Out-Null
$SessionFile = Get-ChildItem "$env:USERPROFILE\.claude\projects" -Filter "*.jsonl" -Recurse -ErrorAction SilentlyContinue `
  | Sort-Object LastWriteTime -Descending `
  | Select-Object -First 1 -ExpandProperty FullName
if ($SessionFile -and (Test-Path $SessionFile)) {
  $HistoryFile = "$HistoryDir\$CommitSha.jsonl"
  Copy-Item $SessionFile $HistoryFile
  git add $HistoryFile
  git commit --amend --no-edit | Out-Null
  $CommitSha = git rev-parse HEAD
  Write-Host "Session saved and amended into commit: $HistoryFile"
} else {
  Write-Host "WARNING: No Claude Code session found -- commit saved without history."
}
Write-Host "Committed: $Title ($CommitSha)"
