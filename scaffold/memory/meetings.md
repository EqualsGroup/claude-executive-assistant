*Last synced: never*

# Meetings

## Recurring Meetings

### 1:1s
**Keywords:** 1:1, 1-1, one-on-one
**Detection:** Calendar event with exactly 2 attendees (user + one other). Identify the other person from attendees and look them up in `memory/people/` to determine the relationship.

**Purpose:** 1:1s are **personal coaching sessions**, not status updates or technical meetings. They exist to build trust, discuss personal challenges, give/receive feedback, and improve how someone works — not what they're working on. Project status belongs in standup or sprint planning.

**Data sources:** `previous-output`, `calendar` (recent 1:1s with this person)

**Prep notes:**
- Focus on the person, not the project. How are they feeling? What's frustrating them? What's going well personally?
- Check their file in `memory/people/` for: coaching points, working style, recent interactions, performance review insights
- Check `dynamics.md` for sensitivities involving this person
- Review previous 1:1 output for follow-ups and commitments made
- Think about what feedback you want to give OR receive
- Consider: is there something they need to hear that nobody else will say?

**Output template:**
```
## How they're doing
- [Observations from recent interactions, Slack tone, workload signals]
- [Feeling valued check — last known sentiment, any changes?]

## Topics to discuss
- [Personal challenges, frustrations, growth areas — NOT project status]
- [Follow-ups from last 1:1]

## Feedback to give
- [Specific, evidence-based — what you observed and its impact]

## Feedback to ask for
- [What you want their perspective on about YOUR work/approach]

## Coaching focus
- [Current development area from people.md]

## Sensitivities
- [Anything from dynamics.md that affects this conversation]
```

#### [Name]
<!-- Per-person overrides. The generic template above handles structure — only add person-specific context here. -->
- **Coaching focus:** [current development area]
- **Feeling valued:** [last known sentiment — update after each review cycle]

<!-- Add one entry per direct report -->

---

### Daily

#### Daily Standup
**Purpose:** Quick daily update — what you did yesterday, what you're doing today, blockers
**Cadence:** Daily
**Keywords:** standup, daily
**Detection:** Calendar event whose subject contains "standup" or "daily" (case-insensitive).

**Data sources:** `full-sync`, `slack-activity` (since last working day), `github-activity` (since last working day), `github-open-prs`, `calendar` (today), `previous-output`

**Prep notes:**
- "Since last working day" = 1 day on Tue–Fri, 3 days on Monday (captures Friday). Adjust the search window accordingly.
- **Previous output staleness:** Check the date in the most recent `outputs/meeting-prep/*-standup.md` filename:
  - **< 3 working days old** — reliable baseline. Use for planned-vs-actual diff.
  - **3–5 working days old** — use cautiously. Cross-reference with `my-work.md`.
  - **> 5 working days old** — treat as stale. Add a **Catch-up** section summarising what changed since the last daily (compare `my-work.md` current state against the old snapshot).
  - **No previous output** — skip planned-vs-actual diff, note this is the first run.
- Compare last working day's actual activity against previous output's "Today" section — flag `[not touched]` items (planned but no evidence of progress) and `[unplanned]` items (work that wasn't in the plan)
- Track blocker age: count days since first appearance in my-work.md. Flag 3+ days with `[Xd]`, suggest escalation for 5+ days.
- Flag stale PRs: any open PR authored by the user that's been open 3+ days. Include review status — if CHANGES_REQUESTED but author pushed commits after the review, note "awaiting re-review" not "needs changes"
- Cross-reference PR review status with `my-work.md` and Slack for the real narrative — raw GitHub status can be misleading
- Use short memorable names for work items, not ticket numbers (e.g. "Intermediary fix" not "TN-14990")
- The Standup section is what the user reads aloud — 3-5 bullets max, grouped by theme not individual items
- For each meeting in "Meetings Today", cross-reference attendees against `memory/people/` (coaching points, working style) and `memory/dynamics.md` (sensitivities)

**Output template:**
```
## Standup
- [3-5 bullets: what you'd actually say out loud]

---

## Catch-up (only if previous output > 5 working days old)
- [Key changes since last daily]

## Yesterday
- [What was done, grouped logically]
- [Flag [not touched] and [unplanned] items vs previous plan]

## Today
- [Planned work from my-work.md Now tier, with blocked items marked]

## Meetings Today (only if any scheduled)
- [HH:MM — Meeting name — attendees, key context from memory/people/ and memory/dynamics.md]

## Blockers
- [Blockers with age, e.g. "IAT rework [3d] — awaiting AJ response"]
- [Stale PRs with review status: "PSS filtering #977 — open 3d, awaiting re-review"]
- [Suggest escalation for 5+ day blockers]
- ["None" if clear]

## Heads Up (only if relevant)
- [Sensitivities, deadlines, or relationship context affecting today's work]
```

---

### Leadership Meetings

#### [Meeting Name]
**Channel:** [Slack channel if applicable]
**Purpose:** [What it's for]

**Standing Topics:**
- [Topic 1]
- [Topic 2]

**Your Focus Areas:**
- [What you specifically bring or own in this meeting]

---

### Cross-Functional

#### [Meeting Name]
**Key Dynamics:** *See dynamics.md for cross-team context*
**Approach:**
- [How to navigate this meeting effectively]

---

### Upcoming

<!-- Ad-hoc meetings on the horizon -->

### Recent

<!-- Recently completed meetings worth noting — remove after ~2 weeks -->

---

## Meeting Prep Templates

### Leadership Meeting
```
1. Team status: what's on track, what's not
2. Cross-team dependencies or blockers
3. Decisions needing group input
4. FYIs and announcements
```

### Stakeholder Update Meeting
```
1. Current state of [project/initiative]
   - Progress since last update
   - Key milestones hit

2. Blockers/Risks
   - What's slowing us down
   - What could go wrong

3. Ask/Decision needed
   - What do you need from them?
```

### Technical Decision Meeting
```
1. Problem statement
2. Options considered
3. Recommendation + rationale
4. Trade-offs
5. Impact on teams
6. Timeline
```

### Difficult Conversation Prep
```
1. What's the issue? (specific examples)
2. Why does it matter? (impact)
3. What outcome do I want?
4. What might they say? How will I respond?
5. What's the collaborative path forward?
```
