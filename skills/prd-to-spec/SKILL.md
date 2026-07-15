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

## Step 6 — Validate and report

Run:

```
openspec status --change <name>
openspec validate --change <name>
```

Report to the user:
- Change name and location (`openspec/changes/<name>/`)
- Artifacts drafted (proposal.md, which spec files)
- Any validation warnings
- Next steps: review and refine specs, then continue to `design` and `tasks` artifacts via `openspec instructions --change <name> design`
