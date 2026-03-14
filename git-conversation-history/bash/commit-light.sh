#!/usr/bin/env bash
# Usage: bash commit-light.sh "feat: title" ["optional description"]
# Saves only new conversation lines since the last commit's history.
# Falls back to full save if no prior history exists.

TITLE="$1"
DESCRIPTION="$2"

if [ -z "$TITLE" ]; then
  echo "Usage: bash commit-light.sh \"feat: title\" [\"optional description\"]"
  exit 1
fi

if [ -n "$DESCRIPTION" ]; then
  git commit -m "$TITLE" -m "$DESCRIPTION"
else
  git commit -m "$TITLE"
fi

COMMIT_SHA=$(git rev-parse HEAD)
PREV_SHA=$(git rev-parse HEAD~1 2>/dev/null)
HISTORY_DIR=".claude/git-conversation-history"

mkdir -p "$HISTORY_DIR"

SESSION_FILE=$(find "$HOME/.claude/projects" -name "*.jsonl" -type f 2>/dev/null \
  | xargs ls -t 2>/dev/null \
  | head -1)

HISTORY_FILE="$HISTORY_DIR/$COMMIT_SHA.jsonl"

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
  echo "WARNING: No Claude Code session found -- commit saved without history."
else
  PREV_HISTORY_FILE=""
  if [ -n "$PREV_SHA" ]; then
    PREV_HISTORY_FILE="$HISTORY_DIR/$PREV_SHA.jsonl"
  fi

  if [ -n "$PREV_HISTORY_FILE" ] && [ -f "$PREV_HISTORY_FILE" ]; then
    LAST_LINE=$(tail -1 "$PREV_HISTORY_FILE")
    FOUND_IDX=$(grep -nF "$LAST_LINE" "$SESSION_FILE" | tail -1 | cut -d: -f1)
    TOTAL_LINES=$(wc -l < "$SESSION_FILE")

    if [ -n "$FOUND_IDX" ] && [ "$FOUND_IDX" -lt "$TOTAL_LINES" ]; then
      tail -n +"$(( FOUND_IDX + 1 ))" "$SESSION_FILE" > "$HISTORY_FILE"
      NEW_COUNT=$(wc -l < "$HISTORY_FILE")
      echo "Light history saved: $NEW_COUNT new lines -> $HISTORY_FILE"
    elif [ -n "$FOUND_IDX" ] && [ "$FOUND_IDX" -eq "$TOTAL_LINES" ]; then
      echo "No new conversation since last commit. Empty history saved."
      > "$HISTORY_FILE"
    else
      echo "Could not locate prior history in session -- saving full session as fallback."
      cp "$SESSION_FILE" "$HISTORY_FILE"
    fi
  else
    echo "No prior history found -- saving full session."
    cp "$SESSION_FILE" "$HISTORY_FILE"
  fi

  git add "$HISTORY_FILE"
  git commit --amend --no-edit > /dev/null
  COMMIT_SHA=$(git rev-parse HEAD)
  echo "History file amended into commit."
fi

echo "Committed: $TITLE ($COMMIT_SHA)"
