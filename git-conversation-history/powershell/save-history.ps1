# Usage: pwsh save-history.ps1 <commit-sha>
param([Parameter(Mandatory)][string]$CommitSha)

$FullSha = git rev-parse $CommitSha 2>$null
if (-not $FullSha) { Write-Error "❌ Commit not found: $CommitSha"; exit 1 }

$SessionFile = Get-ChildItem "$env:USERPROFILE\.claude\projects" -Filter "*.jsonl" -Recurse -ErrorAction SilentlyContinue `
  | Sort-Object LastWriteTime -Descending `
  | Select-Object -First 1 -ExpandProperty FullName

if (-not $SessionFile) { Write-Error "❌ No Claude Code session file found."; exit 1 }

$HistoryDir = ".claude/git-conversation-history"
New-Item -ItemType Directory -Force -Path $HistoryDir | Out-Null
Copy-Item $SessionFile "$HistoryDir\$FullSha.jsonl"

$GitIgnore = ".gitignore"
if (-not (Test-Path $GitIgnore) -or -not (Select-String -Path $GitIgnore -SimpleMatch ".claude/git-conversation-history" -Quiet)) {
  Add-Content $GitIgnore ".claude/git-conversation-history/"
}

$Lines = (Get-Content "$HistoryDir\$FullSha.jsonl").Count
Write-Host "✅ Saved: $HistoryDir\$FullSha.jsonl ($Lines lines)"
