---
name: "pipeline-router"
description: "Meta-skill for the Book of Challenges editing pipeline. Query the current pipeline stage via MCP and load the appropriate stage-specific skill. Load this skill first in any editing session — it tells you which skill to use next."
---

# Pipeline Router

## Purpose

This is the entry-point skill for any editing session on the Book of Challenges manuscript. It routes you to the correct stage-specific workflow by querying the manuscript's pipeline state directly from the MCP server.

**Always load this skill first.** Then follow the three steps below.

---

## Step 1: Query the Pipeline Stage

Call the `get_pipeline_stage` tool from the `book-annotations` MCP server:

```
Tool: get_pipeline_stage
Arguments: {}
```

The response will include:
- `activeStage` — the current stage ID
- `activeStageName` — human-readable name
- `activeStageStatus` — `pending` | `active` | `complete`
- `recommendedSkill` — the skill name to load next
- `activeStageNotes` — context and decisions recorded for this stage
- `annotationStats` — live counts of open/resolved annotations (relevant to copyedit stage)
- `bookBrief` — the author's editorial brief (pitch, audience, outOfScope, constraints)

### Reading the Book Brief

The `bookBrief` field is **mandatory reading before any editing work begins**. It contains:

| Field | Purpose |
|---|---|
| `pitch` | What the book is. One or two sentences. |
| `audience` | Who it is written for. |
| `outOfScope` | What the book deliberately does NOT cover. Never suggest content in this category. |
| `constraints` | Non-negotiable editorial decisions the author has locked in. Never override these. |

If `bookBrief` fields are null or empty, **stop and ask the author to fill in the Book Brief** in the pipeline view before proceeding. Editing without it risks producing suggestions that contradict the book's purpose.

If `bookBrief.outOfScope` or `bookBrief.constraints` are set, read them carefully and carry them forward as hard rules for the entire editing session. Every annotation you add must be consistent with them.

---

## Step 2: Load the Stage Skill

Based on `recommendedSkill`, load the corresponding skill:

| `activeStage` | `recommendedSkill` | What it covers |
|---|---|---|
| `developmental` | `developmental-edit` | Structure, pacing, GM UX, information architecture |
| `line` | `line-edit` | Prose artistry, rhythm, voice, clichés |
| `copyedit` | `copy-editing` | Grammar, CMOS, TTRPG formatting, consistency |
| `proofread` | `proofread` | Final typos, mechanical errors, layout artefacts |
| `sensitivity` | `sensitivity-edit` | Cultural accuracy, representation, harmful tropes |
| `playtest` | `playtest` | Mechanical clarity, time scope, table usability |

Load the skill and execute its full workflow with the pipeline context already in hand.

---

## Step 3: Update the Stage on Completion

When the editing pass for a stage is genuinely complete, call `set_pipeline_stage` to record it:

```json
{
  "stageId": "<the active stage id>",
  "status": "complete",
  "note": "Brief summary of what was done and how many findings were recorded."
}
```

Do NOT mark a stage complete unless the work is genuinely finished. If the pass is partial, call:

```json
{
  "stageId": "<the active stage id>",
  "status": "active",
  "note": "Progress note: completed chapters X–Y. Chapters Z–W remain."
}
```

---

## Stage Sequencing Rules

The pipeline has a fixed order. Stages should be worked in sequence, not in parallel:

```
Developmental Edit
       ↓
   Line Edit
       ↓
   Copyedit        ← currently active for this manuscript
       ↓
[Layout & Design]  ← manual step outside this tool
       ↓
   Proofread       ← locked until Copyedit is marked complete
```

**Specialized stages** (Sensitivity Edit, Playtest) can run at any point after Developmental Edit is complete — they are not strictly sequential with the main pipeline.

---

## If No Stage Is Active

If `get_pipeline_stage` returns no active stage, check `allStages` in the response to see which stage is next in sequence. Then call `set_pipeline_stage` to start it:

```json
{ "stageId": "<next stage>", "status": "active", "note": "Starting <stage name> pass." }
```

Then re-run `get_pipeline_stage` to confirm, and load the appropriate skill.

---

## Current Manuscript State (as of last update)

- **Active stage:** Copyedit
- **Developmental Edit:** Not yet started — structure review needed before next major revision
- **Line Edit:** Not yet started — will run after structural issues are resolved
- **Copyedit:** Active — 165 annotations across 67 chapters; ~122 open items in Review Queue
- **Proofread:** Locked — unlocks when Copyedit is marked complete
- **Sensitivity Edit:** Not started
- **Playtest:** Not started

---

## MCP Server Connection

**Stdio (local):**
```bash
node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/mcp.js
```

**HTTP (Tailscale / Gemini mobile):**
```
http://aurelius.taila4fb6a.ts.net:3001/mcp
```
