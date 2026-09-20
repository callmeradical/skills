---
name: gauntlet-loop
description: >
  Two-agent build/review loop. A Builder subagent implements a task via TDD;
  a Critic subagent, spawned fresh with no shared history, evaluates the
  Builder's output against a stated, concrete quality bar and returns PASS or
  HOLD with specific, actionable feedback. On HOLD, the feedback becomes the
  Builder's next task and the loop repeats. On PASS, or when a max-iteration
  ceiling is hit, the loop stops and reports. Use when the user says
  "gauntlet loop", "builder and critic", "build then review in a loop", or
  wants an adversarial-review pattern where the reviewer can't rationalize
  the builder's own choices because it never saw them being made.
---

# Gauntlet Loop

A minimal, two-role quality loop: **Builder** implements, **Critic** judges — with
zero shared context between them. This is the core insight the loop depends on:
a single agent that both writes and reviews its own code tends to rationalize its
own choices rather than interrogate them. Splitting the roles into separate
subagent delegations, with the Critic starting from a blank slate, avoids that.

This combines two lineages: an internal ADR-driven Builder/Critic/Red-Teamer/Judge
pipeline for shipping code slices, and Matt Shumer's public
["Gauntlet Loop"](https://somethingbig.ai/gauntlet-loop) method (the technique
behind the "Claude of Duty" demo). Both converge on the same core mechanism —
this skill implements that shared core, scoped to two roles.

## Before starting

Confirm with the user, if not already stated:

1. **The goal, not the implementation.** Give the Builder the destination, not
   the route. Don't prescribe architecture, file layout, or exact steps unless
   the user has already fixed those — an agent that's told exactly how to build
   something will just follow instructions rather than solve the problem, and a
   Critic checking "did it follow instructions" is a much weaker bar than
   "is this actually good."

2. **A real, concrete bar** — not "make it good" or "production-ready." Vague
   bars produce vague verdicts. Prefer, in order of strength:
   - **A reference to compare against**: a real competing product, a screenshot,
     an existing high-quality file in the same codebase, a prior piece of
     writing with the tone/clarity you want. This is what turns the Critic into
     something closer to a blind A/B tester rather than a rubric-checker.
   - **A measurable target**: test coverage of stated scenarios, a latency
     number, a security/failure-recovery check.
   - **A pattern-conformance check**: "does this look like it belongs in this
     codebase to someone who's never seen this task" — checked independent of
     any spec, since specs are often silent on cross-cutting concerns.

   If no bar is available, make finding one part of the task: ask the Builder
   (or a lead/planning pass) to propose a concrete comparison or measurement
   that plays the same role for this task that real competitor screenshots or
   a reference implementation would, and explain in one sentence why it's a
   fair bar, before the loop starts.

3. **Max iterations** — a safety ceiling, not a target. Default to 5 for
   unattended/autonomous runs so a stuck loop doesn't run forever unsupervised.
   If the user wants to actually push quality as far as it goes (the original
   "Gauntlet Loop" framing), offer the alternative: no fixed ceiling, keep
   looping until the user says stop or the Critic's feedback stops surfacing
   anything meaningful (diminishing returns is itself a valid stop condition —
   don't require a PASS to end the loop if the user's happy with "good enough
   and no longer improving").

If the task implies a change to *what* the system does or *why* (not just *how*
it's built), stop and suggest running **write-a-prd** then **prd-to-spec** first,
rather than looping on an unstated or drifting target. The loop builds against a
fixed target — it does not renegotiate the target mid-loop.

## The loop

Repeat until PASS (or the user's chosen stop condition):

### 1. Delegate to the Builder

```
delegate(instructions: "<the goal, or the Critic's HOLD feedback from the
previous iteration>. Implement via TDD: write the failing test first, then
the minimal implementation, then refactor. Use the tdd skill.")
```

The Builder subagent should have access to whatever extensions the task needs
(developer, etc.) but does **not** need — and should not be given — the Critic's
role or evaluation criteria. It builds; it doesn't grade its own homework.

### 2. Gather the actual artifact, not a description of it

Before invoking the Critic, collect the **real thing** — not a summary the
Builder wrote about its own work:

- Code: the **complete current content** of every touched file, not a `git
  diff`. A diff can't tell the Critic that a sibling file (a second store
  implementation, a matching test, a downstream caller) was never updated —
  you have to see the whole file to notice an absence.
- Visual or product work: actual screenshots or a running instance, not a
  text description of what it looks like.
- Writing: the actual draft text, in full.

### 3. Delegate to the Critic — fresh context, no Builder history

```
delegate(instructions: "Evaluate this against the bar below. You have not
seen how or why any of this was made — evaluate only what exists. If a
reference is provided, compare directly against it, blind where possible —
you should be judging which is better, not confirming the builder's choices.

Bar: <the stated bar, or the reference artifact itself>

The actual artifact: <full files / screenshots / draft text — never a
builder-written summary>

<if available: relevant spec/PRD/openspec artifacts>

Check, in this order, stopping at the first failure:
1. Conformance to existing patterns/reference — independent of any spec or
   builder explanation. Would this look out of place, or lose a side-by-side
   comparison?
2. Fidelity to the stated design/spec, if one exists.
3. Coverage of the stated goal/quality bar.

Respond with exactly one verdict — PASS or HOLD — followed by the single
biggest remaining gap if HOLD, specific and actionable: name the file, the
line or function, or the exact visual/content difference. Don't list every
issue — name the largest one so the Builder has a clear next move.")
```

Do **not** give the Critic subagent the Builder's conversation, reasoning, or
commit history. It should only ever see: the bar/reference, the actual current
artifact, and (if relevant) the design artifacts. This is what makes it a
critic and not an echo of the Builder.

### 4. Branch on the verdict

- **PASS** → stop. Report the outcome, the number of iterations it took, and a
  summary of what was built.
- **HOLD** → the Critic's single biggest-gap feedback becomes the Builder's
  instructions for the next iteration. Increment the iteration count and go
  back to step 1.
- **Ceiling reached without PASS** (or user-observed diminishing returns, if
  running in no-ceiling mode) → stop. Report the current state, the Critic's
  most recent feedback, and recommend the user review directly rather than
  continuing to loop.

## Optional: watch it without interrupting it

For longer or unattended runs, maintain a simple live progress file (an HTML
page or a `progress.md`/`workbench.md`) updated at the end of each iteration —
current status, what changed, the Critic's latest verdict. This lets the user
check in without having to interrupt the loop to ask for a status update. Keep
it lightweight and don't over-specify its format — whatever best represents
progress for the task at hand (screenshots, test results, a changelog) is fine.

## Scaling up: decomposition and parallel loops

The two-role loop above is the atomic unit. For a large goal, don't run one
giant Builder/Critic loop over the whole thing — let a lead pass split the
goal into the **smallest pieces that can be built and judged independently**,
then run a separate Builder/Critic loop per piece (in parallel, via multiple
`delegate` calls, when the pieces don't depend on each other).

- Let the agent decide the decomposition; don't prescribe it. It understands
  the artifact and can judge what should be separated, what should stay
  together, and what can run concurrently.
- "Make the whole thing better" is too vague a target for any one loop.
  "Make this one piece beat this one reference" gives a loop something it can
  actually converge on.
- After a wave of parallel piece-loops finishes, optionally spawn one fresh
  agent to do a **smoothing pass**: inspect the combined result, fix
  inconsistencies between independently-improved pieces, and make sure it
  reads as one thing rather than a collection of parts. This is not another
  Builder/Critic round — its job is coherence, not quality-bar enforcement.

This is composition of the same two-role mechanism, not a different one: more
delegation calls, run per-piece, optionally in parallel, optionally followed by
a reconciliation pass. Build and confirm the single two-role loop converges
before reaching for decomposition — it adds real coordination overhead.

## Notes on scaling further

Beyond decomposition, the same mechanism extends to: a Red-Teamer for
adversarial probing (spawned blind to the Critic's feedback, so it doesn't
inherit the same blind spots), a Judge on a stronger/more effortful model for
final sign-off across multiple critics, a shared task board so multiple loops
can run without duplicating work, or real process isolation via containers or
git worktrees. All of these are more subagents and more delegation calls
layered on this same core — add roles one at a time, only once the two-role
loop is proven to converge.

## See also

- [The Gauntlet Loop (Matt Shumer)](https://somethingbig.ai/gauntlet-loop) —
  the public source for the "give it a bar it can't talk its way around, never
  let the builder grade itself" framing.
