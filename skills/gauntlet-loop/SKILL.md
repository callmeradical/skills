---
name: gauntlet-loop
description: >
  Two-agent build/review loop. A Builder subagent implements a task via TDD;
  a Critic subagent, spawned fresh with no shared history, evaluates the
  Builder's output against a stated quality bar and returns PASS or HOLD with
  specific, actionable feedback. On HOLD, the feedback becomes the Builder's
  next task and the loop repeats. On PASS, or when a max-iteration ceiling is
  hit, the loop stops and reports. Use when the user says "gauntlet loop",
  "builder and critic", "build then review in a loop", or wants an
  adversarial-review pattern where the reviewer can't rationalize the
  builder's own choices because it never saw them being made.
---

# Gauntlet Loop

A minimal, two-role quality loop: **Builder** implements, **Critic** judges — with
zero shared context between them. This is the core insight the loop depends on:
a single agent that both writes and reviews its own code tends to rationalize its
own choices rather than interrogate them. Splitting the roles into separate
subagent delegations, with the Critic starting from a blank slate, avoids that.

## Before starting

Confirm with the user, if not already stated:

1. **The task** — what is the Builder actually implementing? (a spec, a PRD, a
   plain description — whatever's available.)
2. **The quality bar** — what does the Critic check for? Be specific. Vague bars
   ("good code") produce vague verdicts. Prefer concrete, checkable criteria:
   tests pass, coverage of stated scenarios, conformance to existing codebase
   patterns, no regressions in touched files.
3. **Max iterations** — a ceiling to stop an infinite loop if the Builder and
   Critic can't converge. Default to 5 if the user doesn't specify. When the
   ceiling is hit without a PASS, stop and hand the situation to the user rather
   than looping forever.

If the task implies a change to *what* the system does or *why* (not just *how*
it's built), stop and suggest running **write-a-prd** then **prd-to-spec** first,
rather than looping on an unstated or drifting target. The loop builds against a
fixed target — it does not renegotiate the target mid-loop.

## The loop

Repeat until PASS or the iteration ceiling is reached:

### 1. Delegate to the Builder

```
delegate(instructions: "<the task, or the Critic's HOLD feedback from the
previous iteration>. Implement via TDD: write the failing test first, then
the minimal implementation, then refactor. Use the tdd skill.")
```

The Builder subagent should have access to whatever extensions the task needs
(developer, etc.) but does **not** need — and should not be given — the Critic's
role or evaluation criteria. It builds; it doesn't grade its own homework.

### 2. Gather full file content, not a diff

Before invoking the Critic, read the **complete current content** of every file
the Builder touched — not `git diff` output. A diff can't tell the Critic that a
sibling file (a second store implementation, a matching test file, a downstream
caller) was never updated; you have to see the whole file, or the whole
directory, to notice an absence.

### 3. Delegate to the Critic — fresh context, no Builder history

```
delegate(instructions: "Evaluate this implementation against the quality bar
below. You have not seen how or why any of this was written — evaluate only
what exists.

Quality bar: <the stated bar>

Full content of touched files:
<paste full files, not diffs>

<if available: relevant spec/PRD/openspec artifacts>

Check, in this order, stopping at the first failure:
1. Conformance to existing codebase patterns — independent of any spec. Would
   this look out of place to someone who knows this codebase but has never
   seen this task?
2. Fidelity to the stated design/spec, if one exists.
3. Coverage of the stated task/quality bar.

Respond with exactly one verdict — PASS or HOLD — followed by specific,
actionable feedback if HOLD. Vague feedback like 'needs improvement' is not
acceptable; name the file, the line or function, and what's wrong.")
```

Do **not** give the Critic subagent the Builder's conversation, reasoning, or
commit history. It should only ever see: the quality bar, the current file
contents, and (if relevant) the design artifacts. This is what makes it a
critic and not an echo of the Builder.

### 4. Branch on the verdict

- **PASS** → stop. Report the outcome, the number of iterations it took, and a
  summary of what was built.
- **HOLD** → the Critic's feedback becomes the Builder's instructions for the
  next iteration. Increment the iteration count and go back to step 1.
- **Iteration ceiling reached without PASS** → stop. Report the current state,
  the Critic's most recent HOLD feedback, and recommend the user review
  directly rather than continuing to loop.

## Notes on scaling this up

This skill deliberately covers only the two-role core. If you need more (a
Red-Teamer for adversarial probing, a Judge on a stronger model for final
sign-off, a shared task board so multiple loops can run without duplicating
work, real process isolation via containers or worktrees) — that's a
composition of *more* subagents and *more* delegation calls layered on this
same pattern, not a different mechanism. Build the two-role loop first, confirm
it converges, then add roles one at a time.
