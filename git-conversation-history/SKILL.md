---
name: git-conversation-history
description: Commit code and manage conversation history per commit. Use when committing features or fixes. Use proactively to look up past conversation context before editing a feature — prevents regressions.
---

# Git Conversation History

## Purpose

Every commit can have its full Claude Code conversation saved alongside it in:
```
.claude/git-conversation-history/<commit-sha>.jsonl
```

Before modifying an existing feature, find relevant commit(s), read conversation history (scripts provided below) to understand the original intent, constraints, and decisions — so you don't introduce bugs.
Recommended approach:
1. After understanding user prompt, find relevant commit(s) by the title.
2. Read commit conversation history (use scripts below).
3. You now have better context.
4. When you do a feature either use commit or light commit (scripts below) so you save the conversation context for the future.

---

## OS Detection

Detect the OS at the start of any session and use the correct script folder:

| OS | Folder | Run with |
|----|--------|----------|
| Linux / macOS | `bash/` | `bash .claude/skills/git-conversation-history/bash/<script>.sh` |
| Windows | `powershell/` | Use `pwsh` if available, otherwise `powershell`. Run: `pwsh .claude/skills/git-conversation-history/powershell/<script>.ps1` or `powershell .claude/skills/git-conversation-history/powershell/<script>.ps1` |

To detect which is available on Windows, run: `pwsh -Version 2>/dev/null || powershell -Command '$PSVersionTable.PSVersion'`

---

## Scripts

---

### 1a. Commit with full conversation saved

Stage files you want to commit before executing this script.

```bash
# Linux/macOS
bash .claude/skills/git-conversation-history/bash/commit.sh "feat: title" ["optional description"]

# Windows (pwsh / PowerShell 7+)
pwsh .claude/skills/git-conversation-history/powershell/commit.ps1 "feat: title" ["optional description"]

# Windows (powershell / Windows PowerShell 5.x fallback)
powershell .claude/skills/git-conversation-history/powershell/commit.ps1 "feat: title" ["optional description"]
```

Runs `git commit`, then copies the **entire** latest Claude Code session to `.claude/git-conversation-history/<sha>.jsonl`. Use for the first commit on a feature, or when you want a full snapshot.

---

### 1b. Commit with light (incremental) conversation saved

Stage files you want to commit before executing this script.

```bash
# Linux/macOS
bash .claude/skills/git-conversation-history/bash/commit-light.sh "feat: title" ["optional description"]

# Windows (pwsh / PowerShell 7+)
pwsh .claude/skills/git-conversation-history/powershell/commit-light.ps1 "feat: title" ["optional description"]

# Windows (powershell / Windows PowerShell 5.x fallback)
powershell .claude/skills/git-conversation-history/powershell/commit-light.ps1 "feat: title" ["optional description"]
```

Same as above, but **only saves new conversation lines since the previous commit's history**. Avoids duplicating earlier history across every commit.

**How it works:** finds the last line of the previous commit's `.jsonl`, locates it verbatim in the current session file, and saves only everything after it.

**Fallback behaviour:**
- No previous history file → saves full session (same as `commit.sh`)
- Previous history anchor not found in session (e.g. session was rotated) → saves full session
- No new lines since last commit → saves an empty file

**Recommended default** for all commits after the first on a branch.

---

### 2. Save conversation for an existing commit (retroactive)

```bash
# Linux/macOS
bash .claude/skills/git-conversation-history/bash/save-history.sh <commit-sha>

# Windows
pwsh .claude/skills/git-conversation-history/powershell/save-history.ps1 <commit-sha>
# or
powershell .claude/skills/git-conversation-history/powershell/save-history.ps1 <commit-sha>
```

---

### 3. Count lines in history file(s)

Check file size before reading deeply.

```bash
# Linux/macOS
bash .claude/skills/git-conversation-history/bash/count-lines.sh [commit-sha]

# Windows
pwsh .claude/skills/git-conversation-history/powershell/count-lines.ps1 [commit-sha]
# or
powershell .claude/skills/git-conversation-history/powershell/count-lines.ps1 [commit-sha]
```

Omit commit SHA to list all history files with sizes.

---

### 4. Read a line range from a history file

Conversation files can be very large. Use `count-lines` first to know the total, then read the range you need.

```bash
# Linux/macOS
bash .claude/skills/git-conversation-history/bash/get-history-lines.sh <commit-sha> <start_line> <end_line>

# Windows
pwsh .claude/skills/git-conversation-history/powershell/get-history-lines.ps1 <commit-sha> <start_line> <end_line>
# or
powershell .claude/skills/git-conversation-history/powershell/get-history-lines.ps1 <commit-sha> <start_line> <end_line>
```

All three arguments are required. Partial SHAs are accepted — e.g. `a3f9c12` will match `a3f9c12abc.jsonl`.

Each output line is prefixed with its line number: `42: {"role": ...}`

**Workflow:**
1. `count-lines` to see file sizes
2. `get-history-lines a3f9c12 1 100` to read the first 100 lines
3. Continue with the next range as needed

---

## Storage

```
.claude/
  git-conversation-history/
    a3f9c12.jsonl
    d82bb41.jsonl
```

`.jsonl` — one JSON object per line, Claude Code's native session format
