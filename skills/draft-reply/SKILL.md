---
name: draft-reply
description: >
  Research a topic and draft a substantive reply in the user's voice — for
  emails, messages, or document comments. Use when the user says "draft a
  reply", "respond to", "write back to", or asks to compose a message for
  someone.
---

## Instructions

### Phase 1: Understand the request

From the user's message, determine:
- **Recipient:** Who is this for?
- **Source:** ~~email, ~~messaging, ~~documents comment, or ad-hoc
- **Topic:** What is being replied to?
- **Depth:** Quick reply (1-3 sentences) or substantive (requires research)
- **Channel:** Where will this be sent?

### Phase 2: Gather context (parallel)

**Always read from $EA_ROOT/:**
- `memory/people/[recipient].md`
- `memory/dynamics.md` — sensitivities involving this person or topic
- `memory/my-work.md` — related priorities or commitments

**If research required:**
- Search the web for relevant sources
- Check `memory/projects.md` for technical context

### Phase 3: Draft the reply

1. Match the user's voice (see the "User Voice" section in CLAUDE.md)
2. Match the channel — ~~messaging is casual, ~~email slightly longer, ~~documents is structured
3. Lead with the answer
4. Reference specifics — concrete examples, data points
5. Consider the relationship — dynamics.md may reveal careful handling needed
6. If research was done, weave findings naturally into the reply. Don't dump a bibliography — integrate insights.

### Phase 4: Present for approval

```
**To:** [Recipient]
**Channel:** [Where it will be sent]
**Context:** [1-line summary]

---

[Draft reply text]

---

**Notes:** [Any context for the user — e.g., "Toned down the criticism given dynamics with this person", "Included the arXiv reference they mentioned", "Kept it short since they're senior and busy"]
```

### Phase 5: Save, send, and track (after approval)

**If the user approves sending:**
- Send via the appropriate connector (~~messaging, ~~email, ~~documents)
- If a commitment was made in the reply, add it to `$EA_ROOT/memory/my-work.md`
- If the reply reveals a decision or position, update relevant memory file

**If the user just wanted the draft:**
- Save to `$EA_ROOT/outputs/drafts/YYYY-MM-DD-[recipient]-[topic].md` if substantive
- No memory updates needed unless the user explicitly decides something

## Rules

- Never send without approval
- Match voice precisely — the user's reputation is on the line
- Be honest about gaps — if memory doesn't have enough context about the recipient or topic, say so and ask before drafting
- Research is optional, not default — most replies just need memory context
- Keep it human — no AI-sounding phrases. Specifically avoid: "I hope this email finds you well", "As per our discussion", "Please don't hesitate to reach out", "I wanted to circle back", "Just following up on this"
- Consider timing — if the reply is significantly overdue (check my-work.md), acknowledge the delay naturally without over-apologizing
