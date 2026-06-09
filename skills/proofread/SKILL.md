---
name: "proofread"
description: "Proofreading skill for the Book of Challenges manuscript. The final safety net — catches microscopic errors that survived every prior pass. Runs after copyediting is complete. Uses the book-annotations MCP server."
---

# Proofread Skill

## 1. What Proofreading Is (and Is Not)

Proofreading is the **absolute final step** before publishing. It is narrower and more mechanical than every previous stage.

- **Not copyediting** — you are not enforcing style rules; those decisions were made in the Copyedit stage
- **Not line editing** — you are not improving prose; you are finding what slipped through
- **Not developmental** — the structure is locked

**The mindset:** You are a quality-control inspector, not a creative collaborator. Your job is to find what everyone else missed.

> **Note:** Ideally proofreading runs on the final laid-out PDF. Since layout is not yet complete, this pass targets the manuscript text itself — catching errors before layout introduces additional complexity.

---

## 2. MCP Server Tools

Use `book-annotations` MCP server (stdio: `node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/mcp.js`).

### `get_pipeline_stage`
Call this first. Confirm `proofread` stage is active. This stage requires `copyedit` to be `complete`.

### `add_comment`
The primary tool for this stage. Type is always `"Style"` for mechanical errors.

```json
{
  "sectionId": "chapter-id",
  "text": "\"exact error\"\n\nProofread: [specific error description and correct form].",
  "type": "Style",
  "quote": "exact text containing the error",
  "author": "Proofreader"
}
```

### `suggest_revision`
Use only when the correction is unambiguous — a clear wrong word, a missing word, a definite spelling error:

```json
{
  "sectionId": "chapter-id",
  "original": "the exact wrong text",
  "replacement": "the corrected text",
  "reason": "Typo / Missing word / Wrong word",
  "ruleLabel": "Proofread",
  "author": "Proofreader"
}
```

### `set_pipeline_stage`
On completion: `{ "stageId": "proofread", "status": "complete", "note": "Final proofread complete. X errors found." }`

---

## 3. The Proofreader's Checklist

Work through each chapter against this checklist. Do not read for meaning — read for errors.

### Tier 1: Definite Errors (always flag)
These are unambiguously wrong and must be corrected:

- **Typos and misspellings** — including words that are spelled correctly but are the wrong word (`their/there/they're`, `its/it's`, `affect/effect`, `principal/principle`, `mettle/metal`)
- **Missing words** — sentences where a word has been dropped (re-read each sentence slowly)
- **Doubled words** — "the the", "a a", "is is"
- **Broken sentences** — sentences that end without a verb or start without a subject
- **Incorrect numbers** — dice notation errors (`2d8` vs `2d6` — flag as a question if uncertain), page references, DC values that contradict the chapter's stated difficulty

### Tier 2: Consistency Errors (flag if not in style sheet)
These require checking against the established style:

- **Name spelling:** Every proper noun (character names, location names, ability names) should be consistent throughout the manuscript. Flag any that appear in multiple forms.
- **Capitalisation of game terms:** If `Armor Class` is capitalised in Chapter 3, it must be capitalised everywhere. Flag any exceptions.
- **Formatting of repeated elements:** If DC checks are formatted as `DC 15` in most chapters, flag any variants (`DC15`, `Difficulty Class 15`, `a difficulty of 15`).
- **Oxford comma:** Should be present consistently throughout (the style established in copyedit).

### Tier 3: Layout Artefacts (flag for post-layout pass)
These won't be fixable until layout is complete, but log them now:

- **Orphaned sentences** — a single line left alone at the top of a page
- **Widows** — a single word on its own line at the end of a paragraph
- **Mid-paragraph section headers** — headers that appear in the wrong place in the text flow

Use `add_comment` with `type: "Annotation"` and prefix: `[POST-LAYOUT]` for these.

---

## 4. Reading Strategies

Proofreading requires reading differently from normal comprehension. Use these techniques:

**Read backwards by sentence** — start from the last sentence of each chapter and work forward. This defeats the brain's tendency to auto-correct errors it expects.

**Read the first and last sentence of every paragraph** — this catches the majority of errors with less reading time.

**Slow down on proper nouns** — these are where inconsistencies cluster.

**Check every number** — DC values, dice expressions, page references, week numbers, day numbers.

**Trust nothing the previous stages caught** — errors can be introduced during edits. Read fresh.

---

## 5. What Proofreading Does NOT Do

Do not:
- Rewrite sentences for style or clarity — that was Line Edit
- Change style decisions (Oxford comma, capitalisation rules) — those were set in Copyedit
- Flag things that are unusual but intentional — the author may have made a deliberate choice
- Improve weak prose — that ship has sailed

When in doubt, use `add_comment` with `type: "Question"` rather than silently changing something or flagging it as a definite error.
