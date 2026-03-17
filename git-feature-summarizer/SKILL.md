---
name: git-feature-summarizer
description: Guide AI to generate structured "what/why/how" feature summaries for users and commit messages after each feature implementation.
---

## Purpose

Problem: People often ask AI agents to implement features but forget to preserve enough context about **why** the feature was implemented and **how** it was structured. Later, when they return and ask for changes, the AI lacks this context and makes incorrect assumptions.

This skill standardizes how feature work is summarized so future AI sessions can quickly understand the intent and structure of past changes.

## When To Use This Skill

- Use this skill **after implementing any feature or substantial change** that would reasonably be grouped into a single commit.
- This includes new features, major refactors, and significant architectural changes.

## Core Behavior

When this skill is active and a feature has been implemented, the AI must perform **both** of the following actions **before considering the feature "done"**:

1. **Write a summary table to the user** explaining the implementation.
2. **Include the same summary table in the git commit description** for that feature.

## Summary Table Format

The summary is a **table** with:

- **Columns**: `What`, `Why`, `How`
- **Rows**: Concrete elements of the implementation (e.g., classes, higher-level modules/packages, major configuration changes, or cross-cutting mechanisms like middlewares and rate limiters).

### Column Semantics

- **What**: A short, concrete description of the implemented element.
  - Examples: `rate limiter`, `NewsFeedPublisher`, `user-notifications API`, `feature flag: new_homepage`.
- **Why**: The main reason this element exists from a product or system perspective.
  - Think: performance, reliability, UX, safety, compliance, maintainability, or domain-specific goals.
- **How**: A concise explanation of how this element works or is used in the system.
  - Focus on high-level mechanism and key collaborators, not line-by-line details.

### Example Summary Table

| What          | Why                          | How                                                                 |
|---------------|------------------------------|---------------------------------------------------------------------|
| rate limiter  | to prevent system overload   | limits too-frequent requests; excess calls receive throttled errors |
| NewsFeedPublisher | to distribute new posts efficiently | publishes events to a message bus; subscribers update user feeds    |

Adjust the number of rows to match the real feature scope (typically 2–10 rows).

## Step 1: Write Summary Table To User

After finishing a feature implementation (including tests and refactors):

1. Identify the main architectural and domain elements you added or changed.
2. Build the `What / Why / How` table as described above.
3. Present the table in the conversation so the user can read and reuse it later.
4. Keep explanations concise but meaningful; assume a future developer (or AI) will rely on this to quickly reconstruct intent and structure.

## Step 2: Embed Summary Table Into Git Commit Description

When creating the git commit for the feature:

1. Use an appropriate, concise commit **title** as usual (e.g., `Add news feed publisher`).
2. In the **commit description/body**, paste the same `What / Why / How` table used in the conversation.
3. If you refined the table after showing it to the user, commit the improved version.

### Commit Message Structure (Recommended)

The commit message body should include a heading and the table:

```text
Add news feed publisher

Feature summary:

| What                | Why                                | How                                                                 |
|---------------------|------------------------------------|---------------------------------------------------------------------|
| rate limiter        | to prevent system overload         | limits too-frequent requests; excess calls receive throttled errors |
| NewsFeedPublisher   | to distribute new posts efficiently| publishes events to a message bus; subscribers update user feeds    |
```

If existing project conventions require a different commit format, keep those conventions but still include the table somewhere in the description.

## Scope and Granularity Guidelines

- **Group by feature**: One table per feature/commit, not per individual function.
- **Prefer higher-level elements** over tiny helpers:
  - Include services, domain classes, controllers, main modules, and key infrastructure pieces.
  - Exclude low-level utilities unless they are conceptually important.
- **Keep it stable over time**: When extending an existing feature, either:
  - Add new rows for new elements, or
  - Update existing rows if their purpose or behavior meaningfully changed.

## Behavior Checklist (For the AI)

Before finishing a feature and its commit:

1. [ ] Have I identified the main elements (What) of this feature?
2. [ ] Have I explained **why** each element exists from a domain/system perspective?
3. [ ] Have I described **how** each element works or is used at a high level?
4. [ ] Have I shown the complete `What / Why / How` table to the user?
5. [ ] Have I included the same table in the git commit description/body?
6. [ ] Is the table concise, clear, and understandable for a future developer or AI?

