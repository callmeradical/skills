---
name: smith-onboard
description: Onboard a repository to a smith deployment. Generates Smithfile + GUARDRAILS.md tailored to the project, commits/pushes, refreshes the GitHub App catalog, attaches the repo, and verifies the project record. Use when the user says "onboard <repo> to smith", "add this repo to smith", or invokes /smith-onboard.
---

# /smith-onboard

Connect a Git repository to a smith deployment as an autonomously-managed project. Every step uses the `smith` CLI (no console UI, no curl).

## Inputs

- **Target directory**: a Git working tree. If the user did not specify, default to the current working directory.
- **Smith context**: the CLI context that points at the deployment (`~/.smith/config.json`). If multiple contexts exist, ask which one.

## Preflight

Confirm each before mutating anything:

1. `smith config get-contexts` shows the desired context, and `smith config use-context <name>` selects it.
2. `smith integration github-app status` reports `connected: true`. If not, stop and tell the user to install the App at the URL the status response surfaces.
3. The target directory has a clean git tree (`git status --short` is empty) on its default branch. If dirty, ask before continuing — the skill will create commits.
4. The repo has a remote pointed at GitHub (`git remote get-url origin` ends in `.git` or matches the App's installed scope).
5. A provider profile exists. Check via `smith --output json provider list`. If none exists, walk the user through `smith provider add` before continuing.

## Step 1 — Detect the project shape

Read enough of the repo to choose sensible build/test/lint commands:

- `package.json` → Node project. Use `npm run build`, `npm run test:unit -- --run`, `npm run lint`. If `package.json` has no `lint` script, fall back to whatever `mise.toml` declares.
- `go.mod` → Go project. Use `go build ./...`, `go test ./... -short`, `mise run lint` if a lint task exists else `golangci-lint run`.
- `pyproject.toml` / `setup.py` → Python project. Use `pytest`, `ruff check` / `pyright`, build via `python -m build`.
- `Cargo.toml` → Rust project. `cargo build`, `cargo test`, `cargo clippy`.
- `mise.toml` overrides everything — if `mise run build`, `mise run test:unit`, `mise run lint` exist, prefer them.

Pick a `provider.profile` that matches an existing profile from `smith provider list`. Default to `claude-default` if it exists.

## Step 2 — Generate Smithfile and GUARDRAILS.md

Write `Smithfile` at the repo root in the schema below. Disposition profiles must match the project shape (e.g. Go projects do not need npm commands).

```yaml
version: 1

runtime:
  image: ghcr.io/callmeradical/smith-replica:branch-main
  pull_policy: Always
  skills_image: ghcr.io/callmeradical/smith-skills:branch-main
  skills_pull_policy: Always

provider:
  profile: <profile-id>

namespace: smith-system

max_iterations: 25

review:
  gates:
    - stage: planning
      timeout: 24h

env:
  # project-specific environment

lifecycle:
  startup: "<install dependencies>"
  pre_workflow: "<lint>"
  post_workflow: "<short test>"
  on_failure: "<verbose test, capped output>"

dispositions:
  feature:
    implement_commands: [...]
    validate_commands: [...]
    implement_prompts:
      - "Follow TDD; failing tests first."
      - "Match existing code style; no drive-by refactors."
  bug-fix:
    diagnose_commands: [...]
    implement_commands: [...]
    implement_prompts:
      - "Reproduce with a failing test before fixing."
  refactor:
    implement_commands: [...]
    validate_commands: [...]
    implement_prompts:
      - "Existing tests pass before and after."
  chore:
    implement_commands: [...]
    validate_commands: [...]

build_instructions: |
  ## Install
  <install steps>
  ## Build
  <build cmd>
  ## Test
  <test cmd>
  ## Lint
  <lint cmd>

guardrails: |
  - <project-specific rule>
  - <…>
```

Write `GUARDRAILS.md` at the repo root with detailed safety constraints. Cover: code style, API/dependency boundaries, accessibility (if UI), testing expectations, build/deploy invariants, commit conventions, and an explicit "what loops must not do" section.

Both files together. Show the user a diff before committing.

## Step 3 — Commit and push

Two commits, in this order, on the default branch:

```bash
git add Smithfile GUARDRAILS.md
git commit -m "chore: onboard repository to smith with Smithfile + guardrails

<short why; reference smith deployment>"

git push origin <default-branch>
```

If unsigned commits are blocked, surface the error and stop.

## Step 4 — Refresh and attach via smith CLI

```bash
smith api post /integrations/github-app/repositories/refresh --body '{}'
smith integration scope list github-app | jq '.repositories[] | select(.full_name=="<owner>/<repo>")'
```

If the repo does **not** appear after refresh, the App's GitHub-side scope does not include it. Tell the user to grant access at:

> GitHub → Settings → Applications → Smith → Configure → Repository access → add `<owner>/<repo>`

Then re-run the refresh. This is the only step that cannot be done from the smith CLI (auth boundary).

When the repo does appear, attach:

```bash
smith integration scope attach github-app --scope <owner>/<repo>
```

The response is the created Project record. Surface the project id and key fields.

## Step 5 — Verify

Run all four checks; surface the output:

```bash
smith api post /integrations/github-app/repositories/refresh --body '{}' | jq .refreshed_at

smith integration scope list github-app | \
  jq '.repositories[] | select(.full_name=="<owner>/<repo>") | {full_name, attached, default_branch}'

smith --output json project list | \
  jq '.result[] | select(.active_repo_full_name=="<owner>/<repo>") | {id, github_app_id, github_installation_id, provider_profile_id}'

smith --output json provider list | jq '.result[] | select(.id=="<profile-id>")'
```

Project is fully onboarded when:
- The repo shows `attached: true`
- The project record carries non-empty `github_app_id` and `github_installation_id`
- The referenced provider profile exists

## Step 6 — Document and offer

Optionally write `ONBOARDING.md` at the repo root mirroring the deployment-specific identifiers (project id, App id, installation id, image tags). This is a courtesy for future operators; ask the user before committing it as that's repo-visible.

If the smith deployment is running with
`SMITH_ISSUE_PROVIDER_COMMAND_INVOCATION_ONLY=true` (the default for our
deployments), say so explicitly: **labels do not dispatch loops** — only
`/smith run` (and other `/smith ...`) comments do. Mention this when you
offer next steps so the user does not file labeled-but-silent issues.

Offer next steps:
- "Want me to file a GitHub issue and post `/smith run` to trigger the first loop?"
- "Want me to scaffold a PRD via `smith prd create`?"

## What this skill explicitly does NOT do

- Install the Smith GitHub App (user-driven on github.com).
- Grant the App access to a new repo on GitHub (auth boundary).
- Provision provider API keys (cluster-secret operation).
- Modify branch protection or CI rules.

## Errors and recoveries

| Symptom | Remedy |
| --- | --- |
| `repository_outside_installation_scope` on attach | The catalog is stale or the App lacks repo access. Refresh; if still missing, grant access on GitHub. |
| `smithfile_required` on attach | The Smithfile is not on the default branch. `git push` it. |
| `smithfile_invalid: …` | Re-edit and re-push. Errors point at the offending field. |
| `provider profile not found` | Create it via `smith provider add` before re-attaching. |
| `409 conflict: project exists` | The repo is already attached. Use `smith project list` to find the existing record; treat as success. |

## Style

Caveman-style status updates while running ("refresh catalog", "attach: ok", "verify: green"). Final response: project id, the four verify checks summarised, and a one-line offer for next-step actions.
