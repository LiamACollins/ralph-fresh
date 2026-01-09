#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
RALPH_DIR=".ralph"

usage() {
  cat <<EOF
ralph-init.sh - Initialize ralph files in current project

Usage: ralph-init.sh "Task description"

Creates:
  $RALPH_DIR/task.md       - Task checklist (edit this!)
  $RALPH_DIR/progress.txt  - Learnings log (auto-updated)
  $RALPH_DIR/prompt.md     - Instructions for Claude (customizable)

Example:
  cd /path/to/your/project
  ralph-init.sh "Add user authentication with JWT"
EOF
  exit 0
}

get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  usage
fi

TASK_DESCRIPTION="$*"
CURRENT_BRANCH=$(get_current_branch)

if [[ -d "$RALPH_DIR" ]]; then
  echo "Warning: $RALPH_DIR/ already exists"
  read -p "Overwrite? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

mkdir -p "$RALPH_DIR"

sed "s/{{TASK_DESCRIPTION}}/$TASK_DESCRIPTION/g" "$TEMPLATES_DIR/task.md.template" > "$RALPH_DIR/task.md"

cp "$TEMPLATES_DIR/progress.txt.template" "$RALPH_DIR/progress.txt"
{
  echo "Started: $(date '+%Y-%m-%d %H:%M')"
  echo "Branch: $CURRENT_BRANCH"
  echo ""
} >> "$RALPH_DIR/progress.txt"

cp "$TEMPLATES_DIR/prompt.md" "$RALPH_DIR/prompt.md"

echo "$CURRENT_BRANCH" > "$RALPH_DIR/.last-branch"

if [[ -f .gitignore ]]; then
  if ! grep -q "^\.ralph/$" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# Ralph working files" >> .gitignore
    echo ".ralph/" >> .gitignore
    echo "Added .ralph/ to .gitignore"
  fi
fi

echo ""
echo "Initialized ralph in $RALPH_DIR/"
echo "Branch: $CURRENT_BRANCH"
echo ""
echo "Next steps:"
echo "  1. Edit $RALPH_DIR/task.md to define your stories"
echo "  2. Run: ralph.sh --max-iterations 20 --verbose"
echo ""
