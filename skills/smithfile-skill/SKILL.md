---
name: smithfile-skill
description: Generate a tailored Smithfile for a repository by exploring its codebase, build system, and existing configuration.
kind: tool
---

# /smithfile

Generate a tailored Smithfile for a repository by exploring its codebase, build system, and existing configuration.

## When to use

- User says `/smithfile` or "create a smithfile" or "set up smith for this repo"
- User wants to onboard a repository for smith integration
- User asks how to configure smith for their project

## What you must do

Follow these steps in order. Do not skip steps.

### Step 1 — Detect the project

Explore the repository to determine:

1. **Language and framework**: Check for `go.mod` (Go), `package.json` (Node/TypeScript), `requirements.txt`/`pyproject.toml` (Python), `Cargo.toml` (Rust), `pom.xml`/`build.gradle` (Java/Kotlin). Check for frameworks (React, Next.js, FastAPI, Gin, etc.).

2. **Build system**: Check for `Makefile`, `mise.toml`, `justfile`, `Taskfile.yml`, `package.json` scripts, `Cargo.toml`, or CI workflow files (`.github/workflows/`). Extract the actual build, test, and lint commands.

3. **Existing smith artifacts**: Check for `AGENTS.md` (absorb into build_instructions), `GUARDRAILS.md` (reference or absorb), `CLAUDE.md` (check for smith-relevant instructions).

4. **Runtime needs**: Check for `Dockerfile`, `.tool-versions`, `mise.toml` tool specifications. These hint at what the runtime image needs.

5. **Test infrastructure**: What test commands exist? Unit tests, integration tests, e2e tests? What lint tools? (eslint, golangci-lint, ruff, clippy, etc.)

Print a summary:

```
Detected:
  Language:    Go 1.25
  Build:       go build ./...
  Test:        go test ./... -short
  Lint:        golangci-lint run (via mise)
  Framework:   None (CLI + API server)
  Existing:    AGENTS.md (will absorb), GUARDRAILS.md (will reference)
```

### Step 2 — Ask the user

Ask these questions using AskUserQuestion:

1. **Provider preference**: codex-default, claude-default, or gemini-default?
2. **Max iterations**: How many loop iterations before hard stop? (suggest 25 for small repos, 30-40 for large)
3. **Guardrails**: Should guardrails be inline in the Smithfile or reference an existing GUARDRAILS.md?

If the answers are obvious from context (e.g., CLAUDE.md exists so claude-default is likely), you can suggest a default.

### Step 3 — Generate the Smithfile

Write a `Smithfile` to the repo root with:

- `version: 1`
- `runtime` section if custom images are needed (leave empty for defaults)
- `provider.profile` from user's choice
- `max_iterations` from user's choice
- `env` with any environment variables needed for build/test (e.g., `CI: "true"`, `CGO_ENABLED: "0"`)
- `lifecycle` hooks derived from the detected build system:
  - `startup`: dependency installation (npm ci, go mod download, pip install, etc.)
  - `pre_workflow`: lint check
  - `post_workflow`: test suite
  - `on_failure`: verbose test output for debugging
- `dispositions` for feature, bug-fix, and refactor with real commands from the repo
- `build_instructions` absorbing AGENTS.md content if it exists, or generating from detected commands
- `guardrails` inline or referencing GUARDRAILS.md per user preference

### Step 4 — Validate

Run `smith smithfile validate Smithfile` (or `go run ./cmd/smith smithfile validate Smithfile` if the CLI isn't installed) to verify the generated Smithfile is valid.

If validation fails, fix the errors and re-validate.

### Step 5 — Present the result

Show the user the generated Smithfile and explain:
- What each section does
- What the lifecycle hooks will run
- What guardrails are enforced
- Next steps: commit and push, then attach via GitHub App

## Examples

### Go project

```yaml
version: 1

provider:
  profile: claude-default

max_iterations: 25

env:
  CGO_ENABLED: "0"
  GOFLAGS: "-count=1"

lifecycle:
  startup: "go mod download"
  pre_workflow: "golangci-lint run"
  post_workflow: "go test ./... -short"
  on_failure: "go test ./... -short -v 2>&1 | tail -100"

dispositions:
  feature:
    implement_commands:
      - "go build ./..."
      - "go test ./... -short"
    validate_commands:
      - "golangci-lint run"
    implement_prompts:
      - "Follow TDD workflow. Write failing tests first."
  bug-fix:
    diagnose_commands:
      - "go test ./... -short -v"
    implement_commands:
      - "go build ./..."
      - "go test ./... -short"

build_instructions: |
  ## Build
  go build ./...

  ## Test
  go test ./... -short

  ## Lint
  golangci-lint run

guardrails: |
  - Always run tests before committing
  - Do not modify generated files
  - Use conventional commit messages
```

### Node.js project

```yaml
version: 1

provider:
  profile: claude-default

max_iterations: 30

env:
  NODE_ENV: test
  CI: "true"

lifecycle:
  startup: "npm ci"
  pre_workflow: "npm run lint"
  post_workflow: "npm test"
  on_failure: "npm test -- --reporter=verbose 2>&1 | tail -100"

dispositions:
  feature:
    implement_commands:
      - "npm test"
      - "npm run build"
    validate_commands:
      - "npm run lint"
    implement_prompts:
      - "Follow TDD workflow. Write failing tests first."
      - "Use the existing component patterns in src/components/."
  bug-fix:
    diagnose_commands:
      - "npm test -- --reporter=verbose"
    implement_commands:
      - "npm test"

build_instructions: |
  ## Build
  npm run build

  ## Test
  npm test

  ## Lint
  npm run lint

  ## Type Check
  npm run typecheck

guardrails: |
  - Always run tests and lint before committing
  - Never install new dependencies without updating the lock file
  - Do not add inline styles; use design system tokens
  - Use conventional commit messages
```

### Python project

```yaml
version: 1

provider:
  profile: claude-default

max_iterations: 25

env:
  PYTHONDONTWRITEBYTECODE: "1"

lifecycle:
  startup: "pip install -e '.[dev]'"
  pre_workflow: "ruff check . && mypy ."
  post_workflow: "pytest"
  on_failure: "pytest -v --tb=long 2>&1 | tail -100"

dispositions:
  feature:
    implement_commands:
      - "pytest"
    validate_commands:
      - "ruff check ."
      - "mypy ."
    implement_prompts:
      - "Write tests first. Use pytest fixtures."
  bug-fix:
    diagnose_commands:
      - "pytest -v --tb=long"
    implement_commands:
      - "pytest"

build_instructions: |
  ## Install
  pip install -e '.[dev]'

  ## Test
  pytest

  ## Lint
  ruff check .

  ## Type Check
  mypy .

guardrails: |
  - Always pin dependency versions
  - Never commit notebook output or large data files
  - Always add docstrings to new public functions
  - Run ruff and mypy before marking work complete
```

## Important

- The Smithfile must be valid YAML with `version: 1`
- Environment variable keys cannot use the `SMITH_` prefix (reserved)
- Lifecycle events must be one of: startup, post_environment, pre_workflow, post_workflow, pre_finalize, on_failure
- Disposition keys must be one of: feature, bug-fix, refactor, chore, autofix, research, other
- Pull policies must be: IfNotPresent, Always, or Never
- If an AGENTS.md exists, its content should be absorbed into build_instructions (Smithfile takes precedence at runtime)
