# Usage: pwsh count-lines.ps1 [commit-sha]
# Omit SHA to list all history files.
param([string]$CommitSha = "")

$HistoryDir = ".claude/git-conversation-history"

if (-not $CommitSha) {
  if (-not (Test-Path $HistoryDir)) { Write-Host "No history found at $HistoryDir"; exit 0 }
  Write-Host "History files:"
  Get-ChildItem "$HistoryDir\*.jsonl" | ForEach-Object {
    $Lines = (Get-Content $_.FullName).Count
    Write-Host ("  {0,-46} {1} lines" -f $_.Name, $Lines)
  }
  exit 0
}

$FullSha = git rev-parse $CommitSha 2>$null
if (-not $FullSha) { $FullSha = $CommitSha }
$File = "$HistoryDir\$FullSha.jsonl"
if (-not (Test-Path $File)) { Write-Error "❌ No history file for: $CommitSha"; exit 1 }

$Lines = (Get-Content $File).Count
Write-Host "📄 $File"
Write-Host "   Lines: $Lines"
