---
name: adr-to-guardrail
description: Read an ADR and append one or more GUARDRAIL signs to GUARDRAILS.md. Each sign encodes the ADR's decision as a concrete trigger/instruction/reason triple that enforces the decision automatically. Use when the user says "add this ADR to guardrails", "guardrail this decision", "encode this ADR", or wants to harden an architectural decision into a persistent constraint.
---

An ADR records a decision. A GUARDRAIL sign enforces it — automatically, every session. This skill translates the why/what of an ADR into the when/do/why of a sign.

## Step 1 — Find the ADR

If `$ARGUMENTS` names a file, read it directly.

Otherwise, search for ADRs in common locations:
- `docs/adr/`, `docs/adrs/`, `docs/decisions/`
- Files matching `docs/adr-*.md`, `docs/*.adr.md`
- Files matching `**/adr-*.md`

If multiple are found and none specified, list them and ask the user which to use.

Read the full ADR before continuing.

## Step 2 — Extract signs from the ADR

A single ADR often yields multiple signs — one per distinct enforcement point. Read the ADR and identify every decision that can be stated as a **trigger + instruction + reason** triple:

- **Trigger** — a concrete, scannable description of what the agent is about to do. Written as a gerund phrase: "Adding a new state persistence mechanism", "Deploying to any environment", "Adding credentials or secrets". Should be specific enough that the agent recognises it applies.
- **Instruction** — what the agent MUST or MUST NOT do. Use ALWAYS/NEVER language. Be prescriptive: name the specific tool, pattern, or path to follow or avoid. If the decision has multiple ordered steps, list them numbered.
- **Reason** — one or two sentences explaining why this constraint exists. Focus on the failure mode it prevents.
- **Provenance** — the ADR identifier and title (e.g. `ADR-0001 (etcd State Machine)`).

One ADR → one sign is fine. One ADR → three signs is also fine if there are three distinct enforcement points. Do not pad. Do not merge distinct constraints into one sign.

## Step 3 — Determine sign numbers

Read `GUARDRAILS.md` if it exists and find the current highest sign number. New signs are numbered sequentially from there. If `GUARDRAILS.md` does not exist, start from SIGN #1.

## Step 4 — Write the signs

Each sign follows this exact format:

```
## SIGN #N
**Trigger:** <gerund phrase — what the agent is about to do>
**Instruction:** <ALWAYS/NEVER ... specific prescriptive rule>
**Reason:** <one or two sentences on the failure mode this prevents>
**Provenance:** <ADR identifier and title>
```

Blank line between fields is not needed. One blank line between signs.

## Step 5 — Update GUARDRAILS.md

If `GUARDRAILS.md` does not exist, create it with this header before the signs:

```markdown
# GUARDRAILS.md
# Persistent safety constraints for <project name>

## Meta
Created: <today's date>
Total Signs: <count>

---
```

If it exists:
- Append the new signs after the last existing sign.
- Update `Total Signs:` in the Meta section to reflect the new total.

Do not reformat, reorder, or touch existing signs.

## Step 6 — Report

Tell the user:
- How many signs were added and their numbers
- Which ADR they came from
- Any decisions in the ADR that were deliberately not encoded (and why — e.g. too implementation-specific to be a useful trigger)
