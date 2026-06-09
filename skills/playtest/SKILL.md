---
name: "playtest"
description: "Playtest / alpha-reader skill for the Book of Challenges manuscript. Evaluates challenges for mechanical clarity, time-appropriateness, and table usability as a GM tool. Uses the book-annotations MCP server."
---

# Playtest Skill

## 1. What Playtesting Is

For a GM challenge journal, playtesting functions as a specialised developmental edit focused on **mechanical usability at the table**. You are not evaluating the prose quality or grammar — you are asking: *Can a real GM actually run this challenge effectively?*

**The reader persona:** Imagine you are a busy GM with 2–3 hours of prep time per week. You have picked up this book to make your sessions better. You are reading a chapter for the first time 20 minutes before your session.

Does this chapter work for that person?

---

## 2. MCP Server Tools

Use `book-annotations` MCP server (stdio: `node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/mcp.js`).

### `get_pipeline_stage`
Call first. Confirm `playtest` stage is active.

### `add_comment`
Use `type: "Feedback"` for usability observations and `type: "Question"` for mechanical ambiguities.

```json
{
  "sectionId": "chapter-id",
  "text": "\"verbatim passage if applicable\"\n\nPlaytest note: [specific usability observation or mechanical question].",
  "type": "Feedback",
  "quote": "specific passage if relevant",
  "author": "Playtester"
}
```

### `suggest_revision`
Use when a mechanical clarification has a clear correct form:

```json
{
  "sectionId": "chapter-id",
  "original": "ambiguous mechanical text",
  "replacement": "clarified version",
  "reason": "Mechanical ambiguity — GMs need a clear ruling here.",
  "ruleLabel": "Mechanical Clarity",
  "author": "Playtester"
}
```

### `set_pipeline_stage`
On completion: `{ "stageId": "playtest", "status": "complete" }`

---

## 3. The Playtester's Evaluation Framework

### Test 1: The 20-Minute Prep Test
Read the chapter as if you have 20 minutes before your session.

- Can you understand the challenge immediately, or do you need to re-read sections?
- Are there any terms used without being defined?
- Could you run this challenge without any additional resources beyond this book?
- Is there anything you'd need to decide on the fly that the book should have answered for you?

**Flag:** Any point where you paused, re-read, or felt uncertain. These are friction points.

### Test 2: Mechanical Completeness
Every challenge that has a mechanical component should specify:

- **The trigger:** What situation causes this challenge to begin?
- **The stakes:** What does success achieve? What does failure cost?
- **The resolution:** How does the GM know when the challenge is over?
- **The mechanics:** If dice are involved — what check, what DC, what skill? If roleplay — what does the GM listen for to determine success?

**Flag:** Any of these four elements that are missing or ambiguous.

### Test 3: Time Appropriateness
The book is a *52-week challenge journal*. Each challenge should be completable in a single session by a group with a real-world GM's time constraints.

- Does this challenge have a realistic scope for a 3–4 hour session?
- Does it require significant prep beyond reading the chapter?
- Is there an obvious way to scale it (shorter/longer) for different groups?

**Flag:** Challenges that would realistically require multiple sessions without offering natural break points, or challenges that could be resolved in 10 minutes without enough substance.

### Test 4: Player Agency
A good challenge gives players meaningful choices.

- Does the challenge have at least two viable approaches?
- Can different player types (combat, roleplay, puzzle-solving) each contribute something?
- Is there a way for a creative player to find an unexpected solution?
- Does the challenge feel like it has a single "correct" answer the GM is waiting for?

**Flag:** Challenges that feel like a corridor with one exit, or that assume a specific party composition.

### Test 5: Broken Mechanics
Look for mechanics that can be trivialised or exploited:

- Is there a DC so low that any moderately skilled character auto-succeeds?
- Is there a DC so high that failure is almost guaranteed?
- Does the challenge break if a player has a specific spell, ability, or item?
- Are there obvious edge cases the text doesn't address?

**Flag as `Question`:** Mechanical edge cases where the correct ruling isn't clear from the text.

---

## 4. Special Considerations for This Manuscript

The Book of Challenges is a **daily/weekly challenge journal** structured around themes. Additional questions:

- Does the chapter's challenge actually exemplify the stated theme of its Part? Or does it feel misplaced?
- Are the Day 1–7 tasks genuinely distinct from each other, or do some feel like repetitions?
- Is the improvisation guidance at the end of each chapter genuinely useful — or is it so generic it could appear in any chapter?

---

## 5. Feedback Tone

Playtest feedback should be practical and specific:

- "A GM reading this for the first time won't know whether [X] means [interpretation A] or [interpretation B]" — not "this is unclear"
- "This challenge would likely take 5+ hours at a typical table, well beyond a single session" — not "this is too long"
- "A player with *Pass Without Trace* trivialises the stealth requirement completely" — not "this could be broken"

The goal is to hand the author a specific problem they can solve.
