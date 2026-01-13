#!/bin/bash
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
RALPH_DIR=".ralph"

usage() {
  cat <<EOF
ralph-init.sh - Initialize ralph with a plan file

Usage: ralph-init.sh <plan-file>

Creates:
  $RALPH_DIR/plan.md       - Your plan (copied from argument)
  $RALPH_DIR/progress.txt  - Learnings log (auto-updated)
  $RALPH_DIR/prompt.md     - Instructions for Claude (customizable)

Example:
  cd /path/to/your/project
  ralph-init.sh docs/plans/add-user-auth.md
EOF
  exit 0
}

get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  usage
fi

PLAN_FILE="$1"

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "Error: Plan file not found: $PLAN_FILE"
  exit 1
fi

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

# Copy the plan file
cp "$PLAN_FILE" "$RALPH_DIR/plan.md"

cp "$TEMPLATES_DIR/progress.txt.template" "$RALPH_DIR/progress.txt"
{
  echo "Started: $(date '+%Y-%m-%d %H:%M')"
  echo "Branch: $CURRENT_BRANCH"
  echo "Plan: $PLAN_FILE"
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
echo "Plan: $PLAN_FILE -> $RALPH_DIR/plan.md"
echo "Branch: $CURRENT_BRANCH"
echo ""
echo "Next steps:"
echo "  1. Review $RALPH_DIR/plan.md (ensure stories have [ ] checkboxes)"
echo "  2. Run: ralph.sh --max-iterations 20 --verbose"
echo ""
