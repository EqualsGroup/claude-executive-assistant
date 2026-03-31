---
name: meeting-prep
description: >
  Generate structured meeting prep docs using memory context.
  Usage: /meeting-prep [meeting-type]
  Examples: /meeting-prep standup, /meeting-prep 1:1
  Run without arguments to auto-detect from your calendar.
  Also triggers on "prep me for", "meeting with", "1:1 with", "prepare for".
---

## Instructions

Generate a structured meeting prep document tailored to the meeting type and participants. The skill is generic — all meeting-specific behaviour comes from the meeting's definition in `meetings.md`.

### Phase 1: Identify the meeting

**If arguments provided** (e.g. `/meeting-prep standup`, `/meeting-prep 1:1`):
- Match the argument against meeting definitions in `$SECRETARY_ROOT/memory/meetings.md` by section heading, purpose, or keywords
- For meetings that need participants (e.g. 1:1): check today's calendar for the next matching event and extract attendees from it — never require the user to specify a name

**If no arguments** (just `/meeting-prep`):
1. Fetch today's calendar events
2. Find the **next upcoming meeting** (closest start time that hasn't ended). Sort by start time ascending — the earliest meeting that hasn't ended wins. Do NOT skip meetings because they seem simple or are recurring — every meeting type defined in meetings.md needs prep.
3. Match it against `meetings.md` definitions using a two-step process:
   - **Keywords** (subject match): check the calendar event's subject against each definition's Keywords (case-insensitive substring match). If a keyword matches, that definition is selected.
   - **Detection rules** (structural match): if no keyword matches, apply each definition's Detection rules (e.g. attendee count for 1:1s). This catches meetings that don't have keywords in their title.
   - If both a keyword match and a detection rule match exist, prefer the keyword match (more specific).
4. If no match, generate a sensible prep doc from context
5. Tell the user which meeting was detected and proceed

**If no upcoming meetings found**, read `meetings.md` and list available meeting types (from section headings and Keywords) as a quick help.

Determine from the matched meeting and calendar event:
- **Participants** — from the calendar event attendees, cross-referenced with `$SECRETARY_ROOT/memory/people/`
- **Topic/purpose** — from the meeting definition, or inferred from participant context

### Phase 2: Gather context (parallel)

Read all relevant memory files from `$SECRETARY_ROOT/` in parallel:
- `memory/meetings.md` — the meeting's definition: standing topics, attendees, data sources, output template, prep notes
- `memory/people/` — files for all participants (working style, coaching points, recent context, performance review insights)
- `memory/projects.md` — active initiatives relevant to the participants or topic
- `memory/dynamics.md` — sensitivities involving the participants, team dynamics, political context
- `memory/my-work.md` — current priorities, pending items involving the participants

### Phase 3: Fetch data sources

The meeting definition in `meetings.md` specifies what data the prep needs under a **"Data sources"** section. Common data sources and how to fetch them:

| Data source | How to fetch |
|-------------|-------------|
| `full-sync` | Run the `/sync` skill to refresh all memory files from external sources before fetching other data. Ensures the prep is based on up-to-date context. Heavy — only declare when the meeting needs full freshness (e.g. standup) |
| `messaging-activity` | ~~messaging search for messages the user sent in the relevant time window |
| `code-activity` | ~~code connector: commits pushed, PRs opened/merged/reviewed, reviews given. Fetch using the auth method configured in `sync/sources.md` with appropriate date filters |
| `code-open-prs` | ~~code connector: list all open PRs authored by the user. **For each PR, also fetch review status** and latest commit date. Flag stale reviews where commits were pushed after the last review (likely means feedback was addressed, awaiting re-review) |
| `calendar` | ~~calendar search for the specified time window (e.g. today, past week) |
| `previous-output` | Read the most recent `$SECRETARY_ROOT/outputs/meeting-prep/*-[meeting-name].md`. Check its age — see staleness handling in the meeting definition's prep notes |

Launch data fetches as parallel subagents where possible. Each subagent is **research-only — do NOT edit any files**.

**PR status is not the full picture.** ~~code review status is a point-in-time snapshot. CHANGES_REQUESTED doesn't mean the author hasn't addressed the feedback. Cross-reference review status with `my-work.md` notes and ~~messaging conversations for the real state. The narrative from memory always takes precedence over the raw API status.

If the meeting definition has no data sources section, skip this phase — the memory context from Phase 2 is sufficient.

### Phase 4: Generate prep document

Use the meeting's **output template** from `meetings.md` as the structural foundation. Fill each section using the gathered context and fetched data.

If the meeting has no template in `meetings.md`, generate a sensible prep doc from the context. Cover what's relevant — participants, topics to raise, topics they may raise, sensitivities, approach notes. Use the **Meeting Prep Templates** section in `meetings.md` for structural inspiration if a matching template type exists.

**Enrich with cross-references:**
- Flag sensitivities from `dynamics.md` that affect any participant or topic
- For each participant, check their file in `$SECRETARY_ROOT/memory/people/` — surface coaching points, working style, recent interactions relevant to this meeting
- Note upcoming deadlines or blockers from `projects.md` and `my-work.md`
- If a previous output exists, highlight what changed since then (new blockers, completed items, shifted priorities)

### Phase 5: Save and present

1. **Save first** to `$SECRETARY_ROOT/outputs/meeting-prep/YYYY-MM-DD-[meeting-name].md`
2. **Then present** key points inline for quick reference

## Rules

- **The meeting definition drives the prep.** All meeting-specific logic, templates, data sources, and output formats live in `meetings.md`. This skill is the generic engine.
- **Always check dynamics.md** — every meeting has political context. Surface sensitivities proactively.
- **Always check my-work.md** — don't miss action items or follow-ups involving the participants.
- **Be specific** — reference actual events, dates, and quotes from memory, not generic advice.
- **Flag landmines** — if dynamics.md shows a sensitivity involving this person, call it out explicitly with guidance on how to navigate.
- **Keep it scannable** — bullet points, not paragraphs. The user reads this 5 minutes before the meeting.
- **Save before presenting** — don't risk losing the document if the session ends.
- **Use previous outputs** — the `$SECRETARY_ROOT/outputs/meeting-prep/` directory is your historical record. Use it for planned-vs-actual comparisons, continuity, and tracking commitments across meetings.
