---
name: review-doc
description: >
  Review a document with full memory context, then post structured comments on
  specific sections. Use when the user says "review this", "look at this doc",
  "give me feedback on", or shares a document link for analysis.
---

## Instructions

### Phase 1: Identify the document

From the user's message, determine:
- **Document source:** ~~documents URL, shared link, or pasted content
- **Review scope:** Full review, specific sections, or a focused lens
- **Output mode:** Post comments on the document, or return feedback locally

### Phase 2: Read document + context (parallel reads)

**Document content:**
- ~~documents URL: use the ~~documents connector
- Other URL: fetch the content
- Pasted: use directly

**Memory context from $EA_ROOT/ (parallel reads):**
- `memory/people/` — files for author and anyone mentioned
- `memory/dynamics.md` — sensitivities involving the topic or people
- `memory/projects.md` — related initiatives
- `memory/company.md` — org structure, regulatory context
- `memory/my-work.md` — user's current priorities

### Phase 3: Analyze (main agent)

For each section:
1. **Assess:** Is this section accurate, complete, and well-framed given what memory knows?
2. **Cross-reference:** Does it align with or contradict known dynamics, decisions, or context?
3. **Identify gaps:** What's missing that memory files suggest should be here?
4. **Consider audience:** Who will read this? What political or interpersonal context matters?
5. **Form a position:** What should the user's stance be on this section?

Group feedback into:
- **Agree / fine as-is**
- **Partially agree** — specific improvements
- **Disagree / missing** — substantive gaps
- **Strategic suggestions** — reframings from broader context

### Phase 4: Present review plan (main agent)

Present all planned feedback to the user for approval before posting anything.

```
## REVIEW: [document name]

### AGREE / FINE AS-IS (X sections)
| Section | Note |

### COMMENTS TO POST (X comments)
| # | Section | Type | Comment draft |
(Type = Partially agree / Disagree / Gap / Strategic)

### STRATEGIC SUGGESTIONS (X items)
| # | Section | Suggestion |

### MEMORY UPDATES
| File | Change |
```

For each comment, show the exact text that would be posted (in the user's voice).
End with: **"Approve all, or tell me which to edit/drop."**

### Phase 5: Execute (after user confirmation)

Wait for the user to approve or adjust the plan, then execute:

**If posting comments:**
- One comment per point, anchored to the section. Write in user's voice (see voice guidelines).
- Keep comments concise: 1-3 sentences, lead with the point.
- Use the ~~documents connector's comment tool with the specific block/section ID.
- For other platforms: use the appropriate comment/annotation tools.
- Only post comments the user has approved.

**If returning locally:** Present inline, save to `$EA_ROOT/outputs/reviews/YYYY-MM-DD-[doc-name].md`

### Phase 6: Track follow-up

- Add a Track item to `$EA_ROOT/memory/my-work.md` noting comments were posted, who owns next action, and what to monitor
- If the review surfaced decisions or positions, update the relevant memory file (dynamics.md for governance positions, projects.md for technical decisions, etc.)

## Rules

- Always load full memory context — that's the value of this skill
- **Never post comments without user approval** — present the plan first, always
- Write in the user's voice
- Be substantive, not nitpicky
- Flag political landmines from dynamics.md
- One comment per point
- Never fabricate context
