---
name: prd-to-spec
description: Take a PRD from docs/prd/ and draft an openspec change — proposal and specs artifacts — from it. The PRD is the What and Why; the spec is the How. Use when the user wants to turn a PRD into a spec, says "spec this out", "draft the spec for", or "take the PRD to openspec".
---

A PRD is the **What and Why**. A spec is the **How**. This skill reads a PRD and produces the openspec artifacts that translate it into testable, implementable requirements.

## Step 1 — Find the PRD

If `$ARGUMENTS` names a file, read it directly.

Otherwise, list `docs/prd/` and:
- If there is exactly one file, use it.
- If there are multiple, show the list and ask the user which one to use.

Read the full PRD before continuing.

## Step 2 — Check openspec is initialized

Run `openspec doctor`. If the project is not initialized, run:

```
openspec init --tools opencode
```

## Step 3 — Create the change

Derive a kebab-case change name from the PRD filename or its title heading (e.g. `docs/prd/user-auth.md` → `user-auth`).

```
openspec new change <name>
```

## Step 4 — Draft proposal.md

Run:

```
openspec instructions --change <name> proposal
```

Read the instructions output carefully. Then write `openspec/changes/<name>/proposal.md` using the PRD as source material:

- **Why** — draw from the PRD's Problem Statement. 1-2 sentences on the problem and why it matters now.
- **What Changes** — draw from the PRD's Solution and User Stories. Bullet list of new capabilities, modifications, and removals. Mark breaking changes with **BREAKING**.
- **Capabilities** — identify the distinct capabilities this change introduces or modifies. Each becomes a `specs/<name>/spec.md` file. Use the PRD's feature scope to determine the capability list. Use kebab-case names.
- **Impact** — draw from the PRD's Out of Scope and Further Notes sections. Affected code, APIs, dependencies, systems.

Keep it concise (1-2 pages). The proposal is still the Why/What — push implementation detail to specs and design.

## Step 5 — Draft specs artifacts

Run:

```
openspec instructions --change <name> specs
```

Read the instructions output carefully. For each capability listed in the proposal, create `openspec/changes/<name>/specs/<capability>/spec.md`.

Translate the PRD's User Stories and solution intent into **testable requirements**:

- Each requirement: `### Requirement: <name>` — use SHALL/MUST for normative requirements.
- Each scenario: `#### Scenario: <name>` — exactly 4 hashtags, WHEN/THEN format.
- Every requirement MUST have at least one scenario.
- Specs describe observable behavior through public interfaces — not implementation detail.
- Draw acceptance criteria directly from the PRD's User Stories: each "As a..., I want..., so that..." maps to one or more requirements and scenarios.

If the PRD has an Implementation Decisions section, note it but do not copy it wholesale into specs — extract only the behavioral contracts (what the system SHALL do), leaving the technical choices for `design.md`.

## Step 6 — Draft design.md

Run:

```
openspec instructions --change <name> design
```

Write `openspec/changes/<name>/design.md` — the How. This is the first place implementation detail belongs. Include:

- **Context** — current state, constraints, what the specs are asking for
- **Goals / Non-Goals** — what this design achieves and explicitly excludes
- **Decisions** — key technical choices with rationale (why X over Y, alternatives considered)
- **Risks / Trade-offs** — known limitations, mitigations
- **Migration Plan** — deploy steps and rollback strategy if applicable
- **Open Questions** — unresolved decisions to surface before coding begins

Skip `design.md` only if the change is trivially local to a single module with no architectural decisions.

## Step 7 — Draft tasks.md as tracer bullet vertical slices

Run:

```
openspec instructions --change <name> tasks
```

Write `openspec/changes/<name>/tasks.md`. **Do not produce a flat implementation checklist.** Structure the tasks as ordered tracer bullet vertical slices:

- Each numbered group is one **vertical slice** — a thin path through the full stack that produces a working (if minimal) increment of the system.
- Order slices from the thinnest possible working system outward. The first slice should produce *something* end-to-end: the simplest path that touches every layer.
- Each slice should be completable in one TDD red-green-refactor cycle.
- Tasks within a slice run top-to-bottom: write the failing test first, then the implementation.

Example structure:
```
## 1. Thinnest working path — <one-line description of the slice>

- [ ] 1.1 Write failing test: <behavior under test>
- [ ] 1.2 Implement <minimal thing> to make it pass
- [ ] 1.3 Refactor

## 2. <Next thinnest capability>

- [ ] 2.1 Write failing test: <behavior under test>
- [ ] 2.2 Implement
- [ ] 2.3 Refactor
```

Each slice should map to one or more spec scenarios. Reference the scenario name in the task description where possible.

## Step 8 — Validate and report

Run:

```
openspec status --change <name>
openspec validate --change <name>
```

Report to the user:
- Change name and location (`openspec/changes/<name>/`)
- Artifacts drafted: proposal.md, specs, design.md, tasks.md
- Number of tracer bullet slices and which spec scenarios they cover
- Any validation warnings
- Next step: review the tasks, then begin implementation slice-by-slice using the **tdd** skill
