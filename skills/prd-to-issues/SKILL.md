---
name: prd-to-issues
description: Break a PRD into independently-grabbable GitHub issues using tracer-bullet vertical slices. Use when user wants to convert a PRD to issues, create implementation tickets, or break down a PRD into work items.
---

# PRD to Issues

Break a PRD into independently-grabbable GitHub issues using vertical slices (tracer bullets).

## Process

### 1. Locate the PRD

Ask the user for the PRD GitHub issue number (or URL).

If the PRD is not already in your context window, fetch it with `gh issue view <number>` (with comments).

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code.

### 3. Draft vertical slices

Break the PRD into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as an architectural decision or a design review. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?
- Should all approved slices be attached as sub-issues to the parent PRD issue? (Default: yes)

Iterate until the user approves the breakdown.

### 5. Create the GitHub issues

For each approved slice, create a GitHub issue using `gh issue create`. Use the issue body template below.

Create issues in dependency order (blockers first) so you can reference real issue numbers in the "Blocked by" field.

<issue-template>
## Parent PRD

#<prd-issue-number>

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation. Reference specific sections of the parent PRD rather than duplicating content.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- Blocked by #<issue-number> (if any)

Or "None - can start immediately" if no blockers.

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7

</issue-template>

Do NOT close or modify the parent PRD issue.

### 6. Attach slices as sub-issues of the parent PRD

After creating slice issues, attach each one as a sub-issue of the parent PRD issue.

Preferred method (GitHub GraphQL via `gh api`):

1. Get parent PRD node ID:

```bash
PARENT_ID="$(gh issue view <prd-issue-number> --json id --jq '.id')"
```

2. For each created slice issue number `<child-number>`, attach it:

```bash
CHILD_URL="$(gh issue view <child-number> --json url --jq '.url')"
gh api graphql \
  -f query='mutation($issueId:ID!, $subIssueUrl:String!) { addSubIssue(input:{issueId:$issueId, subIssueUrl:$subIssueUrl}) { issue { number } subIssue { number } } }' \
  -f issueId="$PARENT_ID" \
  -f subIssueUrl="$CHILD_URL"
```

3. Verify linkage:
- Open parent issue in web UI and confirm sub-issues are listed.
- Optionally run:

```bash
gh issue view <prd-issue-number> --comments
```

Fallback if sub-issue mutation is unavailable:
- Add a single parent issue comment with a markdown task list linking all slice issues.
- Keep each child issue body field `## Parent PRD` pointing to `#<prd-issue-number>`.
