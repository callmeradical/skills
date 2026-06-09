#!/usr/bin/env bash
# spawn_agent.sh - Spawn an opencode agent in a new tmux window for a focused task.
#
# Each agent optionally gets its own git worktree so parallel agents never
# touch each other's working tree.
#
# Usage:
#   spawn_agent.sh --window <name> --task-id <td-id> --description <text> \
#                  [--dir <path>] [--worktree] [--branch <name>] [--dry-run]
#
# Options:
#   --window <name>        tmux window name (short slug, e.g. "auth")
#   --task-id <id>         td task ID (e.g. td-a1b2)
#   --description <text>   one-line description of what this agent should accomplish
#   --dir <path>           working directory (default: $PWD; git root used for worktrees)
#   --worktree             create a git worktree for this agent (recommended for parallel work)
#   --branch <name>        branch name for the worktree (default: drive/<task-id>-<window>)
#   --dry-run              print the prompt and tmux command without executing

set -euo pipefail

WINDOW_NAME=""
TASK_ID=""
DESCRIPTION=""
WORK_DIR="${PWD}"
USE_WORKTREE=false
BRANCH_NAME=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --window)      WINDOW_NAME="$2";   shift 2 ;;
    --task-id)     TASK_ID="$2";       shift 2 ;;
    --description) DESCRIPTION="$2";   shift 2 ;;
    --dir)         WORK_DIR="$2";      shift 2 ;;
    --worktree)    USE_WORKTREE=true;  shift ;;
    --branch)      BRANCH_NAME="$2";   shift 2 ;;
    --dry-run)     DRY_RUN=true;       shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ---- Validation -------------------------------------------------------------
[[ -z "$WINDOW_NAME" ]]  && { echo "--window is required"      >&2; exit 1; }
[[ -z "$TASK_ID" ]]      && { echo "--task-id is required"     >&2; exit 1; }
[[ -z "$DESCRIPTION" ]]  && { echo "--description is required" >&2; exit 1; }

if [[ -z "${TMUX:-}" ]]; then
  echo "Error: Not inside a tmux session. Cannot spawn windows." >&2
  exit 1
fi

SESSION=$(tmux display-message -p '#S')

# ---- Git worktree setup -----------------------------------------------------
AGENT_DIR="$WORK_DIR"

if $USE_WORKTREE; then
  GIT_ROOT=$(git -C "$WORK_DIR" rev-parse --show-toplevel 2>/dev/null) || {
    echo "Error: --worktree requires a git repository." >&2
    exit 1
  }
  REPO_NAME=$(basename "$GIT_ROOT")
  [[ -z "$BRANCH_NAME" ]] && BRANCH_NAME="drive/${TASK_ID}-${WINDOW_NAME}"

  # Place worktrees as siblings of the repo root
  WORKTREE_DIR="${GIT_ROOT}/../${REPO_NAME}-wt-${WINDOW_NAME}"

  if [[ ! -d "$WORKTREE_DIR" ]]; then
    if $DRY_RUN; then
      echo "(dry-run) Would create worktree: $WORKTREE_DIR on branch $BRANCH_NAME"
    else
      git -C "$GIT_ROOT" worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME"
      echo "Created worktree: $WORKTREE_DIR (branch: $BRANCH_NAME)"
    fi
  else
    echo "Reusing existing worktree: $WORKTREE_DIR"
  fi

  AGENT_DIR=$(realpath "$WORKTREE_DIR" 2>/dev/null || echo "$WORKTREE_DIR")
fi

# ---- Build the bootstrap prompt ---------------------------------------------
WORKTREE_NOTE=""
if $USE_WORKTREE; then
  WORKTREE_NOTE="
## Working directory
You are in a dedicated git worktree: \`${AGENT_DIR}\` (branch: \`${BRANCH_NAME}\`)
Commit your work to this branch. Do not push. The orchestrator will review and merge."
fi

read -r -d '' PROMPT << ENDOFPROMPT || true
You are an autonomous developer. Work independently to drive your task to completion.

## Orientation (run this first)
\`\`\`bash
td usage --new-session
td start ${TASK_ID}
\`\`\`
${WORKTREE_NOTE}
## Your task
**ID:** ${TASK_ID}
**Goal:** ${DESCRIPTION}

## Required workflow

### 1. Orient
Run \`td usage --new-session\` and \`td context ${TASK_ID}\` to load full context.

### 2. Choose a slice strategy based on the task

**Vertical slice (default for self-contained features)**
Implement one complete behavior at a time end-to-end using TDD:
  RED: write a failing test for the next behavior
  GREEN: write minimal code to pass it
  Repeat; refactor only after all tests pass.
  Never write all tests first; never refactor while RED.

**Tracer bullet (for new systems or deep stack work)**
Fire a thin slice through the entire stack first to prove connectivity:
  - Implement the thinnest possible end-to-end path (e.g., request hits handler, calls DB, returns response)
  - Write a test that exercises this path
  - Once the tracer is GREEN, fill in each layer fully via vertical TDD slices

### 3. Log as you go
\`\`\`bash
td log "what you just did"
td log --decision "why you chose approach X"
td log --blocker "if genuinely stuck"
td link ${TASK_ID} path/to/file.ts   # track every file you change
\`\`\`

### 4. Hand off when done
\`\`\`bash
td handoff ${TASK_ID} \\
  --done "what is fully complete" \\
  --remaining "none" \\
  --decision "key architectural decisions"
td review ${TASK_ID}
\`\`\`

Work autonomously. Do not ask for confirmation unless genuinely blocked.
ENDOFPROMPT

# ---- Dry run ----------------------------------------------------------------
if $DRY_RUN; then
  echo "=== DRY RUN ==="
  echo "Session:     $SESSION"
  echo "Window:      $WINDOW_NAME"
  echo "Directory:   $AGENT_DIR"
  [[ -n "$BRANCH_NAME" ]] && echo "Branch:      $BRANCH_NAME"
  echo ""
  echo "--- Prompt ---"
  echo "$PROMPT"
  exit 0
fi

# ---- Create tmux window and launch opencode ---------------------------------
tmux new-window -t "${SESSION}" -n "${WINDOW_NAME}" -c "${AGENT_DIR}"
sleep 0.3
tmux send-keys -t "${SESSION}:${WINDOW_NAME}" "opencode --prompt $(printf '%q' "$PROMPT")" Enter

echo "Spawned agent '${WINDOW_NAME}' in session '${SESSION}' for task ${TASK_ID}"
[[ -n "$BRANCH_NAME" ]] && echo "  Worktree branch: $BRANCH_NAME → $AGENT_DIR"
