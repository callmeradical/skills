---
name: daily-briefing
description: This skill should be used when the user asks for a "daily briefing", "morning briefing", "morning summary", "what's on today", "daily update", "brief me", or invokes /briefing. Gathers news, calendar, reminders, tasks, and messages into a single summary.
trigger: /briefing
---

# Daily Briefing

Compile a concise morning briefing from nine sources. Present results in a single structured response — no preamble, no sign-off. Automatically create Things 3 tasks for any identified action items.

## Procedure

Execute all data-gathering steps in parallel where possible, then synthesize into the output format below.

### 1. Weather

Determine location: default is South Jersey (Woolwich Township NJ). But first check today's calendar — if travel is indicated (flights, hotel, out-of-town events), use that destination instead.

```bash
curl -s "wttr.in/{location}?format=%l:+%c+%t+%h+%w\n" 
curl -s "wttr.in/{location}?1&Q&T"
```

Present current conditions and today's forecast (morning/noon/evening/night).

### 2. News — 1440 Daily Digest

Find the most recent email from "1440 Daily Digest" using himalaya:

```bash
himalaya envelope list --folder INBOX | grep -i "1440"
```

Read the message by its ID:

```bash
himalaya message read <ID>
```

Extract only the most interesting 4-6 topics. For each topic, write 1-3 sentences capturing the key facts. Skip ads, promotions, and filler sections. Use editorial judgment — prioritize surprising, consequential, or broadly relevant stories.

### 2. Calendar — Today's Schedule

List today's calendar events using calendula. Check all calendars for items occurring today:

```bash
calendula items list <calendar-id>
```

Run for each calendar returned by `calendula calendars list`. Filter to items with today's date. Present as a timeline sorted by start time.

### 3. Reminders — Due Today

List reminders from all lists:

```bash
reminders show <list-name>
```

Run for each list returned by `reminders show-lists`. Include reminders due today or overdue. **Exclude the "Daily" list entirely** — those are daily routines and not worth reporting. Present grouped by list name.

### 4. Tasks — Things 3

Pull today's tasks (includes overdue items, matching the Things Today view):

```bash
things-cli today
```

Present as a simple list grouped by area/project.

### 5. Email Inbox — Action Required

Scan recent inbox emails beyond the 1440 digest:

```bash
himalaya envelope list --folder INBOX
```

Review the most recent ~20 envelopes. Skip newsletters, notifications, and marketing. For emails that require a response or action, summarize the ask in 1-2 sentences and note the sender.

### 6. Messages — Beeper

Fetch recent unread chats using the Beeper MCP tools:

- Use `mcp__beeper__search_chats` with `unreadOnly: true` and `inbox: "primary"` to find chats with unread messages
- For each unread chat, use `mcp__beeper__list_messages` to get recent messages
- Summarize each conversation in 1-2 sentences
- Flag any messages that clearly require a response or action

### 7. GitHub — PRs & Reviews

Check for open PRs and review requests:

```bash
gh search prs --review-requested=@me --state=open
gh search prs --author=@me --state=open
```

Report:
- PRs awaiting your review (repo, title, age)
- Your open PRs (repo, title, status — checks passing/failing, review state)

### 8. Upcoming Gifts — Yearly Reminders

Check the Yearly reminders list for anything due within the next 7 days:

```bash
reminders show Yearly
```

Flag any gifts or occasions coming up in the next week so there's time to act.

### 9. Archive Inbox

After all inbox emails have been read and summarized, archive them to keep the inbox clean:

```bash
himalaya flag add --folder INBOX <ID> seen
himalaya message move --folder INBOX <ID> Archive
```

Run for each email that was summarized in step 5. Do NOT archive the 1440 Daily Digest (already handled in step 1). Only archive after the briefing content has been fully assembled — never before summarizing.

## Action Item Creation

After gathering all data, identify action items from **email inbox** and **Beeper messages** — anything that requires a response, decision, or follow-up.

For each action item, create a task in Things 3 via URL scheme using `reveal=false` to skip the quick-entry dialog:

```bash
open "things:///add?title={URL-encoded title}&notes={URL-encoded notes}&when=today&reveal=false"
```

- **title**: concise action description (e.g., "Reply to Steven re: music video final cut")
- **notes**: include source context — who sent it, which platform (email/Beeper), and enough detail to act without re-reading the original message

Report each created task in the Action Items section of the briefing.

## Output Format

Present the briefing using this exact structure:

```
# Daily Briefing — {date}

## Weather
{location}: {conditions}, {temp}. High {high}, Low {low}. {precipitation if any}.

## News
- **{Topic}** — {1-3 sentence summary}
- ...

## Schedule
- {time} — {event} ({calendar})
- ...
(or "Nothing scheduled." if empty)

## Reminders
**{List name}**
- {reminder} (due {date/time})
- ...
(or "No reminders due." if empty)

## Tasks
- {task} ({area/project})
- ...
(or "No tasks for today." if empty)

## Inbox
- **{Sender}** — {subject}: {1-2 sentence summary}. {Action needed: yes/no}
- ...
(or "Nothing actionable." if empty)

## Messages
- **{Chat name}** — {summary}. {Action needed: yes/no}
- ...
(or "No unread messages." if empty)

## GitHub
**Review Requested:**
- {repo}#{number} — {title} (opened {age})
- ...
(or "No reviews requested." if empty)

**Your Open PRs:**
- {repo}#{number} — {title} ({checks status}, {review state})
- ...
(or "No open PRs." if empty)

## Upcoming
- {gift/occasion} — due in {N} days
- ...
(or nothing if no gifts/occasions within 7 days)

## Action Items
Items below were automatically added to Things 3:
- {action description} (source: {email/beeper/reminder}) — added to Things
- ...
(or "No action items identified." if empty)
```

## Email the Briefing

After presenting the briefing in the terminal, also send it as an HTML-formatted email to lars@cromleylabs.com.

Write the full briefing as a styled HTML document to a temp file, then send via himalaya:

```bash
cat /tmp/daily-briefing.mml | himalaya message send
```

Use raw MIME format (NOT himalaya MML — MML does not produce correct Content-Type headers for HTML):

```
From: lars@cromleylabs.com
To: lars@cromleylabs.com
Subject: Daily Briefing — {date}
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="briefing-boundary"

--briefing-boundary
Content-Type: text/plain; charset=utf-8

{plaintext summary fallback}

--briefing-boundary
Content-Type: text/html; charset=utf-8

{html content}

--briefing-boundary--
```

Generate a unique boundary per send (e.g., `briefing-$(date +%s)`). Write to `/tmp/daily-briefing.eml` and pipe to `himalaya message send`.

### HTML Style Guidelines

Use inline CSS for maximum email client compatibility. Design:

- Clean, minimal layout — white background, dark text
- Max width 640px, centered
- Section headers: bold, dark color, bottom border
- Lists: no bullets, subtle left border for grouping
- Action items: highlighted with a warm accent color (e.g., amber/orange background)
- News items: topic in bold, summary in regular weight
- Schedule: time in monospace, event name beside it
- Responsive — readable on mobile
- No external assets, images, or web fonts

## Important Notes

- Run data-gathering commands in parallel to minimize latency.
- For the 1440 digest: if today's edition hasn't arrived yet, use the most recent one available.
- For calendar: today is determined by the system clock, not hardcoded.
- Keep the entire briefing scannable — brevity over completeness.
