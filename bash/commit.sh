#!/usr/bin/env bash
# Usage: bash commit.sh "feat: title" ["optional description"]
set -e

TITLE="${1}"
DESCRIPTION="${2}"

if [ -z "$TITLE" ]; then
  echo "Usage: $0 \"feat: title\" [\"optional description\"]"
  exit 1
fi

if [ -n "$DESCRIPTION" ]; then
  git commit -m "${TITLE}" -m "${DESCRIPTION}"
else
  git commit -m "${TITLE}"
fi

COMMIT_SHA=$(git rev-parse HEAD)
HISTORY_DIR=".claude/git-conversation-history"
mkdir -p "$HISTORY_DIR"

SESSION_FILE=$(find "${HOME}/.claude/projects" -name "*.jsonl" 2>/dev/null \
  | xargs ls -t 2>/dev/null | head -1)

if [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ]; then
  cp "$SESSION_FILE" "$HISTORY_DIR/${COMMIT_SHA}.jsonl"
  echo "📄 Session saved: $HISTORY_DIR/${COMMIT_SHA}.jsonl"
else
  echo "⚠️  No Claude Code session found — commit saved without history."
fi

grep -qF ".claude/git-conversation-history" .gitignore 2>/dev/null \
  || echo ".claude/git-conversation-history/" >> .gitignore

echo "✅ Committed: $TITLE ($COMMIT_SHA)"
