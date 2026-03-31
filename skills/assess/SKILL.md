---
name: assess
description: >
  Performance assessment workflow — fetch self-assessments from HR system,
  compare with manager assessments, update coaching points. Use when the user
  says "assessment", "performance review", "self-assessment", or "review for
  [name]".
---

## Instructions

Run the performance assessment comparison workflow for a named report.

### Phase 1: Check existing files

Check `$SECRETARY_ROOT/outputs/assessments/[name]/` for:
- `manager-assessment-YYYY.md`
- `self-assessment-YYYY.md`

Use current year. Directory uses the same `[first-last]` format as people files
(e.g., `outputs/assessments/jane-doe/`).

### Phase 2+3: Fetch missing + read context (parallel)

**Fetch missing assessments (if needed):**
- Self-assessment missing: Use ~~hr-system connector to navigate to the employee's review page, extract content, save to `outputs/assessments/[name]/self-assessment-YYYY.md`
- Manager assessment missing: Ask the user to provide it

**Read memory context (parallel):**
- Both assessment files
- `$SECRETARY_ROOT/memory/people/[name].md`
- `$SECRETARY_ROOT/memory/dynamics.md`
- `$SECRETARY_ROOT/memory/meetings.md` — their 1:1 prep notes

### Phase 4: Analysis

Produce a structured comparison:

```
## Assessment Comparison: [Name] — [Year]

### Self-Assessment Highlights
- [Key points from their self-assessment — what they're proud of, where they think they struggled]

### Alignment (both agree)
- [Areas where manager and self-assessment see the same strengths/weaknesses]

### Key Divergences
- **[Topic]** — Self: "[quote/summary]" vs Manager: "[quote/summary]"
  - *Implication:* [What this means for the review conversation]

### Perception Gaps
- **Feeling valued:** [Their score and exact words]
- **Engagement:** [Self-perception vs manager rating]
- **Biggest blind spot:** [What they don't see about themselves]

### Coaching Points for Review Conversation
- [What to reinforce — strengths to explicitly acknowledge]
- [What to develop — frame with empathy, connect to their goals]
- [What to monitor — areas to track without over-indexing]

### Conversation Approach
- **Tone:** [e.g., "supportive but direct", "softer — reframe around growth"]
- **Open with:** [Suggested opening]
- **Avoid:** [Landmines to steer around]
- **Key message to land:** [The one thing they should walk away understanding]
```

### Phase 5: Update memory files

1. Person's file — add/update a `**YYYY Performance Review Insights:**` section with:
   - Self-assessment highlights
   - Alignment with manager review
   - Key divergences (with specific quotes/evidence)
   - Coaching points for the review conversation
   - Review conversation approach notes
2. meetings.md — update 1:1 prep notes with review context
3. my-work.md — add or update "conduct performance review conversation" item

### Phase 6: Save output

Save to `$SECRETARY_ROOT/outputs/assessments/[name]/comparison-YYYY.md`

## Trigger Rules

**When a self-assessment completion notification arrives** (e.g. from the HR system):
1. Check if `$SECRETARY_ROOT/outputs/assessments/[name]/self-assessment-YYYY.md` already exists
2. If not, fetch the self-assessment content and save it there
3. If both manager and self assessment now exist, run the Assessment Comparison Workflow (Phase 4+5+6 above)

**Checking assessment status:** Before asking the user whether reviews are complete, always check `$SECRETARY_ROOT/outputs/assessments/` to see what files exist. The presence of files tells you the answer.

**Fetching assessments from HR system:** Use Claude's own Chrome integration (`mcp__claude-in-chrome__*` tools) to navigate to the HR system (see `$SECRETARY_ROOT/memory/company.md > Service URLs` for the URL) and fetch assessment content. Do NOT use other Chrome MCPs (e.g. `mcp__chrome-devtools__*`) as they don't share browser sessions/cookies. This is an ad-hoc browser task, not part of the /sync flow.

## Rules

- Never fabricate assessment content
- Quote directly from assessments for divergences
- Be psychologically astute — identify what the person needs to hear vs wants to hear
- Consider dynamics.md for salary frustrations, flight risk signals
- If both assessments exist and comparison was done, ask what to revisit
