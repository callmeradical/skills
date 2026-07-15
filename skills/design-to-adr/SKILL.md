---
name: design-to-adr
description: Read an openspec design.md and promote significant architectural decisions into formal ADR files in docs/adr/. Use when the user says "extract ADRs from the design", "promote decisions to ADRs", "write ADRs for this change", or after completing a design.md in openspec.
---

A `design.md` is a working document — decisions made in context, for this change. An ADR is a permanent record — a decision that future agents and engineers must know about regardless of whether they ever read the spec. This skill separates the two.

## Step 1 — Find the design.md

If `$ARGUMENTS` is a change name, read `openspec/changes/<name>/design.md`.

If `$ARGUMENTS` is a file path, read it directly.

Otherwise, list `openspec/changes/` and:
- If one change has a `design.md`, use it.
- If multiple do, show the list and ask the user which to use.

Also read the corresponding `proposal.md` and `specs/` for context on what the change is trying to achieve.

## Step 2 — Score each decision against the ADR bar

Read the Decisions section of `design.md`. For each decision, ask:

1. **Cross-cutting?** Does it affect more than one module, service, or layer?
2. **Durable?** Will this constraint still matter in 6 months, after the code is written?
3. **Non-obvious from code?** Would a future agent reading the codebase be able to infer this from the implementation alone?
4. **Has a rejected alternative?** Was something else considered and ruled out? That rationale is the most valuable thing to preserve.

If the answer to two or more of these is yes → promote to ADR.
If the decision is local, temporary, or self-evident from the code → leave it in design.md, note it was not promoted.

## Step 3 — Determine ADR numbers

Check `docs/adr/` for existing ADR files. Find the highest number in use (e.g. `adr-0012-*.md` → 12). New ADRs are numbered sequentially from there. If `docs/adr/` does not exist or is empty, start from `ADR-0001`.

Create `docs/adr/` if it does not exist.

## Step 4 — Write the ADR files

One file per decision. Filename: `adr-<NNNN>-<kebab-case-title>.md`.

Use this format exactly:

```markdown
# ADR-<NNNN>: <Title>

**Status:** Proposed
**Date:** <today>
**Change:** <openspec change name>

## Context

<2-4 sentences. What is the situation that forced this decision? What constraints or forces are in play? Reference the spec change if helpful.>

## Decision

<1-3 sentences. The decision itself, stated plainly. Start with "We will..." or "Use...">

## Rationale

<Why this option over the alternatives. Name the alternatives that were considered and why each was rejected. This is the most important section — it's the part that design.md has but code never will.>

## Consequences

**Easier:** <what this decision makes simpler or safer>
**Harder:** <what this decision makes more difficult or constrained>
**Risks:** <known failure modes or conditions under which this decision should be revisited>
```

Do not add sections beyond these. Do not include implementation detail — that stays in design.md. The ADR is the why, not the how.

## Step 5 — Report

Tell the user:
- Which decisions were promoted to ADRs (with numbers and filenames)
- Which decisions were not promoted, and the reason for each (e.g. "local to a single function", "self-evident from the interface", "temporary scaffolding")
- Suggest running the **adr-to-guardrail** skill on any ADR that has a clear ALWAYS/NEVER enforcement point
