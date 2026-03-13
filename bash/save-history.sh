#!/usr/bin/env bash
# Usage: bash save-history.sh <commit-sha>
set -e

COMMIT_SHA="${1}"
if [ -z "$COMMIT_SHA" ]; then echo "Usage: $0 <commit-sha>"; exit 1; fi

git rev-parse --quiet --verify "$COMMIT_SHA" > /dev/null 2>&1 \
  || { echo "❌ Commit not found: $COMMIT_SHA"; exit 1; }

FULL_SHA=$(git rev-parse "$COMMIT_SHA")

SESSION_FILE=$(find "${HOME}/.claude/projects" -name "*.jsonl" 2>/dev/null \
  | xargs ls -t 2>/dev/null | head -1)

[ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ] \
  || { echo "❌ No Claude Code session file found."; exit 1; }

HISTORY_DIR=".claude/git-conversation-history"
mkdir -p "$HISTORY_DIR"
cp "$SESSION_FILE" "$HISTORY_DIR/${FULL_SHA}.jsonl"

grep -qF ".claude/git-conversation-history" .gitignore 2>/dev/null \
  || echo ".claude/git-conversation-history/" >> .gitignore

echo "✅ Saved: $HISTORY_DIR/${FULL_SHA}.jsonl ($(wc -l < "$HISTORY_DIR/${FULL_SHA}.jsonl" | tr -d ' ') lines)"
