---
name: dev-workflow
description: Orchestrate the full feature development workflow — PRD → spec → ADRs → guardrails — pausing for review at each gate. Use when the user says "walk me through the workflow", "start a new feature", "run the dev workflow", or wants to drive a feature from idea to guardrails end-to-end.
---

This skill orchestrates the full feature workflow. It does not do the work itself — it loads each skill in sequence and pauses at review gates before continuing. You can enter at any step.

## Determine entry point

Run `lc workflow` if available, or check these artifacts manually to find where the feature stands:

| Step | Artifact | Location |
|------|----------|----------|
| 1. PRD | `<feature>.md` | `docs/prd/` |
| 2. Spec | `openspec/changes/<feature>/` | proposal + specs + design + tasks |
| 3. ADRs | `adr-NNNN-*.md` | `docs/adr/` |
| 4. Guardrails | `GUARDRAILS.md` | project root |

If `$ARGUMENTS` names a feature or step, start there. Otherwise start at the first incomplete step.

---

## Step 1 — PRD

**Skip if:** `docs/prd/<feature>.md` already exists and the user confirms it is complete.

Load the **write-a-prd** skill and follow it fully. The PRD must capture the What and Why before anything else is written. No implementation detail belongs here.

### Review gate 1

Present the completed PRD to the user. Ask:
- Does this accurately capture the problem and goals?
- Is anything missing or out of scope?

**Do not proceed to Step 2 until the user explicitly approves the PRD.**

---

## Step 2 — Spec

**Skip if:** `openspec/changes/<feature>/tasks.md` already exists and the user confirms it is complete.

Load the **prd-to-spec** skill and follow it fully. This produces all four openspec artifacts: proposal, specs, design, tasks (as tracer bullet slices).

### Review gate 2

Present a summary of the spec artifacts:
- Key capabilities identified in `proposal.md`
- Number of requirements and scenarios in `specs/`
- Key decisions in `design.md`
- Number of tracer bullet slices in `tasks.md`

Ask:
- Do the specs accurately reflect the PRD?
- Are the design decisions sound?
- Are the tracer bullet slices the right granularity?

**Do not proceed to Step 3 until the user explicitly approves the spec.**

---

## Step 3 — ADRs

**Skip if:** `docs/adr/` contains ADR files referencing this change and the user confirms they are complete.

Load the **design-to-adr** skill and follow it fully. Extract qualifying architectural decisions from `design.md` into formal ADR files.

### Review gate 3

Present the promoted ADRs and the decisions that were not promoted (with reasons). Ask:
- Are the right decisions being elevated to ADRs?
- Is anything missing that future agents need to know permanently?
- Should any non-promoted decision be reconsidered?

**Do not proceed to Step 4 until the user explicitly approves the ADRs.**

---

## Step 4 — Guardrails

**Skip if:** `GUARDRAILS.md` already contains signs with provenance referencing this change's ADRs.

For each ADR produced in Step 3, load the **adr-to-guardrail** skill and encode it into `GUARDRAILS.md`.

### Review gate 4

Present the new GUARDRAILS signs. Ask:
- Do the triggers accurately capture when the constraint applies?
- Are the ALWAYS/NEVER instructions precise enough?
- Is any sign too broad or too narrow?

---

## Completion

When all four steps are approved, report:

```
Feature: <name>
PRD:        docs/prd/<feature>.md
Spec:       openspec/changes/<feature>/  (proposal + specs + design + tasks)
ADRs:       docs/adr/adr-NNNN-*.md  (<N> decisions promoted)
Guardrails: GUARDRAILS.md  (<N> new signs, total: <total>)

Next: begin implementation with the tdd skill, working through
tasks.md slice by slice.
```
