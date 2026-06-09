---
name: "sensitivity-edit"
description: "Sensitivity editing skill for the Book of Challenges manuscript. Reviews for cultural inaccuracies, harmful stereotypes, and problematic representations in a TTRPG context. Uses the book-annotations MCP server."
---

# Sensitivity Edit Skill

## 1. What Sensitivity Editing Is

A sensitivity editor reads through the manuscript to identify content that may:
- Rely on harmful real-world stereotypes mapped onto fictional cultures or factions
- Represent marginalised identities, cultures, or groups in ways that are reductive, othering, or harmful
- Handle sensitive themes (trauma, violence, exploitation, mental illness) in ways that lack care or nuance
- Contain language that has a specific harmful connotation the author may not be aware of

**This is not censorship.** The goal is to help the author produce a more thoughtful, inclusive product that resonates with a wider audience without causing unintended harm.

**In TTRPG specifically:** Fictional cultures, monsters, and factions often map — consciously or not — onto real-world groups. The sensitivity editor's job is to surface those mappings and help the author make intentional choices about them.

---

## 2. MCP Server Tools

Use `book-annotations` MCP server (stdio: `node /Users/lars/Documents/0_Inbox/book_of_challenges/web_editor/mcp.js`).

### `get_pipeline_stage`
Call first. Confirm `sensitivity` stage is active.

### `add_comment`
All sensitivity findings use `type: "Question"` — these are raised as questions for the author to reflect on, not corrections to be applied automatically.

```json
{
  "sectionId": "chapter-id",
  "text": "\"verbatim passage\"\n\nSensitivity note: [observation]. [Question for the author to consider]. [Optional: alternative framing to consider.]",
  "type": "Question",
  "quote": "the specific passage",
  "author": "Sensitivity Editor"
}
```

### `set_pipeline_stage`
On completion: `{ "stageId": "sensitivity", "status": "complete" }`

---

## 3. Review Lenses

### Lens 1: Fictional Cultures and Factions
When the manuscript creates fictional cultures (underground factions, city guilds, tribal structures, etc.):

- Do any fictional cultures map uncomfortably closely onto specific real-world ethnic, religious, or indigenous groups?
- Are "evil" or antagonist cultures given any depth, motivation, or humanity — or are they monolithic threats?
- Does the manuscript treat fictional cultures as monolithic (all members of X culture are Y) or as containing internal diversity?
- Are sacred or spiritual practices of fictional cultures treated with respect, or used as exotic flavour?

**Particular TTRPG risk:** Underground/wilderness cultures, nomadic peoples, and "primitive" civilisations that echo colonial tropes.

### Lens 2: Representation of Identities
When the text references (explicitly or by implication) real-world identities:

- Are characters with marginalised identities (if present) given agency and depth, or used as props?
- Does the text assume a default audience of a specific demographic without acknowledging other players?
- Are disability, mental illness, or neurodivergence referenced? If so, how? Are they portrayed with nuance or used as shorthand for villainy/weakness?

### Lens 3: Violence and Sensitive Themes
A GM challenge book will involve conflict, danger, and difficult themes. The question is *how* they are handled:

- Are traumatic themes (loss, captivity, exploitation, abuse) handled with appropriate weight — or treated as flavourful background?
- Does any content risk trivialising real-world trauma?
- Are there content warnings that a GM might need to share with their table before running a particular challenge?

Flag these with `type: "Question"` asking whether a **content warning** recommendation should be added to the chapter.

### Lens 4: Language
Specific words and phrases that carry unintended weight:

- Terms borrowed from specific cultures or languages that are used outside their cultural context (appropriation)
- Euphemisms for groups that the group itself has moved away from
- Metaphors that inadvertently invoke race, disability, or gender in a negative frame

Do not over-flag — language evolves and context matters enormously. Raise as a `Question` with context, not a directive.

---

## 4. Tone of Annotations

Sensitivity notes must be:
- **Curious, not accusatory** — "I noticed this passage could be read as..." rather than "this is harmful"
- **Specific** — point to the exact passage and explain the concern precisely
- **Constructive** — offer a question or direction, not just a problem
- **Aware of authorial intent** — acknowledge that the intent may be positive even when the effect is not

The author has the final word on all sensitivity feedback. Your job is to surface blind spots, not to make decisions.

---

## 5. Scope for This Manuscript

The Book of Challenges is a TTRPG GM resource. Key areas of focus:

- **Challenge locations:** Are sacred sites, burial grounds, or culturally significant locations used as generic adventure backdrops?
- **NPC archetypes:** Do any recurring NPC types (merchants, guards, villains) reinforce harmful stereotypes?
- **Challenge themes:** Do any weekly challenges involve content (slavery, torture, sexual violence) that requires explicit content warnings?
- **Accessibility:** Does the book assume able-bodied players and GMs, or is it inclusive in its language about participation?
