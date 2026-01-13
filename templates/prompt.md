# Ralph Iteration Instructions

You are running in a Ralph loop - an iterative development process where each iteration is a fresh context. Your memory between iterations comes from files, not conversation history.

## Step 0: Check Runtime Config

Read `.ralph/.runtime-config` for runtime settings:
- `NO_COMMIT=true` means do NOT commit changes (user will review and commit manually)
- `NO_COMMIT=false` means commit after each successful story

## Step 1: Read Project Configuration

**Before doing any work**, check for and follow these project files if they exist:
- `AGENTS.md` - Project-specific agent instructions
- `CLAUDE.md` - Project-specific Claude instructions

These files define code style, commit conventions, testing commands, and other project-specific rules. **Follow them exactly.**

## Step 2: Read Ralph Context

Read these files to understand current task state:

1. `.ralph/progress.txt` - Learnings from previous iterations
   - **Read the "Codebase Patterns" section first** - reusable patterns for this repo
   - Check the "Task Progress" table for passes/fails status
   - Review recent iteration entries for context
2. `.ralph/plan.md` - Your plan with stories to implement
3. Recent git log: `git log --oneline -10`

## Step 3: Select ONE Story

Look at `.ralph/plan.md` and find the FIRST unchecked story `- [ ]`.

Work on ONLY that story this iteration. Do not work on multiple stories.

## Step 4: Implement

Implement the story:
- Follow patterns from the project's AGENTS.md or CLAUDE.md
- Apply patterns from the "Codebase Patterns" section in progress.txt
- Read relevant code first to understand existing patterns
- Make minimal, focused changes

## Step 5: Quality Gates

Run any quality gates specified in `.ralph/plan.md` (look for a "Quality Gates" or "Testing" section):
- If tests/typecheck commands are listed, run them
- If they fail, debug and fix before proceeding
- Do not mark a story complete if quality gates fail

## Step 6: Commit (if enabled)

Check `.ralph/.runtime-config`:
- If `NO_COMMIT=false`: Stage and commit your changes following the project's commit conventions (from AGENTS.md/CLAUDE.md)
- If `NO_COMMIT=true`: Skip committing, user will review and commit manually

## Step 7: Update plan.md

Mark the completed story with `[x]`:
```markdown
- [x] The story you just completed
```

If the story FAILED (quality gates didn't pass after reasonable attempts), mark with `[!]`:
```markdown
- [!] The story that failed
```

## Step 8: Update progress.txt

### 8a. Update Task Progress Table

Add or update a row in the "Task Progress" table:
```markdown
| Story description | Passed/Failed/Blocked | N |
```

### 8b. Append Iteration Entry

Append an entry to the "Iteration Log" section:

```markdown
---
## Iteration N - YYYY-MM-DD HH:MM
**Story**: <story description>
**Status**: Passed | Failed | Blocked
**What was done**: <brief summary>
**Learnings**:
- <pattern discovered>
- <useful context for future iterations>
**Gotchas**:
- <things that tripped you up>
- <non-obvious requirements>
```

### 8c. Update Codebase Patterns (if applicable)

If you discovered a pattern that applies to ALL future work in this repo (not just this task), add it to the "Codebase Patterns" section at the TOP of progress.txt.

Good patterns to add:
- Database/ORM conventions
- API patterns and utilities
- Testing commands and strategies
- File structure conventions
- Build/deployment commands

Do NOT add task-specific details here - only genuinely reusable patterns.

## Step 9: Update AGENTS.md/CLAUDE.md (only if applicable)

If you discovered a genuinely reusable pattern that should persist beyond this ralph task (for ALL future development), add it to the project's `AGENTS.md` or `CLAUDE.md` file (if one exists).

**Note**: The Codebase Patterns section in progress.txt is for patterns discovered during THIS ralph task. AGENTS.md/CLAUDE.md is for permanent, repo-wide patterns.

## Step 10: Check Completion

If ALL stories in plan.md are marked `[x]` (passed):
- Output: `<promise>COMPLETE</promise>`

If stories remain (including `[!]` failed stories):
- End your response normally
- The loop will start a new iteration with fresh context

## Important Rules

1. **Follow AGENTS.md/CLAUDE.md** - Project rules override these instructions
2. ONE story per iteration - do not try to do multiple
3. ALWAYS update progress.txt - this is how you remember
4. ALWAYS update plan.md - this tracks what's done
5. Read the Codebase Patterns section FIRST - learn from past discoveries
6. Track passes/fails in the Task Progress table
7. Do NOT output `<promise>COMPLETE</promise>` unless ALL stories passed
8. If stuck, document what's blocking in progress.txt and mark story as `[!]`
9. Check NO_COMMIT setting before committing

## Status Meanings

- `[ ]` = **Pending** - Not yet attempted
- `[x]` = **Passed** - Story complete, quality gates passed
- `[!]` = **Failed** - Story attempted but quality gates failed after reasonable effort
