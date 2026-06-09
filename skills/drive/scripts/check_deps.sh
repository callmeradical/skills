#!/usr/bin/env bash
# check_deps.sh - Verify all drive skill dependencies are present.
#
# Exits 0 if everything is available.
# Exits 1 and prints install instructions for anything missing.
#
# Usage: check_deps.sh [--quiet]

set -euo pipefail

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

MISSING=()
WARNINGS=()

ok()   { $QUIET || printf "  \033[32m✓\033[0m %s\n" "$1"; }
fail() { printf "  \033[31m✗\033[0m %s\n" "$1"; MISSING+=("$1"); }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; WARNINGS+=("$1"); }

# ---- Helper: find a skill across known agent dirs ---------------------------
find_skill() {
  local name="$1"
  local dirs=(
    "$HOME/.opencode/skills"
    "$HOME/.agents/skills"
    "$HOME/.agents/skills/skills"
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
  )
  for d in "${dirs[@]}"; do
    [[ -f "$d/$name/SKILL.md" ]] && echo "$d/$name" && return 0
  done
  return 1
}

$QUIET || echo ""
$QUIET || echo "drive — dependency check"
$QUIET || echo "════════════════════════"

# ---- System tools -----------------------------------------------------------
$QUIET || echo ""
$QUIET || echo "System tools:"

command -v tmux  &>/dev/null && ok "tmux"  || fail "tmux (brew install tmux)"
command -v git   &>/dev/null && ok "git"   || fail "git  (brew install git)"
command -v td    &>/dev/null && ok "td (CLI)" || fail "td CLI (see: https://github.com/marcus/td)"
command -v augy  &>/dev/null && ok "augy"  || warn "augy not found — install instructions below may not apply (https://github.com/anomalyco/augy)"

# ---- Skills -----------------------------------------------------------------
$QUIET || echo ""
$QUIET || echo "Skills:"

# td-task-management
# augy provenance: marcus/td/td-task-management
# sha at time of authoring: b9717f9
if find_skill "td-task-management" &>/dev/null; then
  ok "td-task-management  ($(find_skill td-task-management))"
else
  fail "td-task-management"
  MISSING+=("  → augy install marcus/td/td-task-management")
fi

# tdd
# author:     Matt Pocock
# provenance: mattpocock/skills/skills/engineering/tdd
# note:       augy install requires a real TTY — run in your terminal, not from an agent
if find_skill "tdd" &>/dev/null; then
  ok "tdd  ($(find_skill tdd))"
else
  fail "tdd"
  MISSING+=("  → augy install mattpocock/skills/skills/engineering/tdd")
  MISSING+=("    (run this in your terminal — augy needs a TTY)")
fi

# tmux-label (sibling skill, part of the same multipass project)
# provenance: local, no upstream — created alongside drive
if find_skill "tmux-label" &>/dev/null; then
  ok "tmux-label  ($(find_skill tmux-label))"
else
  fail "tmux-label"
  MISSING+=("  → sibling of the drive skill; ensure both were installed together")
  MISSING+=("    expected at: ~/.opencode/skills/tmux-label")
fi

# ---- Summary ----------------------------------------------------------------
echo ""

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo "All dependencies satisfied. Ready to drive."
  exit 0
fi

echo "Missing dependencies — fetch these before running drive:"
echo ""
for m in "${MISSING[@]}"; do
  echo "  $m"
done
echo ""

if command -v augy &>/dev/null; then
  echo "Quick install for augy-tracked skills:"
  echo "  augy install marcus/td/td-task-management"
  echo ""
fi

echo "Then re-run: bash ~/.opencode/skills/drive/scripts/check_deps.sh"
echo ""
exit 1
