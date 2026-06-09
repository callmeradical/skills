---
name: "copy-editing"
description: "Copyediting skill for the Book of Challenges manuscript. Uses the book-annotations MCP server to add structured annotations, run automated style checks, and suggest revisions. Trigger on: copy-edit, annotate manuscript, review chapter, style check."
---

# Copyediting Skill Profile & Execution Guide

## 1. Skill Overview & Objective

The core objective of copyediting is to optimize a manuscript for readability and mechanical accuracy without altering the author's intent, tone, or creative style. A copyeditor transforms an unstable draft into a polished, professional text ready for final layout and proofreading.

**This skill uses the `book-annotations` MCP server** running at `http://<tailscale-host>:3001/mcp` (or via stdio locally). All annotations, style checks, and revision suggestions are made through MCP tool calls — never by editing the manuscript directly.

---

## 2. MCP Server Tools

The following tools are available via the `book-annotations` MCP server. Use them for all annotation work.

### `check_style`
Run automated style analysis against one or all sections. This is always **Pass 1** — run it before manual review.

```json
{
  "sectionId": "optional — omit to check all sections",
  "limitPerSection": 10,
  "dryRun": false
}
```

Rules checked (configured in `settings.json`):
- **Fillers** — qualifiers and padding words (very, really, just, basically…) `[warning]`
- **Redundancies** — phrases where one word makes the other unnecessary (added bonus, end result…) `[error]`
- **Clichés** — overused figures of speech `[warning]`
- **Adverb Overuse** — -ly adverbs that weaken strong verbs `[warning]`
- **Passive Voice** — passive constructions where active is stronger `[warning]`
- **Weasel Words** — vague hedging language `[warning]`
- **Said-Bookisms** — dialogue tags that call attention to themselves `[info]`
- **Throat-Clearing** — introductory filler before the real sentence starts `[warning]`
- **Negative Form** — phrases better expressed in the positive `[info]`
- **Emotion-Telling** — naming emotions instead of showing them `[warning]`
- **Sentimentality** — overwrought emotional language `[warning]`
- **Writerly Voice** — self-conscious literary flourishes `[info]`
- **Over-Explaining** — restating what is already clear from context `[warning]`
- **Dialogue Name Overuse** — using a character's name too often in dialogue `[info]`
- **Exclamation Overuse** — excessive exclamation marks `[warning]`

### `suggest_revision`
Propose a specific rewrite for a passage. Creates a reviewable Revision annotation.

```json
{
  "sectionId": "chapter-id",
  "original": "exact verbatim passage from the manuscript",
  "replacement": "suggested rewrite",
  "reason": "explanation grounded in CMOS or the style guides",
  "ruleLabel": "e.g. Passive Voice",
  "author": "Copyeditor"
}
```

**Important:** `original` must match the manuscript text exactly (verbatim). The server verifies this and will error if not found.

### `add_comment`
Add a general annotation — for issues that require discussion or judgment rather than a direct fix.

```json
{
  "sectionId": "chapter-id",
  "text": "\"verbatim quote\"\n\nYour comment explaining the issue and suggesting a direction.",
  "type": "Feedback | Annotation | Style | Question",
  "quote": "verbatim passage to highlight",
  "author": "Copyeditor"
}
```

Use `quote` (or begin `text` with `"Quote"`) to trigger auto-highlighting in the web editor.

### `reply_to_comment`
Add a reply to an existing annotation thread.

```json
{
  "commentId": "comment-id",
  "text": "reply text",
  "author": "Copyeditor"
}
```

### `resolve_comment`
Mark a comment as completed or ignored.

```json
{
  "commentId": "comment-id",
  "status": "completed | ignored",
  "reply": "optional closing note"
}
```

### `get_comments`
Retrieve annotations for review or status checks.

```json
{
  "sectionId": "optional",
  "status": "todo | completed | ignored | all"
}
```

---

## 3. Core Responsibilities & Focus Areas

- **Mechanical Accuracy:** Grammar, syntax, punctuation, spelling per CMOS and Merriam-Webster.
- **Internal Consistency:** Fictional names, character traits, timelines, capitalization of game mechanics.
- **Clarity and Flow:** Clunky structures, passive voice, repetition, dangling modifiers, purple prose.
- **Style Guide Adherence:** Chicago Manual of Style (17th/18th Ed.) for fiction and TTRPG content.
- **TTRPG Conventions:** Bold game stats (Armor Class, DC, damage dice). Remove "points of" from damage expressions. Standardize "on a failure / on a success" phrasing.
- **Light Fact-Checking:** Consistent rule references, mathematical sums in tables, internal cross-references.

---

## 4. Execution Workflow

Work in three passes per section (or batch of sections).

### Pass 1: Automated Style Check
1. Call `check_style` with the target `sectionId` (or omit for all sections).
2. Review the summary output — note which rules fired and how many violations per section.
3. The server will have created `Style` annotations automatically. These appear in the web editor.

### Pass 2: Manual Macro Pass — Consistency & Flow
Read the section content. For each issue found:

- **Specific rewrite possible** → use `suggest_revision`
- **Judgment call / discussion needed** → use `add_comment` with type `Feedback` or `Question`
- **Continuity/consistency error** → use `add_comment` with type `Annotation`

Focus areas for this pass:
- Passive voice not caught by the automated check
- Clunky or run-on sentences
- POV / tense inconsistencies
- Character or location name inconsistencies
- TTRPG rule formatting (bold stats, damage dice notation, DC values)
- Purple prose and over-written passages

### Pass 3: Micro-Mechanical Pass
- Comma placement (Oxford comma — apply consistently)
- Dialogue tag punctuation (action + tag → period; speech + tag → comma)
- Number style (CMOS: spell out one through one hundred in prose; use numerals for dice, DCs, distances)
- Chapter header hierarchy
- Table and bullet list formatting consistency
- Internal cross-references accuracy

---

## 5. Practical Examples

### Passive Voice → Active
- **Before:** *The dungeon door was opened slowly by the rogue, who was trying to not make any noise because he knew that goblins were inside the next room.*
- **After:** *The rogue slowly opened the dungeon door, trying to remain silent; he knew goblins lurked in the next room.*
- **Tool:** `suggest_revision` with `ruleLabel: "Passive Voice"`

### TTRPG Rule Formatting
- **Before:** *The GM asks the player for a dexterity check (DC 15). If they fail, they take 2d6 points of fire damage.*
- **After:** *The GM asks the player for a **Dexterity check (DC 15)**. On a failure, the character takes **2d6 fire damage**.*
- **Tool:** `suggest_revision` with `ruleLabel: "TTRPG Formatting"`

### Filler Removal
- **Before:** *The village was really quite old, and it was actually rather famous for its somewhat unusual customs.*
- **After:** *The village was ancient, famous for its peculiar customs.*
- **Tool:** `suggest_revision` with `ruleLabel: "Fillers"`

---

## 6. Annotation Quality Standards

Every annotation must:
1. Include a verbatim `quote` from the manuscript (for highlighting in the web editor).
2. Name the specific rule or principle violated (CMOS chapter, style guide, or rule label).
3. Suggest a concrete direction — not just "this is wrong" but "consider X instead."
4. Use the appropriate `type`: `Style` for automated/rule-based, `Feedback` for prose judgments, `Question` for ambiguous cases, `Annotation` for continuity issues.

Avoid:
- Annotating the same phrase twice (deduplication is enforced by `check_style` but not by manual calls).
- Changing the author's voice or creative intent — flag it, don't rewrite it wholesale.
- Flooding a section with more than ~10 annotations; prioritize the most impactful issues.

---

## 7. Project Style Sheet (Book of Challenges)

Maintain consistency with these project-specific rules:

- **Capitalization:** Game mechanical terms are capitalized (Armor Class, Hit Points, Saving Throw, Difficulty Class, Challenge Rating).
- **Damage Notation:** `2d6 fire damage` — no "points of", no "damage points."
- **DC Formatting:** `DC 15` (no colon, no "of").
- **Dialect:** US English throughout.
- **Oxford Comma:** Yes.
- **Numbers in Prose:** Spell out one through one hundred; numerals for dice, DCs, distances, and stat values.
- **Chapter Titles:** Title case.
- **Dialogue Tags:** Lowercase after comma (`"Come in," she said.`); capitalize after period/em-dash for action beats.

---

## 8. Verification

After completing a batch of sections, verify coverage:

```bash
node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/verify_comments.js
```

Target: `Chapters with comments: 67 / 67 (100.0%)`
