# Usage: pwsh grep-history.ps1 "keyword" [max_lines=50]
param(
  [Parameter(Mandatory)][string]$Keyword,
  [int]$MaxLines = 50
)

$HistoryDir = ".claude/git-conversation-history"
if (-not (Test-Path $HistoryDir)) { Write-Host "No history found at $HistoryDir"; exit 0 }

Write-Host "🔍 Searching `"$Keyword`" (limit: $MaxLines lines)..."
Write-Host ""

$Results = Get-ChildItem "$HistoryDir\*.jsonl" | ForEach-Object {
  $File = $_.Name
  $LineNum = 0
  Get-Content $_.FullName | ForEach-Object {
    $LineNum++
    if ($_ -match [regex]::Escape($Keyword)) {
      "${File}:${LineNum}: $_"
    }
  }
}

$Total = $Results.Count
$Results | Select-Object -First $MaxLines | Write-Host

Write-Host ""
Write-Host "--- $Total total match(es), showing up to $MaxLines ---"
if ($Total -gt $MaxLines) {
  $Higher = $MaxLines * 4
  Write-Host "⚠️  Truncated. Re-run with higher limit: pwsh grep-history.ps1 `"$Keyword`" $Higher"
}
