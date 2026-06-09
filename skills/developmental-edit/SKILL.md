---
name: "developmental-edit"
description: "Developmental editing skill for the Book of Challenges manuscript. Focuses on macro structure, GM user experience, rules sequencing, and pacing — before any prose work begins. Uses the book-annotations MCP server to add structural annotations."
---

# Developmental Edit Skill

## 1. What Developmental Editing Is (and Is Not)

Developmental editing is the **first and heaviest** stage. You are reviewing the manuscript as a **system**, not as prose. You are not fixing grammar, word choice, or sentence rhythm — that is Copyedit and Line Edit territory.

**Your job:** Identify structural problems that would require cutting or reorganising material. Fixing a typo in a paragraph that might get cut is wasted effort.

**The output:** An editorial letter — a structured set of findings that the author can act on before the next stage begins. In this workflow, the editorial letter is delivered as `Annotation` type comments via the MCP server.

---

## 2. MCP Server Tools

Use `book-annotations` MCP server (stdio: `node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/mcp.js`).

### `get_pipeline_stage`
Call this first. Confirm the pipeline is in `developmental` stage before proceeding.

**Read `bookBrief` before annotating anything.** The response contains:
- `bookBrief.pitch` — what the book is
- `bookBrief.audience` — who it is for
- `bookBrief.outOfScope` — what the book deliberately excludes; **never suggest content in this category**
- `bookBrief.constraints` — non-negotiable author decisions; **never override these**

If these fields are empty, stop and ask the author to fill in the Book Brief in the pipeline view first.

Every structural finding you add must be consistent with the book brief. For example: if `outOfScope` states the book is system-agnostic, do not recommend adding game-mechanical specificity (DCs, spell saves, stat blocks, action economy).

### `add_comment`
All developmental findings go through `add_comment` with `type: "Annotation"`.

```json
{
  "sectionId": "chapter-id",
  "text": "\"verbatim quote if applicable\"\n\nStructural finding: description of the problem and recommended action.",
  "type": "Annotation",
  "quote": "verbatim passage if referencing a specific point",
  "author": "Developmental Editor"
}
```

### `get_comments`
Use to review existing annotations before adding new ones (avoid duplication).

### `set_pipeline_stage`
When the full editorial pass is complete:
```json
{ "stageId": "developmental", "status": "complete", "note": "Editorial letter delivered — X structural findings across Y chapters." }
```

---

## 3. The Five Structural Lenses

Evaluate the manuscript through each of these lenses in order. They are cumulative — each builds on the previous.

### Lens 1: Information Architecture (GM User Experience)
A GM should be able to read this book in order and encounter every concept **before** it is required at the table.

- **Cross-reference audit:** Does any chapter instruct the GM to reference a concept explained later? Flag every forward dependency.
- **Baseline mechanics:** Are all foundational rules established early enough that Chapters 1–5 require no lookups?
- **Progressive complexity:** Do challenges escalate in difficulty and mechanical depth in a logical order?
- **Onboarding:** Does the introduction adequately prepare a new GM for the system before Chapter 1?

**Annotation format:**
> "Structural dependency: Chapter X references [concept] which is not introduced until Chapter Y. Move [concept] introduction earlier, or add a brief definition in Chapter X."

### Lens 2: Thematic Coherence
Each part/theme section should have a clear identity that unifies its chapters.

- Does each Part introduction clearly set up the theme that follows?
- Do the chapters within a Part reinforce each other, or do they feel disconnected?
- Are theme transitions between Parts smooth, or abrupt?
- Does the manuscript have a clear arc from beginning to end (early chapters for new GMs → later chapters for experienced ones)?

### Lens 3: Pacing and Density
- Are there clusters of similar challenge types that create fatigue?
- Are mechanical chapters balanced with narrative/lore chapters?
- Is any single chapter overloaded with rules that should be split across multiple sessions?
- Are any chapters so thin they feel like filler?

**Flag:** Chapters that are significantly shorter or longer than the average without a clear reason.

### Lens 4: Internal Consistency
This is distinct from copyedit consistency (spelling/capitalisation). Look for:
- **Rule contradictions:** Does the same mechanic work differently in two chapters without explanation?
- **Tone inconsistencies:** Does a chapter break the established voice (e.g., suddenly becomes preachy or overly academic in a book that's otherwise conversational)?
- **Promise fulfilment:** If the introduction promises a specific type of content, does the manuscript deliver it?

### Lens 5: Completeness
- Are there obvious gaps — topics a 52-week GM challenge should cover that are entirely absent?
- Are appendices, worksheets, or reference materials sufficient for the book's stated purpose?
- Does the Table of Contents accurately reflect what the book delivers?

---

## 4. Annotation Standards for This Stage

Every developmental annotation must:

1. **Name the lens** it belongs to (Information Architecture, Pacing, etc.)
2. **Describe the problem** specifically — not "this chapter is weak" but "Chapter 14 introduces the concept of Session Zero without defining it, but Session Zero preparation is not covered until Chapter 31"
3. **Recommend a specific action:** Move, Cut, Expand, Split, Merge, or Reorder
4. **Avoid prose-level suggestions** — if you notice a cliché while reading, note it mentally but do not annotate it here; that is Line Edit territory

**Type:** Always `"Annotation"` for structural findings.

---

## 5. The Editorial Letter Format

After completing the pass, call `add_comment` on the Introduction chapter (`00_Intro` or equivalent) with a summary editorial letter:

```
type: "Annotation"
text: "EDITORIAL LETTER — Developmental Pass\n\n
[Date]\n\n
## Summary\n
[2-3 sentences on overall structural health]\n\n
## Priority Findings\n
1. [Most critical structural issue]\n
2. [Second most critical]\n
...\n\n
## Full findings are annotated inline across [N] chapters."
```

---

## 6. What to Leave for Later Stages

Do NOT annotate in this stage:
- Grammar, spelling, punctuation → Copyedit
- Sentence rhythm, word choice, clichés → Line Edit
- Typos in final PDF → Proofread
- Cultural representation issues → Sensitivity Edit
- Whether a challenge works at the table → Playtest
