---
name: qtip-manifest-helper
description: Generate and validate qtip Subject Manifests for software projects. Use when a user needs to define a project's identity, capabilities, and interfaces for evaluation by the qtip platform.
---

# qtip Manifest Helper

Use this skill to assist users in creating a **Subject Manifest** for their project.

## Workflow

1.  **Analyze the Project**: Identify the project's ID, environment, and interaction interfaces (API, CLI, Logs).
2.  **Define Capabilities**: List the functional areas (e.g., `auth`, `build`, `billing`) that need evaluation.
3.  **Generate JSON**: Create the `manifest.json` following the schema.

## Schema Reference

See [references/manifest-schema.md](references/manifest-schema.md) for the full Zod schema and example.

## Interaction Patterns

### "Help me create a manifest for my project smith"
1.  Ask the user for the `baseUrl` (if API) or `logPath` (if Log validation).
2.  Suggest relevant `capabilities` based on the project description.
3.  Produce the final JSON block.

### "What interfaces are supported?"
- **api**: Requires a `baseUrl`. Used for REST/JSON interactions.
- **cli**: Used for command-line tool execution.
- **logs**: Requires a `path` to the log file.
- **ui**: (Future) Web interaction via Playwright.

## Example Output

"Here is your manifest for **smith**:

```json
{
  "projectId": "smith",
  "environment": "ci",
  "interfaces": [
    { "type": "cli" }
  ],
  "capabilities": ["build", "cli-core"]
}
```"
