#!/usr/bin/env bash
# Usage: bash get-history-lines.sh <commit-sha> <start_line> <end_line>

HISTORY_DIR=".claude/git-conversation-history"
COMMIT_SHA="$1"
START_LINE="$2"
END_LINE="$3"

if [ -z "$COMMIT_SHA" ] || [ -z "$START_LINE" ] || [ -z "$END_LINE" ]; then
  echo "Usage: bash get-history-lines.sh <commit-sha> <start_line> <end_line>"
  exit 1
fi

# Resolve partial SHA
MATCHES=$(find "$HISTORY_DIR" -name "${COMMIT_SHA}*.jsonl" 2>/dev/null)
MATCH_COUNT=$(echo "$MATCHES" | grep -c '.jsonl' 2>/dev/null || echo 0)

if [ -z "$MATCHES" ] || [ "$MATCH_COUNT" -eq 0 ]; then
  echo "No history file found for commit '$COMMIT_SHA' in $HISTORY_DIR"
  echo "Available commits:"
  find "$HISTORY_DIR" -name "*.jsonl" 2>/dev/null | xargs -I{} basename {} .jsonl | sed 's/^/  /'
  exit 1
fi

if [ "$MATCH_COUNT" -gt 1 ]; then
  echo "Ambiguous SHA '$COMMIT_SHA' matches multiple files:"
  echo "$MATCHES" | xargs -I{} basename {} | sed 's/^/  /'
  exit 1
fi

FILE="$MATCHES"
BASENAME=$(basename "$FILE" .jsonl)
TOTAL_LINES=$(wc -l < "$FILE")

echo "📄 ${BASENAME}.jsonl  —  lines ${START_LINE}–${END_LINE}"
echo ""

awk "NR>=$START_LINE && NR<=$END_LINE { print NR\": \"\$0 }" "$FILE"
