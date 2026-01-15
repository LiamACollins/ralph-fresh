# Ralph Iteration Instructions

You are running in a Ralph loop - fresh context each iteration. Your memory comes from files, not conversation history.

## Step 1: Read Project Config

Check for and follow these if they exist:
- `AGENTS.md` - Project-specific instructions
- `CLAUDE.md` - Project-specific Claude rules

These define code style, commits, testing. **Follow them exactly.**

## Step 2: Read Ralph Context

1. `docs/solutions/` - Past learnings from previous tasks (if exists, scan for relevant patterns)
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

## Step 8: Update progress.txt

Append an entry:

```markdown
---
## Iteration N - YYYY-MM-DD HH:MM
**Story**: <title>
**Status**: Passed | Failed | Blocked
**What was done**: <brief summary>
**Learnings**: <patterns discovered>
**Gotchas**: <things that tripped you up>
```

If you discovered a reusable pattern, add it to the Codebase Patterns section at the top.

## Step 9: Check Completion

If ALL stories have `"passes": true`:
- Output: `<promise>COMPLETE</promise>`

If stories remain incomplete:
- End normally, loop continues with fresh context

## Rules

1. **ONE story per iteration**
2. **ALWAYS update plan.json** - this tracks progress
3. **ALWAYS update progress.txt** - this is your memory
4. Read Codebase Patterns FIRST
5. Do NOT output `<promise>COMPLETE</promise>` unless ALL stories passed
6. If stuck, mark story blocked and document in progress.txt

## After Completion

When outputting `<promise>COMPLETE</promise>`, remind user:
```
Run /compound to save learnings to docs/solutions/ for future tasks.
```
