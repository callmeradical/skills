---
name: kaleidoscope
description: Browser automation and design QA using Kaleidoscope (`ks`). Use for interactive page inspection, screenshots, accessibility checks, responsive checks, and design-token compliance.
kind: tool
---

# Kaleidoscope Workflow

This skill provides Kaleidoscope CLI workflows for browser-driven development and design verification.

## Prerequisites

- `ks` must be installed and available on `PATH` in the runtime container.
- For URL-based flows, a running app endpoint is reachable from the replica.

## Standard Flow

1. Start browser lifecycle:
   - `ks start`
2. Open target:
   - `ks open <url>`
3. Capture and inspect:
   - `ks screenshot`
   - `ks inspect <selector>`
   - `ks layout --depth 3`
4. Run quality checks:
   - `ks audit`
   - `ks contrast`
   - `ks breakpoints`
5. Report concrete findings with selectors, measurements, and fix suggestions.

## Task Recipes

Choose the closest recipe and follow it exactly:

- Design review: `references/design-review.md`
- Visual consistency audit: `references/visual-audit.md`
- Accessibility remediation: `references/accessibility-fix.md`
- Responsive verification: `references/responsive-check.md`
- Build component flow: `references/build-component.md`
- Design token alignment: `references/design-tokens.md`
- Catalog usage and lookup: `references/use-catalog.md`

## Rules

- Prefer measured evidence from `ks` output over assumptions.
- Include breakpoint evidence for UI changes.
- If audit errors are reported, include exact remediation steps.
- Keep recommendations actionable and scoped to the user request.
