---
name: qtip-scenarios
description: Generate qtip scenario YAML files from a PRD, GitHub issue, or user story. Use when user wants to create qtip scenarios, generate evaluation scenarios, convert a PRD to qtip tests, or author scenarios from acceptance criteria. Trigger on "qtip scenarios", "generate scenarios", "scenarios from PRD", "scenarios from issue".
---

# Generate qtip Scenarios

Generate scenario YAML files for the qtip evaluation platform from a PRD, GitHub issue, or user story.

**CRITICAL**: Scenarios MUST be written to a **separate scenarios repository**, NOT to the project repo under test. This is the core security property of qtip — the "oracle pattern." The agent developing the project code cannot modify the scenarios that evaluate it. If you are currently in the project repo, you need to find or ask for the scenarios repo location before writing any files.

## Process

### 1. Determine the scenarios repo

Before anything else, establish where scenario files will be written:

- Check if the project's manifest (`qtip-manifest.json`) has a `scenarios.repo` field — that's the scenarios repo (e.g. `callmeradical/scenarios`)
- If not, ask the user: "Where is your scenarios repo? (e.g. `~/Dev/scenarios` or `owner/scenarios` on GitHub)"
- If the scenarios repo is not cloned locally, clone it: `git clone https://github.com/<owner>/<repo>.git`

All scenario files are written to `<scenarios-repo>/<project-name>/` — NEVER to the project repo itself.

### 2. Get the source

Ask the user for one of:
- A GitHub issue number or URL (fetch with `gh issue view <number>`)
- A local file path to a PRD or spec
- A description of what to test

If a GitHub issue, read it including comments. Extract all acceptance criteria, user stories, and testable behaviors.

### 3. Get the project context

You need two things:
- **The project's qtip manifest** — find `qtip-manifest.json`, `qtip.json`, or `manifest.json` in the project repo. This tells you what capabilities and interfaces the project exposes.
- **The project's codebase** (optional but recommended) — explore the project repo to understand what commands, endpoints, or log patterns actually exist.

Ask the user for the project repo path if you don't already know it.

From the manifest, note:
- `capabilities` — what the project can do
- `interfaces` — what types of interaction are available (api, cli, logs)
- `environment` — what environment this runs in

### 4. Map acceptance criteria to scenarios

For each acceptance criterion or testable behavior from the source:

1. Determine the **interaction type** (api, cli, or logs) based on what's being tested
2. Determine which **capability** it validates
3. Write the concrete **interaction** (the HTTP request, CLI command, or log query)
4. Write the **checks** that verify the behavior

Rules:
- Each scenario tests ONE focused behavior
- Scenario IDs follow the pattern: `PROJECT-CAPABILITY-NNN` (e.g. `FRACTAL-BUILD-001`)
- Every check must reference an acceptance criterion ID
- Prefer concrete, runnable commands over abstract assertions
- CLI commands must work from the project root directory (`cd <project-path> && ...`)
- API interactions need a `request` with `method` and `path` — the base URL comes from the manifest at runtime
- Log interactions need a `query` string — the log file path comes from the manifest at runtime

### 5. Present the plan

Before writing files, show the user a summary:

For each scenario:
- **ID**: scenario ID
- **Name**: human-readable description
- **Type**: api / cli / logs
- **Capability**: which capability it tests
- **Checks**: what it validates

Ask: "Does this coverage look right? Any scenarios to add, remove, or change?"

Iterate until approved.

### 6. Write the scenario files

Write each scenario as a YAML file. Use this structure:

```yaml
id: PROJECT-CAPABILITY-NNN
name: Human readable description
applies_to:
  capabilities: [capability-name]
  interfaces: [interaction-type]
acceptance_criteria:
  - id: AC-1
    description: What this criterion means
interaction:
  type: api|cli|logs
  # For API:
  request:
    method: POST
    path: /endpoint
    body: { "key": "value" }
  # For CLI:
  command: cd /path/to/project && some-command
  # For Logs:
  query: "search string"
checks:
  - type: status_code|json_path|stdout|stderr|log_contains|log_not_contains
    expected: value        # for status_code, stdout, stderr
    path: $.json.path      # for json_path
    exists: true           # for json_path existence check
    acceptance_criteria: AC-1
```

Organize files as: `<project>/<capability>/<scenario-name>.yaml`

### 7. Commit to the scenarios repo

Commit the new files in the scenarios repo (NOT the project repo):

```
cd <scenarios-repo>
git add <project>/<files>
git commit -m "Add scenarios for <project> from <source>"
```

Do NOT push without asking — the user may want to review first. Remind the user that once pushed, these scenarios become the immutable evaluation criteria for the project.

## Check type reference

| Check | Use with | Description |
|-------|----------|-------------|
| `status_code` | api, cli | HTTP status code or exit code equals expected value |
| `json_path` | api | JSONPath query on response body; check `exists: true` or `expected: value` |
| `stdout` | cli | stdout contains expected string |
| `stderr` | cli | stderr contains expected string |
| `log_contains` | logs | log file contains a line matching the query |
| `log_not_contains` | logs | log file does NOT contain a line matching the query |

## Environment constraints

If a scenario should only run in certain environments, add:

```yaml
applies_to:
  capabilities: [auth]
  interfaces: [api]
  environments: [staging, production]  # omit to match all environments
```
