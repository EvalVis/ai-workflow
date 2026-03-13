#!/usr/bin/env bash
# Usage: bash grep-history.sh "keyword" [max_lines=50]
KEYWORD="${1}"
MAX_LINES="${2:-50}"

if [ -z "$KEYWORD" ]; then
  echo "Usage: $0 \"keyword\" [max_lines]  (default max_lines: 50)"
  exit 1
fi

HISTORY_DIR=".claude/git-conversation-history"
[ -d "$HISTORY_DIR" ] || { echo "No history found at $HISTORY_DIR"; exit 0; }

echo "🔍 Searching \"$KEYWORD\" (limit: $MAX_LINES lines)..."
echo ""

grep -rn --include="*.jsonl" "$KEYWORD" "$HISTORY_DIR" | head -n "$MAX_LINES"

TOTAL=$(grep -rn --include="*.jsonl" "$KEYWORD" "$HISTORY_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "--- $TOTAL total match(es), showing up to $MAX_LINES ---"
if [ "$TOTAL" -gt "$MAX_LINES" ]; then
  echo "⚠️  Truncated. Re-run with higher limit: $0 \"$KEYWORD\" $((MAX_LINES * 4))"
fi
