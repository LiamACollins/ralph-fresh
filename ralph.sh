#!/bin/bash
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

MAX_ITERATIONS=10
TIMEOUT_MINUTES=15
COMPLETION_PROMISE="COMPLETE"
VERBOSE=false
NO_COMMIT=false
RALPH_DIR=".ralph"
ARCHIVE_DIR=".ralph/archive"

CB_NO_PROGRESS_THRESHOLD=3
DUAL_COMPLETION_REQUIRED=2

usage() {
  cat <<EOF
ralph.sh - Fresh context loop for Claude Code

Usage: ralph.sh [OPTIONS]

Options:
  --max-iterations N      Max iterations before stop (default: $MAX_ITERATIONS)
  --timeout N             Minutes per iteration before kill (default: $TIMEOUT_MINUTES)
  --completion-promise S  Text to detect completion (default: $COMPLETION_PROMISE)
  --no-commit             Do not auto-commit after each story
  --verbose               Show detailed output
  --help                  Show this help

Prerequisites:
  Run ralph-init.sh first to create $RALPH_DIR/ in your project

Example:
  ralph.sh --max-iterations 20 --timeout 15 --verbose
  ralph.sh --no-commit --max-iterations 10
EOF
  exit 0
}

log() {
  if [[ "$VERBOSE" == true ]]; then
    echo "[ralph] $1"
  fi
}

log_always() {
  echo "[ralph] $1"
}

get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

archive_branch_files() {
  local old_branch="$1"
  local archive_name
  local clean_branch

  clean_branch="${old_branch#ralph/}"
  archive_name="$(date +%Y-%m-%d-%H%M)-${clean_branch}"

  mkdir -p "$ARCHIVE_DIR/$archive_name"

  if [[ -f "$RALPH_DIR/progress.txt" ]]; then
    cp "$RALPH_DIR/progress.txt" "$ARCHIVE_DIR/$archive_name/"
  fi
  if [[ -f "$RALPH_DIR/task.md" ]]; then
    cp "$RALPH_DIR/task.md" "$ARCHIVE_DIR/$archive_name/"
  fi

  log_always "Archived previous branch files to $ARCHIVE_DIR/$archive_name/"
}

reset_progress_for_new_branch() {
  local new_branch="$1"

  if [[ -f "$RALPH_DIR/progress.txt" ]]; then
    cat > "$RALPH_DIR/progress.txt" <<EOF
# Progress Log

## Codebase Patterns (reusable across ALL tasks)

<!-- Patterns discovered during this task -->

---

## Task Progress

| Story | Status | Iteration |
|-------|--------|-----------|

---

## Iteration Log

Started: $(date '+%Y-%m-%d %H:%M')
Branch: $new_branch

EOF
    log_always "Reset progress.txt for new branch: $new_branch"
  fi
}

check_branch_change() {
  local current_branch
  local last_branch_file="$RALPH_DIR/.last-branch"

  current_branch=$(get_current_branch)

  if [[ -f "$last_branch_file" ]]; then
    local last_branch
    last_branch=$(cat "$last_branch_file")

    if [[ "$current_branch" != "$last_branch" ]]; then
      log_always "Branch changed: $last_branch -> $current_branch"
      archive_branch_files "$last_branch"
      reset_progress_for_new_branch "$current_branch"
    fi
  fi

  echo "$current_branch" > "$last_branch_file"
}

write_runtime_config() {
  cat > "$RALPH_DIR/.runtime-config" <<EOF
NO_COMMIT=$NO_COMMIT
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT_MINUTES="$2"
      shift 2
      ;;
    --completion-promise)
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --no-commit)
      NO_COMMIT=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

if [[ ! -d "$RALPH_DIR" ]]; then
  echo "Error: $RALPH_DIR/ not found. Run ralph-init.sh first."
  exit 1
fi

if [[ ! -f "$RALPH_DIR/prompt.md" ]]; then
  echo "Error: $RALPH_DIR/prompt.md not found."
  exit 1
fi

if [[ ! -f "$RALPH_DIR/task.md" ]]; then
  echo "Error: $RALPH_DIR/task.md not found."
  exit 1
fi

check_branch_change
write_runtime_config

no_progress_count=0
completion_signal_count=0
last_task_md_hash=""

get_task_hash() {
  md5 -q "$RALPH_DIR/task.md" 2>/dev/null || md5sum "$RALPH_DIR/task.md" | cut -d' ' -f1
}

check_progress() {
  local current_hash
  current_hash=$(get_task_hash)

  if [[ "$current_hash" != "$last_task_md_hash" ]]; then
    last_task_md_hash="$current_hash"
    return 0
  fi
  return 1
}

current_branch=$(get_current_branch)
log_always "Starting ralph loop"
log_always "Branch: $current_branch"
log_always "Max iterations: $MAX_ITERATIONS"
log_always "Timeout: ${TIMEOUT_MINUTES}m per iteration"
log_always "Completion promise: $COMPLETION_PROMISE"
if [[ "$NO_COMMIT" == true ]]; then
  log_always "Auto-commit: disabled"
fi
echo ""

last_task_md_hash=$(get_task_hash)

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  echo "========================================"
  log_always "Iteration $i of $MAX_ITERATIONS"
  echo "========================================"

  PROMPT=$(cat "$RALPH_DIR/prompt.md")

  TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))

  log "Running claude with ${TIMEOUT_MINUTES}m timeout..."

  # Determine timeout command (gtimeout on macOS via coreutils, timeout on Linux)
  TIMEOUT_CMD=""
  if command -v gtimeout &> /dev/null; then
    TIMEOUT_CMD="gtimeout"
  elif command -v timeout &> /dev/null; then
    TIMEOUT_CMD="timeout"
  fi

  set +e
  if [[ -n "$TIMEOUT_CMD" ]]; then
    OUTPUT=$($TIMEOUT_CMD "${TIMEOUT_SECONDS}s" claude -p "$PROMPT" --dangerously-skip-permissions 2>&1)
    EXIT_CODE=$?
  else
    log "Warning: no timeout command found, running without timeout"
    OUTPUT=$(claude -p "$PROMPT" --dangerously-skip-permissions 2>&1)
    EXIT_CODE=$?
  fi
  set -e

  if [[ $EXIT_CODE -eq 124 ]]; then
    log_always "Iteration timed out after ${TIMEOUT_MINUTES} minutes"
    no_progress_count=$((no_progress_count + 1))
    completion_signal_count=0

    if [[ $no_progress_count -ge $CB_NO_PROGRESS_THRESHOLD ]]; then
      log_always "Circuit breaker: $CB_NO_PROGRESS_THRESHOLD timeouts in a row. Stopping."
      exit 1
    fi
    continue
  fi

  echo "$OUTPUT"

  if echo "$OUTPUT" | grep -q "<promise>$COMPLETION_PROMISE</promise>"; then
    completion_signal_count=$((completion_signal_count + 1))
    log "Completion signal detected ($completion_signal_count/$DUAL_COMPLETION_REQUIRED)"

    if [[ $completion_signal_count -ge $DUAL_COMPLETION_REQUIRED ]]; then
      log_always "Verified complete ($DUAL_COMPLETION_REQUIRED consecutive signals)"
      exit 0
    fi
  else
    completion_signal_count=0
  fi

  if check_progress; then
    log "Progress detected (task.md changed)"
    no_progress_count=0
  else
    no_progress_count=$((no_progress_count + 1))
    log "No progress detected ($no_progress_count/$CB_NO_PROGRESS_THRESHOLD)"

    if [[ $no_progress_count -ge $CB_NO_PROGRESS_THRESHOLD ]]; then
      log_always "Circuit breaker: $CB_NO_PROGRESS_THRESHOLD iterations with no progress. Stopping."
      exit 1
    fi
  fi

  echo ""
  sleep 2
done

log_always "Max iterations ($MAX_ITERATIONS) reached without completion"
exit 1
