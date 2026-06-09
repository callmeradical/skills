# AI Resolve Skill — Book of Challenges

Resolves developmental annotations that have been queued for AI action by the author.

## When to use

Load this skill when the user says:
- "resolve the AI queue"
- "work through the queued annotations"
- "resolve flagged annotations"
- invokes `/ai-resolve`

## Prerequisites

The MCP server must be running:
```
node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/mcp.js
```

## Workflow

### Step 1 — Get the queue

Call `get_actionable_annotations` with `queuedOnly: true`:

```
get_actionable_annotations({ queuedOnly: true })
```

This returns a list of task objects. Each has:
- `commentId` — pass to `resolve_comment` when done
- `chapterId` / `chapterTitle` — the chapter to act on
- `actionType` — one of: `move`, `rename`, `replace`, `rewrite`, `expand`, `manual`
- `annotationText` — full annotation content
- `contentExcerpt` — first 400 chars of chapter content
- `prompt` — specific instructions for this task

If the queue is empty, tell the user and stop.

### Step 2 — Show the queue to the user

Before acting, summarise what's queued:
- List each task: chapter title, action type, one-line description of what will be done
- Ask: "Shall I proceed with all of these, or would you like to skip any?"

### Step 3 — Execute each task

Work through tasks one at a time. For each:

**move** — reassign `parentId` and `order`:
1. Read the manuscript with `get_comments` to understand the folder structure
2. Find the correct target folder ID
3. Use Python/bash to update `parentId` and `order` in `manuscript.jsonl`
4. Call `resolve_comment` with `status: "completed"` and a reply summarising what moved where

**rename** — update `title` and `metaTitle`:
1. Read the annotation to determine the new name
2. Update in `manuscript.jsonl` via Python/bash
3. Call `resolve_comment` with `status: "completed"`

**replace** — find-and-replace in chapter content:
1. Read the annotation to identify the terms and replacements
2. Apply in `manuscript.jsonl` via Python/bash
3. Verify no instances remain
4. Call `resolve_comment` with `status: "completed"`

**rewrite** — targeted prose rewrite:
1. Read the full chapter content
2. Locate the problematic passage identified in the annotation
3. Rewrite to address the annotation's concern
4. Use `suggest_revision` to propose the change for author review
5. Call `resolve_comment` with `status: "completed"`

**expand** — requires new content:
- Do NOT attempt to auto-resolve
- Tell the user: "This annotation requires new chapter content. Use the Draft workpad to write it."
- Skip and move to the next task

**manual** — requires judgment:
- Do NOT attempt to auto-resolve
- Tell the user what the annotation says and ask what they'd like to do
- Skip if they want to defer it

### Step 4 — Report

After working through the queue, report:
- What was completed (with brief description of each action)
- What was skipped (expand/manual) and why
- Remind the user to reload the editor to see changes

## Rules

- Always read before writing — use `get_comments` or read `manuscript.jsonl` to understand current state before modifying
- One task at a time — complete and resolve each before moving to the next
- Never mark `expand` or `manual` tasks as completed without author confirmation that the work is done
- If a task is ambiguous, ask the author before acting
- Write a closing reply on each `resolve_comment` call explaining what was done
