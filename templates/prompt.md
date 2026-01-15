# Ralph Iteration Instructions

You are running in a Ralph loop - fresh context each iteration. Your memory comes from files, not conversation history.

## Step 1: Read Project Config

Check for and follow these if they exist:
- `AGENTS.md` - Project-specific instructions (includes graduated learnings from past tasks)
- `CLAUDE.md` - Project-specific Claude rules

These define code style, commits, testing. **Follow them exactly.**

## Step 2: Read Ralph Context

1. `docs/solutions/` - Bug fixes from previous tasks (if exists, scan for relevant issues)
2. `.ralph/progress.txt` - Learnings from THIS task's iterations (read Codebase Patterns first)
3. `.ralph/plan.json` - Your task list
4. `git log --oneline -10` - Recent commits

## Step 3: Select ONE Story

Read `.ralph/plan.json` and find the FIRST story where `"passes": false`.

Work on ONLY that story this iteration.

## Step 4: Implement

- Follow patterns from AGENTS.md/CLAUDE.md
- Apply patterns from Codebase Patterns in progress.txt
- Read relevant code first
- Make minimal, focused changes

## Step 5: Quality Gates

Run commands from `qualityGates` array in plan.json:
- If they fail, debug and fix
- Do not mark story complete if gates fail

## Step 6: Commit

Stage and commit following project conventions (from AGENTS.md/CLAUDE.md).

## Step 7: Update plan.json

Set the completed story to `"passes": true`:

```json
{"id": 1, "title": "The story you completed", "passes": true}
```

If story FAILED after reasonable attempts, leave as `"passes": false` and add `"blocked": true`:

```json
{"id": 1, "title": "Story that failed", "passes": false, "blocked": true}
```

## Step 8: Update progress.txt (EVERY iteration)

**ALWAYS append** to progress.txt (never replace):

```markdown
---
## Iteration N - YYYY-MM-DD HH:MM
**Story**: <title>
**Status**: Passed | Failed | Blocked
**What was done**: <brief summary>
**Files changed**: <list of files>
**Learnings for future iterations**:
- <patterns discovered>
- <useful context>
**Gotchas**:
- <things that tripped you up>
- <non-obvious requirements>
```

If you discovered a **reusable pattern** (applies to ALL future work, not just this story), add it to the Codebase Patterns section at the TOP of progress.txt.

## Step 9: Check Completion

If stories remain with `"passes": false`:
- End normally, loop continues with fresh context

If ALL stories have `"passes": true`:
- Proceed to Step 10 (Graduate Learnings)

## Step 10: Graduate Learnings (ONLY on completion)

Before outputting completion, persist learnings to permanent locations:

### 10a. Codebase Patterns → AGENTS.md

Review the Codebase Patterns section in progress.txt. For each pattern that should persist for ALL future development (not just ralph tasks):

- Append to `AGENTS.md` under an appropriate section
- Use concise format matching existing AGENTS.md style
- Skip if pattern already exists in AGENTS.md

### 10b. Bug Fixes → docs/solutions/

For any non-trivial bugs you fixed (required debugging, non-obvious solution):

Create `docs/solutions/<category>/<description>-<date>.md`:

```markdown
---
date: YYYY-MM-DD
problem_type: <build-error|test-failure|runtime-error|performance-issue>
symptoms:
  - <observable symptom 1>
  - <observable symptom 2>
root_cause: <technical explanation>
---

## Problem
<What went wrong>

## Solution
<What fixed it, with code examples>

## Prevention
<How to avoid in future>
```

Categories: `build-errors/`, `test-failures/`, `runtime-errors/`, `performance-issues/`

### 10c. Commit graduated learnings

```bash
git add AGENTS.md docs/solutions/
git commit -m "docs: graduate learnings from <plan-name>"
```

## Step 11: Signal Completion

After graduating learnings, output:

```
<promise>COMPLETE</promise>
```

## Rules

1. **ONE story per iteration**
2. **ALWAYS update plan.json** - tracks story progress
3. **ALWAYS append to progress.txt** - working memory for this task
4. **Graduate learnings ONLY on completion** - permanent memory for future tasks
5. Read Codebase Patterns FIRST each iteration
6. Do NOT output `<promise>COMPLETE</promise>` until learnings are graduated
7. If stuck, mark story blocked and document in progress.txt
