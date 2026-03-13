# Usage: pwsh get-history-lines.ps1 <commit-sha> <start_line> <end_line>
param(
  [Parameter(Mandatory)][string]$CommitSha,
  [Parameter(Mandatory)][int]$StartLine,
  [Parameter(Mandatory)][int]$EndLine
)

$HistoryDir = ".claude/git-conversation-history"

# Resolve partial SHA
$Match = Get-ChildItem "$HistoryDir\*.jsonl" -ErrorAction SilentlyContinue |
         Where-Object { $_.BaseName -like "$CommitSha*" }

if (-not $Match) {
  Write-Host "No history file found for commit '$CommitSha' in $HistoryDir"
  Write-Host "Available commits:"
  Get-ChildItem "$HistoryDir\*.jsonl" -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Host "  $($_.BaseName)" }
  exit 1
}
if ($Match.Count -gt 1) {
  Write-Host "Ambiguous SHA '$CommitSha' matches multiple files:"
  $Match | ForEach-Object { Write-Host "  $($_.BaseName)" }
  exit 1
}

$File = $Match[0]
Write-Host "📄 $($File.BaseName).jsonl  —  lines $StartLine–$EndLine"
Write-Host ""

$LineNum = 0
Get-Content $File.FullName | ForEach-Object {
  $LineNum++
  if ($LineNum -ge $StartLine -and $LineNum -le $EndLine) {
    "${LineNum}: $_"
  }
}
