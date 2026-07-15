---
name: wiki-ingest
description: >
  Synthesize the current session into the wiki. Updates entity pages, decision
  pages, session digest, and index. Use when the user says "update the wiki",
  "ingest this session", "write this to the wiki", or similar.
triggers:
  - update the wiki
  - ingest this session
  - write to the wiki
  - wiki update
  - save to wiki
---

# wiki-ingest

Synthesize meaningful content from the current session into `~/wiki/`.

**Do not transcribe — synthesize.** Extract what matters: decisions made,
problems solved, patterns discovered, entity state changes. Discard chatter.

---

## Process

### Step 1 — Read the current wiki state

```bash
cat ~/wiki/index.md
```

Read any pages that are likely to be touched by this session.

### Step 2 — Identify what changed

From the current conversation, extract:

| Category | Questions to ask |
|---|---|
| **Entities** | Did the state of any system change? New bugs found? Issues resolved? |
| **Decisions** | Was a significant choice made? An approach accepted or rejected? |
| **Incidents** | Was an outage or bug investigated? Root cause found? |
| **Features** | Was a feature started, completed, or blocked? |
| **Patterns** | Was a reusable approach discovered or an anti-pattern confirmed? |
| **Sessions** | What did this day's work accomplish overall? |

### Step 3 — Update in place, don't create noise

**Existing page** — update it. Don't create a second page for the same entity.
Use the file path from `index.md` to locate it, then `Read` → `Edit`.

**New concept** — create a new page with OKF frontmatter:
```yaml
---
type: <entity|decision|incident|feature|pattern|session>
title: <title>
description: <one-line summary>
tags: [<relevant>, <tags>]
updated: <YYYY-MM-DD>
---
```

**Session digest** — always update `~/wiki/sessions/YYYY-MM-DD.md`.
Create it if today's doesn't exist yet.

### Step 4 — Update index.md

If any new pages were created, add them to `~/wiki/index.md` under the right
section. Use format: `* [Title](path/to/page.md) — description · status`

### Step 5 — Append to log.md

```
## [YYYY-MM-DD] ingest | <one-line summary of what was ingested>
```

---

## OKF conformance rules

- Every concept file requires a `type` field in YAML frontmatter
- `index.md` files have **no frontmatter** (exception: bundle root `index.md` has `okf_version`)
- Cross-links use bundle-relative `/prefix` paths: `/entities/smith.md` not `../entities/smith.md`
- External links (into repos, GitHub, etc.) use normal relative or absolute paths

---

## What NOT to do

- Don't create a page per session turn — one digest per day maximum
- Don't duplicate content already in the codebase ADRs/docs — link to them instead
- Don't write "the user asked X and I answered Y" — that's a transcript, not a wiki
- Don't update the wiki for trivial sessions (test runs, quick questions)
