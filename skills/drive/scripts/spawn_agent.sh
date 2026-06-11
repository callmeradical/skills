#!/usr/bin/env bash
# spawn_agent.sh - Spawn a goose agent in a new tmux pane (split) for a focused task.
#
# Each agent optionally gets its own git worktree so parallel agents never
# touch each other's working tree.
#
# Usage:
#   spawn_agent.sh --window <name> --task-id <td-id> --description <text> \
#                  [--dir <path>] [--worktree] [--branch <name>] [--dry-run]
#
# Options:
#   --window <name>        pane label / slug (short, e.g. "auth") — used for worktree naming
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
  echo "Error: Not inside a tmux session. Cannot spawn panes." >&2
  exit 1
fi

# ---- Dedicated drive session ------------------------------------------------
# Agents always run in a separate tmux session so they never interfere with
# the operator's current session. The session is named after the project
# (git repo basename) suffixed with "-drive", e.g. "ascend-arch-smith-drive".
# If the session already exists it is reused; otherwise it is created detached.
_REPO_NAME=$(git -C "${WORK_DIR}" rev-parse --show-toplevel 2>/dev/null \
  | xargs basename 2>/dev/null || basename "${WORK_DIR}")
DRIVE_SESSION="${_REPO_NAME}-drive"

if ! tmux has-session -t "${DRIVE_SESSION}" 2>/dev/null; then
  tmux new-session -d -s "${DRIVE_SESSION}" -c "${WORK_DIR}"
  echo "Created dedicated drive session '${DRIVE_SESSION}'"
else
  echo "Reusing drive session '${DRIVE_SESSION}'"
fi

SESSION="${DRIVE_SESSION}"

# ---- Decorate the drive session ---------------------------------------------
# Show a title bar at the top of every pane. We store the agent name as a
# pane user option (@agent) rather than pane_title because running processes
# (goose) override pane_title via terminal escape sequences.
# allow-rename and automatic-rename are disabled so goose can't clobber names.
tmux set-option -t "${SESSION}" pane-border-status top
tmux set-option -t "${SESSION}" pane-border-format " #{?pane_active,#[fg=colour39#,bold],#[fg=colour244]}#{@agent_status} 🪿 #{@agent_name}#{?#{@agent_task}, #[fg=colour243]· #{@agent_task},}#[default] "
tmux set-option -t "${SESSION}" pane-active-border-style "fg=colour39"
tmux set-option -t "${SESSION}" pane-border-style "fg=colour237"
tmux set-option -t "${SESSION}" allow-rename off
tmux set-option -t "${SESSION}" automatic-rename off

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
You have access to all skills in ~/.opencode/skills via the skills extension.

## Step 1 — Load task management skill
Load the td-task-management skill to get full command reference and workflows:
load_skill("td-task-management")

## Step 2 — Orient with td
\`\`\`bash
td usage --new-session
td start ${TASK_ID}
td context ${TASK_ID}
\`\`\`
${WORKTREE_NOTE}
## Your task
**ID:** ${TASK_ID}
**Goal:** ${DESCRIPTION}

## Required workflow

### 1. Track every action with td
All work must be logged. Use td throughout — not just at the start and end.

\`\`\`bash
td log "what you just did"
td log --decision "why you chose approach X"
td log --blocker "if genuinely stuck"
td log --uncertain "if something is ambiguous"
td link ${TASK_ID} path/to/file.ts   # track every file you change
\`\`\`

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

### 3. Before context ends — always hand off
\`\`\`bash
td handoff ${TASK_ID} \\
  --done "what is fully complete" \\
  --remaining "none or what is left" \\
  --decision "key architectural decisions" \\
  --uncertain "anything you were unsure about"
td review ${TASK_ID}
\`\`\`

Work autonomously. Do not ask for confirmation unless genuinely blocked.
ENDOFPROMPT

# ---- Dry run ----------------------------------------------------------------
if $DRY_RUN; then
  echo "=== DRY RUN ==="
  echo "Drive session: ${DRIVE_SESSION} (created if missing)"
  echo "Window:        agents (created if missing, max 4 panes)"
  echo "Pane label:    $WINDOW_NAME"
  echo "Directory:     $AGENT_DIR"
  [[ -n "$BRANCH_NAME" ]] && echo "Branch:        $BRANCH_NAME"
  echo ""
  echo "--- Prompt ---"
  echo "$PROMPT"
  exit 0
fi

# ---- Find or create an agents window with an idle pane ---------------------
# Each agents window is pre-templated with MAX_PANES side-by-side panes on
# creation. Idle panes are titled "idle"; spawning claims the first idle pane.
# When all panes are claimed a new agents window is created (agents-2, etc.).
MAX_PANES=4
IDLE_TITLE="idle"

# All windows in this session matching ^agents(-[0-9]+)?$, sorted.
_agents_windows() {
  tmux list-windows -t "${SESSION}" -F '#{window_name}' \
    | grep -E '^agents(-[0-9]+)?$' \
    | sort -V
}

# Pre-template a freshly created agents window with MAX_PANES idle panes.
# The window already has 1 pane from new-window; split to reach MAX_PANES.
_init_agents_window() {
  local win="$1" dir="$2"
  # Label the initial pane idle via user options (immune to process overrides).
  local first
  first=$(tmux display-message -t "${SESSION}:${win}.0" -p '#{pane_id}')
  tmux set-option -p -t "$first" @agent_name "${IDLE_TITLE}"
  tmux set-option -p -t "$first" @agent_task ""
  tmux set-option -p -t "$first" @agent_status "○"
  # Split to fill up to MAX_PANES, labelling each new pane idle.
  for (( i=2; i<=MAX_PANES; i++ )); do
    local p
    p=$(tmux split-window -h -t "${SESSION}:${win}" -c "$dir" -P -F '#{pane_id}')
    tmux set-option -p -t "$p" @agent_name "${IDLE_TITLE}"
    tmux set-option -p -t "$p" @agent_task ""
    tmux set-option -p -t "$p" @agent_status "○"
  done
  tmux select-layout -t "${SESSION}:${win}" even-horizontal
}

# Return the pane_id of the first idle pane in the given window, or empty.
_first_idle_pane() {
  local win="$1"
  tmux list-panes -t "${SESSION}:${win}" -F '#{pane_id} #{@agent_name}' \
    | awk -v title="${IDLE_TITLE}" '$2 == title { print $1; exit }'
}

# Walk existing agents windows; pick the first with an idle pane.
AGENTS_WINDOW=""
while IFS= read -r win; do
  if [[ -n "$(_first_idle_pane "$win")" ]]; then
    AGENTS_WINDOW="$win"
    break
  fi
done < <(_agents_windows)

# No window with an idle pane — create and pre-template a new one.
if [[ -z "$AGENTS_WINDOW" ]]; then
  existing_count=$(_agents_windows | grep -c . || true)
  if [[ "$existing_count" -eq 0 ]]; then
    AGENTS_WINDOW="agents"
  else
    AGENTS_WINDOW="agents-$((existing_count + 1))"
  fi
  tmux new-window -t "${SESSION}" -n "${AGENTS_WINDOW}" -c "${AGENT_DIR}"
  _init_agents_window "${AGENTS_WINDOW}" "${AGENT_DIR}"
  # Give every shell in the pre-created panes time to initialise before
  # send-keys fires into them.
  sleep 1
  echo "Created tmux window '${AGENTS_WINDOW}' (${MAX_PANES} idle panes) in session '${SESSION}'"
else
  echo "Using tmux window '${AGENTS_WINDOW}' in session '${SESSION}'"
fi

# ---- Claim the first idle pane and launch the agent ------------------------
PANE_ID=$(_first_idle_pane "${AGENTS_WINDOW}")
# Navigate to the agent's working directory.
tmux send-keys -t "$PANE_ID" "cd $(printf '%q' "$AGENT_DIR")" Enter
# Claim the pane — set name, task ID, and running status.
tmux set-option -p -t "$PANE_ID" @agent_name "${WINDOW_NAME}"
tmux set-option -p -t "$PANE_ID" @agent_task "${TASK_ID}"
tmux set-option -p -t "$PANE_ID" @agent_status "●"
# Keep even-horizontal so all panes stay equal width.
tmux select-layout -t "${SESSION}:${AGENTS_WINDOW}" even-horizontal
# Wait for the cd to complete before sending the goose command.
# Write the prompt to a temp file so tmux send-keys never has to
# encode multi-byte Unicode — avoids "invalid UTF-8" goose errors.
PROMPT_FILE="/tmp/goose-prompt-${TASK_ID}.txt"
printf '%s' "$PROMPT" > "$PROMPT_FILE"
sleep 0.5
tmux send-keys -t "$PANE_ID" "goose run --text \"\$(cat $(printf '%q' "$PROMPT_FILE"))\"" Enter

echo "Spawned agent '${WINDOW_NAME}' in pane ${PANE_ID} (window '${AGENTS_WINDOW}', session '${DRIVE_SESSION}') for task ${TASK_ID}"
[[ -n "$BRANCH_NAME" ]] && echo "  Worktree branch: $BRANCH_NAME → $AGENT_DIR"
echo "  Switch to agents: tmux switch-client -t '${DRIVE_SESSION}'"
