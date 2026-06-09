#!/usr/bin/env bash
# label_session.sh - Detect the current AI project name and rename the tmux session/window.
#
# Usage: label_session.sh [--session] [--window] [--dry-run] [--name <override>]
#   --session    Rename the tmux session (default: both)
#   --window     Rename the tmux window (default: both)
#   --dry-run    Print the detected name without renaming
#   --name <n>   Override the auto-detected name

set -euo pipefail

# ---- Argument parsing -------------------------------------------------------
RENAME_SESSION=true
RENAME_WINDOW=true
DRY_RUN=false
NAME_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session)   RENAME_WINDOW=false; shift ;;
    --window)    RENAME_SESSION=false; shift ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --name)      NAME_OVERRIDE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ---- Project name detection -------------------------------------------------
detect_project_name() {
  local dir="${PWD}"

  # 1. Explicit override
  if [[ -n "$NAME_OVERRIDE" ]]; then
    echo "$NAME_OVERRIDE"
    return
  fi

  # 2. Walk up to git root
  local git_root
  git_root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)
  local search_dir="${git_root:-$dir}"

  # 3. package.json "name"
  if [[ -f "$search_dir/package.json" ]]; then
    local pkg_name
    pkg_name=$(python3 -c "import json,sys; d=json.load(open('$search_dir/package.json')); print(d.get('name',''))" 2>/dev/null || true)
    if [[ -n "$pkg_name" && "$pkg_name" != "null" ]]; then
      echo "$pkg_name"; return
    fi
  fi

  # 4. pyproject.toml [project] name
  if [[ -f "$search_dir/pyproject.toml" ]]; then
    local py_name
    py_name=$(python3 -c "
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib
with open('$search_dir/pyproject.toml','rb') as f:
    d = tomllib.load(f)
print(d.get('project',{}).get('name','') or d.get('tool',{}).get('poetry',{}).get('name',''))
" 2>/dev/null || true)
    if [[ -n "$py_name" && "$py_name" != "null" ]]; then
      echo "$py_name"; return
    fi
  fi

  # 5. Cargo.toml [package] name
  if [[ -f "$search_dir/Cargo.toml" ]]; then
    local cargo_name
    cargo_name=$(grep -m1 '^name\s*=' "$search_dir/Cargo.toml" | sed 's/.*=\s*"\(.*\)"/\1/' 2>/dev/null || true)
    if [[ -n "$cargo_name" ]]; then
      echo "$cargo_name"; return
    fi
  fi

  # 6. go.mod module path last segment
  if [[ -f "$search_dir/go.mod" ]]; then
    local go_name
    go_name=$(head -1 "$search_dir/go.mod" | awk '{print $2}' | sed 's|.*/||' 2>/dev/null || true)
    if [[ -n "$go_name" ]]; then
      echo "$go_name"; return
    fi
  fi

  # 7. Git repo root directory name
  if [[ -n "$git_root" ]]; then
    basename "$git_root"; return
  fi

  # 8. Current directory name
  basename "$dir"
}

PROJECT_NAME=$(detect_project_name)

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Could not detect a project name." >&2
  exit 1
fi

echo "Detected project name: $PROJECT_NAME"

if $DRY_RUN; then
  echo "(dry-run: no tmux changes made)"
  exit 0
fi

# ---- Tmux check -------------------------------------------------------------
if [[ -z "${TMUX:-}" ]]; then
  echo "Not inside a tmux session. Nothing to rename." >&2
  exit 1
fi

# ---- Rename -----------------------------------------------------------------
if $RENAME_SESSION; then
  tmux rename-session "$PROJECT_NAME"
  echo "Session renamed to: $PROJECT_NAME"
fi

if $RENAME_WINDOW; then
  tmux rename-window "$PROJECT_NAME"
  echo "Window renamed to: $PROJECT_NAME"
fi
