---
name: tmux-label
description: >
  Label the current tmux session and/or window with the name of the AI project
  being worked on. Auto-detects the project name from package.json, pyproject.toml,
  Cargo.toml, go.mod, or the git repo root directory name. Use when the user asks
  to "label the session", "rename the tmux session", "set the session name", or
  "name the window for this project". Trigger phrases include "label session",
  "rename tmux", "name this session", "set tmux label", or any request to identify
  the current project in tmux.
---

# tmux-label

Label the current tmux session and window with the name of the AI project in the working directory.

## Workflow

1. Run `scripts/label_session.sh` from the project directory.
2. The script auto-detects the project name (priority order below) and renames the tmux session and window.
3. Confirm the rename with the user or adjust with `--name` if wrong.

## Project Name Detection (priority order)

| Source | Field |
|--------|-------|
| `package.json` | `name` |
| `pyproject.toml` | `[project] name` or `[tool.poetry] name` |
| `Cargo.toml` | `[package] name` |
| `go.mod` | module path last segment |
| git repo root | directory name |
| current directory | directory name |

## Script Usage

```bash
# Rename both session and window (default)
bash scripts/label_session.sh

# Rename session only
bash scripts/label_session.sh --session

# Rename window only
bash scripts/label_session.sh --window

# Dry-run: detect name without renaming
bash scripts/label_session.sh --dry-run

# Override the detected name
bash scripts/label_session.sh --name my-project
```

Script location: `scripts/label_session.sh` (relative to this skill folder).

Run from the project's working directory so detection picks up the right files. If not inside tmux, the script exits with a clear message.
