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
  Copy-Item $SessionFile "$HistoryDir\$CommitSha.jsonl"
  Write-Host "Session saved: $HistoryDir\$CommitSha.jsonl"
} else {
  Write-Host "WARNING: No Claude Code session found -- commit saved without history."
}

$GitIgnore = ".gitignore"
if (-not (Test-Path $GitIgnore) -or -not (Select-String -Path $GitIgnore -SimpleMatch ".claude/git-conversation-history" -Quiet)) {
  Add-Content $GitIgnore ".claude/git-conversation-history/"
}

Write-Host "Committed: $Title ($CommitSha)"
