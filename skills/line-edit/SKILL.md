---
name: "line-edit"
description: "Line editing skill for the Book of Challenges manuscript. Focuses on artistry, voice, and prose elevation — line by line. Runs after developmental editing is complete. Uses the book-annotations MCP server."
---

# Line Edit Skill

## 1. What Line Editing Is (and Is Not)

Line editing is about **artistry, not correctness**. You are reading every sentence and asking: *Does this sing? Does it land? Does it sound like the author at their best?*

- **Not copyediting** — you are not enforcing CMOS rules or fixing comma splices
- **Not developmental editing** — the structure is already locked; you are not reorganising chapters
- **Not proofreading** — you are not the last set of eyes; there will be more passes after this

**The goal:** Every sentence should be as punchy, evocative, and specific as it can be while remaining true to the author's voice.

---

## 2. MCP Server Tools

Use `book-annotations` MCP server (stdio: `node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/mcp.js`).

### `get_pipeline_stage`
Call this first. Confirm `line` stage is active.

### `suggest_revision`
The primary tool for this stage. Every line edit should propose a specific rewrite:

```json
{
  "sectionId": "chapter-id",
  "original": "exact original passage",
  "replacement": "your suggested rewrite",
  "reason": "Explanation grounded in the principle being applied",
  "ruleLabel": "e.g. Sentence Rhythm / Purple Prose / Voice",
  "author": "Line Editor"
}
```

### `add_comment`
Use for issues where a rewrite requires the author's creative input rather than a direct substitution:

```json
{
  "type": "Feedback",
  "text": "\"original passage\"\n\nLine note: explanation of the issue and direction to consider.",
  "author": "Line Editor"
}
```

### `set_pipeline_stage`
On completion: `{ "stageId": "line", "status": "complete" }`

---

## 3. The Six Line-Edit Lenses

### Lens 1: Sentence Rhythm and Variety
Monotony kills engagement. Read paragraphs aloud (or simulate doing so).

- **Same-length sentences** in a row create a numbing drone. Break them up.
- **All long sentences** exhaust the reader. Insert short punches.
- **All short sentences** feel choppy and breathless. Add connective tissue.
- **The power position** is the end of a sentence or paragraph — the most important word should land there, not be buried in the middle.

**Suggest a rewrite** that varies the rhythm without changing the meaning.

### Lens 2: Purple Prose and Over-Writing
This is especially common in TTRPG writing, which tends toward melodrama.

Flag passages that:
- Use three adjectives where one would do
- Describe emotion rather than action ("he felt a deep sense of loss" vs "he picked up her empty chair")
- Stack metaphors until they collapse under their own weight
- Use "indelible," "tapestry," "fabric of," "the very essence of" or similar stock grandiosity

**Suggest_revision** with a tighter, more specific version.

### Lens 3: Clichés and Stock Phrases
A cliché is a phrase so familiar it slides past the reader without registering. In TTRPG writing:
- "Epic tales," "legendary adventures," "boundless imagination"
- "The possibilities are endless"
- "At the end of the day"
- "Not just X, but Y" constructions (flag especially; common in this manuscript)

**Replace with something specific and fresh.** If the author means "players will surprise you," write that — not "the possibilities are endless."

### Lens 4: Voice Consistency
The manuscript should have a consistent authorial voice — knowledgeable but conversational, enthusiastic without being breathless.

Flag passages that feel:
- **Too academic** (dry, passive, over-qualified)
- **Too breathless** (exclamation marks, hyperbole, "incredible!", "amazing!")
- **Tonally inconsistent** with surrounding paragraphs

Use `add_comment` with `type: "Feedback"` for voice notes — these require author judgment, not a direct substitution.

### Lens 5: Transitions and Flow
Poor transitions make a reader feel dropped between ideas.

- **Between sentences:** does each sentence follow logically from the last, or does it feel like a non-sequitur?
- **Between paragraphs:** is there a connective thread, or does each paragraph restart from zero?
- **Between sections:** does the end of a section prepare the reader for what comes next?

**Suggest bridge sentences** or restructured paragraph openings.

### Lens 6: Specificity
Vague writing loses the reader. Strong writing is precise.

- "Some monsters" → "three goblins and their worg"
- "A difficult challenge" → "a DC 18 Persuasion check under time pressure"
- "Players will enjoy this" → "players who love roleplay-heavy sessions will remember this one"

Where a passage is vague, flag it with a `Feedback` comment asking the author to be specific, or suggest a specific concrete version if one is inferrable.

---

## 4. What Makes a Good Line-Edit Suggestion

Every `suggest_revision` must:
1. **Preserve the author's meaning** — you are elevating the prose, not rewriting the content
2. **Be grounded in a principle** — state which lens your suggestion comes from in the `reason` field
3. **Be genuinely better** — if you're not confident the rewrite is an improvement, use `add_comment` instead
4. **Not homogenise voice** — your suggestion should sound like the author at their best, not like you

---

## 5. Prioritisation

This is an expensive stage — do not annotate every imperfect sentence. Focus on:

1. **Opening sentences** of chapters and sections (first impression)
2. **Closing sentences** of chapters (last impression)
3. **Pull quotes and callouts** (most-read text)
4. **Passages with multiple issues** (highest return on effort)
5. **Sections flagged during developmental edit** as tone inconsistencies

A chapter with 2–4 strong line edits is more valuable than one with 15 marginal suggestions.
