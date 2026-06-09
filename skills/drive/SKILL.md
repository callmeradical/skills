---
name: drive
description: >
  Autonomous multi-agent development orchestrator. Breaks a project goal into
  parallel workstreams, spawns independent opencode agents in new tmux windows,
  each in its own git worktree, and drives the work to completion using TDD and
  td-task-management. Generates a recap summary to the Desktop when done.
  Use when the user says "drive to completion", "drive this", "run this
  autonomously", "spin up agents", "parallelize this", "take it from here",
  or any variation of wanting the AI to autonomously execute a development goal
  end-to-end. Always requires tmux, td, and git.
---

# drive

Orchestrate autonomous development: label the session, initialise the td sidecar,
create git worktrees, spawn parallel opencode agents in tmux windows (TDD + tracer
bullets), monitor to completion, then generate a Desktop recap.

---

## Dependencies

This skill depends on three other skills and two system tools. **Always run
`check_deps.sh` before starting a drive session.** It will tell you exactly what
is missing and how to fetch it.

```bash
bash ~/.opencode/skills/drive/scripts/check_deps.sh
```

### Skill dependencies

| Skill | Provenance | Install |
|---|---|---|
| **td-task-management** | `marcus/td/td-task-management` @ `b9717f9` | `augy install marcus/td/td-task-management` |
| **tdd** | `mattpocock/skills/skills/engineering/tdd` by [Matt Pocock](https://github.com/mattpocock) | `augy install mattpocock/skills/skills/engineering/tdd` *(run in a real terminal — augy needs a TTY)* |
| **tmux-label** | Sibling skill (created alongside `drive`) | Ensure both were installed together; expected at `~/.opencode/skills/tmux-label` |

### System dependencies

| Tool | Purpose | Install |
|---|---|---|
| `tmux` | Window management for parallel agents | `brew install tmux` |
| `git` | Worktree isolation per agent | `brew install git` |
| `td` CLI | Task tracking sidecar | See [marcus/td](https://github.com/marcus/td) |
| `augy` | Skill package manager (for fetching deps) | See [anomalyco/augy](https://github.com/anomalyco/augy) |

### Fetching missing skills

If `check_deps.sh` reports missing skills:

```bash
# td-task-management (augy-tracked)
augy install marcus/td/td-task-management

# tdd (Matt Pocock)
augy install mattpocock/skills/skills/engineering/tdd
# Note: run this in a real terminal — augy requires a TTY

# tmux-label (must be installed alongside drive)
# Re-install both skills together from their source.
```

---

## Orchestrator Workflow

### Step 0 — Check dependencies

```bash
bash ~/.opencode/skills/drive/scripts/check_deps.sh
```

Do not proceed until all checks pass.

### Step 1 — Label the session

```bash
bash ~/.opencode/skills/tmux-label/scripts/label_session.sh
```

### Step 2 — Initialise td sidecar

```bash
td usage --new-session
```

This auto-rotates sessions and surfaces existing tasks, pending reviews, and
prior decisions. If this is the first run in the repo, td initialises `.todos/`
automatically. Read the output before proceeding.

### Step 3 — Choose a decomposition strategy

Pick the strategy that fits the work. Both use TDD once the slices are defined.

**Strategy A — Vertical slices (default)**

One agent per independent feature. Each agent owns the full stack for that feature.
Best when features are independently deliverable with no shared mutable state.

**Strategy B — Tracer bullet first, then horizontal**

Used when building a new system or wiring a deep stack where connectivity is unknown.
Fire a single tracer bullet agent first — a thin end-to-end slice that proves the
path works — then spawn horizontal agents per architectural layer.

```
1. Tracer agent: thinnest possible path from input to output
   (e.g. request → handler → DB → response), one test, minimal code.
2. Once tracer is GREEN, spawn one agent per layer:
   Agent A: API / routing layer
   Agent B: Business logic / service layer
   Agent C: Data / persistence layer
   Agent D: Frontend / consumer layer
```

Each horizontal agent still uses vertical TDD slices *within* their layer.

### Step 4 — Create td tasks

```bash
td create "Implement X" --type feature --priority P1
td create "Add Y layer" --type feature --priority P1
td log --decision "Split into N tasks because ..."
```

Rules: independent execution, clear testable completion condition, 2–5 tasks,
verb-phrase names ("Implement auth middleware").

### Step 5 — Create worktrees and spawn agents

Each agent gets its own git worktree (isolated branch, no conflicts).

```bash
SKILL=~/.opencode/skills/drive

# Vertical example
bash "$SKILL/scripts/spawn_agent.sh" \
  --window "auth"   --task-id "td-a1b2" \
  --description "Implement JWT auth middleware with refresh token rotation" \
  --worktree --dir "$PWD"

bash "$SKILL/scripts/spawn_agent.sh" \
  --window "retry"  --task-id "td-c3d4" \
  --description "Add exponential backoff retry logic to the fetch client" \
  --worktree --dir "$PWD"

# Tracer bullet first (Strategy B)
bash "$SKILL/scripts/spawn_agent.sh" \
  --window "tracer" --task-id "td-e5f6" \
  --description "Fire tracer bullet: thin end-to-end path through the full stack" \
  --worktree --dir "$PWD"
# Wait for tracer GREEN before spawning horizontal agents.
```

Use `--dry-run` to preview a prompt before launching.

Each spawned agent is bootstrapped to:
1. `td usage --new-session` → orient and claim task
2. Choose vertical or tracer-bullet strategy based on the task
3. Implement via TDD — one test → minimal code → repeat; refactor only after GREEN
4. Log decisions and file links throughout
5. `td handoff` + `td review` when complete

### Step 6 — Monitor

```bash
td monitor          # live dashboard (Ctrl-C to exit)
td usage -q         # compact snapshot on demand
```

Review submitted tasks from a window that did not implement them (td session
isolation enforces implementer ≠ reviewer):

```bash
td reviewable
td approve <id>      # or: td reject <id> --reason "..."
```

### Step 7 — Merge worktrees

After all tasks are approved:

```bash
git merge drive/td-a1b2-auth
git merge drive/td-c3d4-retry
git worktree remove ../myproject-wt-auth
git worktree remove ../myproject-wt-retry
```

Run the full test suite after merging to confirm no conflicts.

### Step 8 — Generate recap

```bash
bash ~/.opencode/skills/drive/scripts/recap.sh
```

Writes `~/Desktop/<project>-recap-<date>.md` (opened automatically on macOS).
Includes all task statuses, decisions, handoffs, file changes, and git worktree state.

Options: `--dry-run` (stdout only), `--output <path>`, `--project <name>`.

---

## Key constraints

| Constraint | Reason |
|---|---|
| Must be inside tmux | Windows required for parallel agents |
| `td` must be installed | Shared state and session isolation |
| git repo required for `--worktree` | Isolated branches per agent |
| Reviewer ≠ implementer | td session isolation enforces this |

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/check_deps.sh` | Verify all dependencies; print augy install instructions if missing |
| `scripts/spawn_agent.sh` | Create tmux window + git worktree, launch opencode agent |
| `scripts/recap.sh` | Generate session recap markdown to Desktop |
| `~/.opencode/skills/tmux-label/scripts/label_session.sh` | Label tmux session with project name |
