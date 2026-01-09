# Ralph Fresh

Bash-based fresh context loop for [Claude Code](https://claude.ai/code) with learning features.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Why Fresh Context?

Research shows that spawning fresh AI processes each iteration outperforms persistent sessions:
- **~90% lower token costs** - No accumulated context noise
- **Better performance** - Clean slate each time
- **Persistent learning** - Knowledge persists via files, not conversation history

See [Anthropic's research on context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) for details.

## Features

- **Fresh context**: Each iteration spawns a new `claude` process
- **Learning files**: progress.txt captures learnings, task.md tracks state
- **Codebase Patterns**: Dedicated section for reusable patterns across ALL tasks
- **Passes/Fails tracking**: Task Progress table with status per story
- **Branch archiving**: Auto-archives progress when switching git branches
- **Circuit breaker**: Stops after N iterations with no progress
- **Configurable timeout**: Kills stuck iterations after N minutes
- **Dual completion**: Requires 2 consecutive completion signals to exit

## Requirements

- [Claude Code CLI](https://claude.ai/code) installed and authenticated
- Bash 4.0+
- Git

## Installation

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/ralph-fresh.git
cd ralph-fresh

# Optional: Add to PATH for convenience
ln -s "$(pwd)/ralph.sh" ~/.local/bin/ralph
ln -s "$(pwd)/ralph-init.sh" ~/.local/bin/ralph-init
```

## Quick Start

```bash
# 1. Go to your project
cd /path/to/your/project

# 2. Initialize ralph
ralph-init.sh "Add user authentication with JWT"

# 3. Edit .ralph/task.md to define your stories

# 4. Run the loop
ralph.sh --max-iterations 20 --verbose
```

## Usage

### Initialize a task

```bash
ralph-init.sh "Your task description"
```

Creates `.ralph/` directory with:
- `task.md` - Task checklist (edit this!)
- `progress.txt` - Learnings log with Codebase Patterns section
- `prompt.md` - Instructions for Claude (customizable)

### Define your stories

Edit `.ralph/task.md`:

```markdown
# Task: Add user authentication with JWT

## Stories (in priority order)
- [ ] Set up auth database schema and migrations
- [ ] Implement login endpoint with JWT generation
- [ ] Add authentication middleware
- [ ] Create logout endpoint
- [ ] Write integration tests

## Quality Gates
pnpm typecheck
pnpm test
```

### Run the loop

```bash
ralph.sh [OPTIONS]

Options:
  --max-iterations N      Max iterations before stop (default: 10)
  --timeout N             Minutes per iteration before kill (default: 15)
  --completion-promise S  Text to detect completion (default: COMPLETE)
  --no-commit             Do not auto-commit (user reviews and commits manually)
  --verbose               Show detailed output
  --help                  Show help
```

**Examples:**

```bash
# Run with defaults (10 iterations, 15min timeout)
ralph.sh

# Run with custom limits
ralph.sh --max-iterations 50 --timeout 30

# Run with verbose output
ralph.sh --max-iterations 20 --verbose

# Disable auto-commit (review changes manually)
ralph.sh --no-commit --max-iterations 20

# Custom completion promise
ralph.sh --completion-promise "ALL DONE" --max-iterations 15
```

## How It Works

```
ralph.sh
    │
    ├── Check branch (archive if changed)
    │
    ├── Iteration 1: claude -p "..." → implements story 1 → updates progress.txt
    │
    ├── Iteration 2: claude -p "..." → reads patterns → implements story 2
    │
    └── ... until <promise>COMPLETE</promise> or max iterations
```

Each iteration:
1. Checks for branch change (archives old progress if changed)
2. Spawns a **fresh** `claude` process (clean context)
3. Claude reads Codebase Patterns section first
4. Claude reads Task Progress table for passes/fails
5. Claude reads iteration log for recent learnings
6. Implements ONE story
7. Updates files for next iteration
8. Outputs `<promise>COMPLETE</promise>` when all stories done

## Learning System

### Codebase Patterns

Reusable patterns at the top of progress.txt:

```markdown
## Codebase Patterns (reusable across ALL tasks)
- ORM: Drizzle, schema in src/db/schema.ts
- API: Use zodios pattern in src/api/
- Tests: Run `pnpm test:unit` for fast feedback
```

### Task Progress Table

Track passes/fails per story:

```markdown
| Story | Status | Iteration |
|-------|--------|-----------|
| Set up auth schema | Passed | 1 |
| Implement login | Passed | 2 |
| Add middleware | Failed | 3 |
```

### Story Status

- `[ ]` = **Pending** - Not yet attempted
- `[x]` = **Passed** - Story complete, quality gates passed
- `[!]` = **Failed** - Story attempted but quality gates failed

## Branch Archiving

When you switch git branches, ralph automatically:
1. Archives current progress to `.ralph/archive/<date>-<branch>/`
2. Resets progress.txt for the new branch

```
.ralph/
├── archive/
│   └── 2024-01-09-1030-feature-auth/
│       ├── progress.txt
│       └── task.md
├── progress.txt (current)
└── task.md (current)
```

## Safety Features

| Feature | Default | Description |
|---------|---------|-------------|
| Max iterations | 10 | Hard stop after N iterations |
| Timeout | 15 min | Kill stuck iterations |
| Circuit breaker | 3 | Exit after N no-progress iterations |
| Dual completion | 2 | Require N consecutive completion signals |

## Project Configuration

Ralph respects your project's existing configuration files:

- **`AGENTS.md`** - If present, Claude follows these agent-specific instructions
- **`CLAUDE.md`** - If present, Claude follows these Claude-specific instructions

These files take precedence over ralph's default behavior for:
- Code style and formatting
- Commit message conventions
- Testing commands
- Any other project-specific rules

This means ralph integrates seamlessly with your existing workflow without overriding your preferences.

## Troubleshooting

### Circuit breaker triggered

Claude made no progress for 3 iterations. Check:
- Is the story too large? Break it down.
- Are quality gates failing? Check the output.
- Review progress.txt for what Claude tried.

### Timeout triggered

An iteration took too long. Options:
- Increase timeout: `--timeout 30`
- Break story into smaller pieces
- Add more context in task.md Notes section

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

This project builds on the work of others:

- **[Geoffrey Huntley](https://ghuntley.com/ralph/)** - Original Ralph Wiggum technique
- **[snarktank/ralph](https://github.com/snarktank/ralph)** - Learning features (progress.txt, Codebase Patterns, branch archiving)
- **[Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)** - Research on context engineering for AI agents

## License

MIT License - see [LICENSE](LICENSE) file for details.
