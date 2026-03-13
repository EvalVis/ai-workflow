#!/usr/bin/env bash
# Usage: bash count-lines.sh [commit-sha]
# Omit SHA to list all history files.
HISTORY_DIR=".claude/git-conversation-history"

if [ -z "$1" ]; then
  [ -d "$HISTORY_DIR" ] || { echo "No history found at $HISTORY_DIR"; exit 0; }
  echo "History files:"
  for f in "$HISTORY_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    printf "  %-44s  %s lines\n" "$(basename "$f")" "$(wc -l < "$f" | tr -d ' ')"
  done
  exit 0
fi

FULL_SHA=$(git rev-parse "$1" 2>/dev/null || echo "$1")
FILE="$HISTORY_DIR/${FULL_SHA}.jsonl"
[ -f "$FILE" ] || { echo "❌ No history file for: $1"; exit 1; }
echo "📄 $FILE"
echo "   Lines: $(wc -l < "$FILE" | tr -d ' ')"
