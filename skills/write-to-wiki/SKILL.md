# Skill: write-to-wiki

Write OKF-formatted markdown documents to a date-organized wiki. Each document
gets YAML frontmatter (`type`, `title`, `description`, `resource`, `tags`,
`timestamp`) and is filed under `$WIKI_ROOT/<yyyy-mm-dd>/<slug>.md`. The daily
folder and a running `index.md` are created automatically.

Follows the [Open Knowledge Format (OKF) v0.1](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing)
spec: markdown + YAML frontmatter, directory-organized, human and agent readable.

---

## Automatic session logging via OpenCode plugin

An OpenCode plugin at `~/.config/opencode/plugins/wiki-hook.js` automatically
writes a session document to the wiki when each session closes.

**Hooks used:**
- `session.idle` — tracks turn count and captures session title as it becomes available
- `session.deleted` — writes the final OKF document when the session closes

**To disable for a specific session:**
```bash
WIKI_HOOK_DISABLED=1 opencode
```

**Goose:** No native hook system. Call `write.sh` manually at the end of a
session, or wrap `goose` in a shell function:
```bash
goose-wiki() {
  goose "$@"
  bash ~/.opencode/skills/write-to-wiki/scripts/write.sh \
    --title "Goose: $(date '+%H:%M')" \
    --type session \
    --tags "goose"
}
```

---

## Quick start

```bash
SKILL=~/.opencode/skills/write-to-wiki

# Simple session note
bash "$SKILL/scripts/write.sh" \
  --title "Smith QA Audit" \
  --type session \
  --tags "smith,qa,dev" \
  --description "Full QA sweep of smith dev instance" \
  "Audited /admin, /settings, /skills, /studio pages. Filed 12 issues."

# From stdin (multi-line body)
cat << 'EOF' | bash "$SKILL/scripts/write.sh" \
  --title "Loop Submission Investigation" \
  --type investigation \
  --tags "smith,infra,loops" \
  --resource "https://github.com/Deloitte-US-Ascend/ascend-arch-smith-infra/issues/67"
## Root cause
SMITH_ETCD_TEAM_ID not injected into replica pods.
## Fix
Added EtcdTeamID to JobRequest in smith-core.
EOF

# Dry run — preview without writing
bash "$SKILL/scripts/write.sh" --title "Test" --dry-run "body text"
```

---

## write.sh

```
write.sh [OPTIONS] [BODY]

Required:
  -t, --title        <text>      Document title → also used as filename slug

Optional:
  -y, --type         <text>      OKF type field          (default: "session")
  -d, --description  <text>      One-line summary
  --tags             <csv>       e.g. "smith,infra,qa"
  --resource         <url>       Related URL
  --date             <yyyy-mm-dd> Override date          (default: today)
  --wiki-root        <path>      Wiki root               (default: ~/wiki)
  --dry-run                      Print without writing
```

## OKF frontmatter produced

```yaml
---
type: session
title: Smith QA Audit
description: Full QA sweep of smith dev instance
tags: [smith,qa,dev]
resource: https://...
timestamp: 2026-06-16T12:00:00Z
---
```

## File layout

```
~/wiki/
  2026-06-16/
    index.md                    ← auto-created daily index
    smith-qa-audit.md           ← your document
    loop-submission-investigation.md
  2026-06-17/
    index.md
    ...
```

The `index.md` in each day folder is itself an OKF document (`type: index`)
with a link list to everything written that day.

---

## Configuration

Set `WIKI_ROOT` in your environment to change the wiki location:

```bash
export WIKI_ROOT=~/Documents/wiki
```

Or pass `--wiki-root` per invocation.

---

## Reading from the wiki

### Passive — instructions

`~/wiki/index.md` is loaded into every OpenCode session via `~/.config/opencode/opencode.json`:
```json
{ "instructions": ["~/wiki/index.md"] }
```
This gives the AI the top-level bundle structure at the start of every session.

### Active — custom tools

Two tools are available globally via `~/.config/opencode/tools/wiki.ts`:

**`wiki_search`** — full-text search across all concept documents
```
wiki_search(query: "loop submission", type: "investigation", since: "2026-06-10")
```

**`wiki_read`** — read a specific document by concept ID
```
wiki_read(id: "2026-06-16/smith-platform-session")
wiki_read(id: "2026-06-16")   # returns day index + concept list
```

The AI can call these tools directly. Just ask:
> "What did we find about loop submission last week?"
> "Read the wiki entry from June 15th"

---

## Usage by OpenCode agents

When an agent or skill wants to persist knowledge from a session:

```bash
bash ~/.opencode/skills/write-to-wiki/scripts/write.sh \
  --title "$(session_title)" \
  --type "$(type)" \
  --tags "$(tags)" \
  --description "$(one_liner)" \
  "$(body)"
```

Common `type` values:
| type | when to use |
|------|-------------|
| `session` | general work session notes |
| `investigation` | debugging / root cause analysis |
| `decision` | architectural or design decisions |
| `runbook` | operational procedures |
| `incident` | incident reports |
| `review` | PR or code review notes |
| `standup` | daily standup / briefing |
