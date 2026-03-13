---
name: smart-commit
description: Commit code and manage conversation history per commit. Use when committing features or fixes. Use proactively to look up past conversation context before editing a feature — prevents regressions.
---

# Smart Commit & Conversation History

## Purpose

Every commit can have its full Claude Code conversation saved alongside it in:
```
.claude/git-conversation-history/<commit-sha>.jsonl
```

Before modifying an existing feature, grep the history to understand the original intent, constraints, and decisions — so you don't introduce bugs.

**Always check conversation history before modifying an existing feature.**

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

```bash
# Windows
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

### 3. Grep history — always use a line limit

Conversation files can be very large. **Always start small and expand only if needed.**

```bash
# Linux/macOS
bash .claude/skills/git-conversation-history/bash/grep-history.sh "keyword" [max_lines=50]

# Windows
pwsh .claude/skills/git-conversation-history/powershell/grep-history.ps1 "keyword" [max_lines=50]
# or
powershell .claude/skills/git-conversation-history/powershell/grep-history.ps1 "keyword" [max_lines=50]
```

**Workflow:**
1. `grep-history.ps1 "payment"` — first 50 hits
2. If truncated: `grep-history.ps1 "payment validation" 200`
3. Use `count-lines` to gauge file size before going deep

Each result is prefixed with `filename:linenum:` so you can trace it back to a commit SHA.

---

### 4. Count lines in history file(s)

Check file size before grepping deeply.

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

## Storage

```
.claude/
  git-conversation-history/
    a3f9c12.jsonl
    d82bb41.jsonl
```

- `.jsonl` — one JSON object per line, Claude Code's native session format
- Gitignored — local only, never pushed
