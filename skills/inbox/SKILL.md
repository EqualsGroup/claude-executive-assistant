---
name: inbox
description: >
  Process your email inbox to reach inbox zero. Triage, delete junk and system
  notifications, archive unique content, log new work, and surface action items.
  Use when the user says "inbox", "email", "triage", or "inbox zero".
---

## Instructions

### Phase 1+2: Load context and read inbox (parallel)

**Context (parallel reads from $EA_ROOT/):**
- `memory/people/` — list filenames only (resolve people lazily per email)
- `memory/projects.md` — active initiatives
- `memory/my-work.md` — current work items
- `outputs/assessments/` — scan directory for existing assessments

**Inbox (paginated):**
<!-- CUSTOMIZE: Choose your email integration -->
<!-- Option A: Microsoft 365 MCP -->
Use your ~~email connector to fetch inbox emails. Paginate until all emails are retrieved.
For ambiguous emails, read the full body for more context.

Typical pagination pattern:
1. First call: search/list inbox with `limit: 50`, `offset: 0`
2. If 50 results returned, continue with `offset: 50`, then `offset: 100`, etc. until fewer than the limit come back
3. For emails that need more context (ambiguous categorization, action items), use your connector's read/get message tool to fetch the full body

### People resolution (lazy, per email)

Do NOT load all person files upfront. Resolve senders on demand:
1. Filename match — sender name maps to `memory/people/[first]-[last].md`
2. If no match — grep `memory/people/` for the sender's email or name
3. If still no match — categorize without people context
4. On match — read the file for role, context, and relationship info

### Phase 3: Categorize every email

#### DELETE
- Cold outreach, marketing, vendor pitches, recruitment firms
- "Follow up" from unknown external senders
- Emails flagged as spam or graymail by email security tools
- System notifications where data lives elsewhere (HR, ticket trackers, calendar confirmations, performance review reminders)
- **Meeting platform "joined your meeting" notifications** — pure system noise, delete
- Old weekly updates (>1 week old) — the content is in shared docs
- Old resolved threads with no unique information (e.g. "Ok thanks" confirmations where the underlying decision/content is captured elsewhere). A resolved thread that contains unique commitments, decisions, or plans (e.g. "we'll schedule a session", "I'll handle X") should be **archived**, not deleted — the email may be the only record of that agreement.

**Exception — Meeting summary/recap emails:** These are NOT system noise. They contain AI-generated meeting recaps with action items. **You MUST digest the content BEFORE archiving or deleting.** Read the full email body using your email MCP connector, then update relevant memory files: `my-work.md` for action items and commitments, `projects.md` for decisions and status changes, the relevant person's file in `memory/people/` for observations, coaching points, and relationship context. Only after digestion is complete should you archive the email. Never skip digestion — these summaries are often the only structured record of what was discussed.

**Phishing red flags** — flag to user, don't auto-delete:
- Urgency + external sender + financial topic
- Mismatched display name vs email domain
- Read receipt requests from unknown senders
- Attachments from first-time senders with vague subjects

#### ARCHIVE
- Emails with substantive content not captured elsewhere
- Company-wide policy or guidance announcements
- Threads where the email itself is the only record of a decision or agreement

#### ACTION NEEDED
- Emails from direct reports and manager (check `memory/people/`)
- Emails from key collaborators (cross-reference `memory/people/`)
- IT approvals, access reviews, compliance issues
- Billing/account actions (infrastructure, SaaS)
- Emails where user is specifically mentioned or flagged
- Flagged/pinned emails

### Phase 4: Present triage

```
## DELETE (X emails)
| From | Subject | Why |

## ARCHIVE (X emails)
| From | Subject | Why |

## ACTION NEEDED (X emails)
| From | Subject | Context | Suggested action |

## DECIDE (need your input)
| From | Subject | Question |
```

For ACTION items, cross-reference memory files to add context:
- If sender has a file in `memory/people/`, note their role and recent context
- If related to a project in projects.md, note the project status
- Suggest specific actions (reply, forward to X, approve, sign, add to calendar)

### Phase 5: Execute (after user confirmation)

Wait for user to approve the plan, then execute:

- Delete approved emails
- Archive approved emails
- Log action items to `$EA_ROOT/memory/my-work.md`:
  - Add to the appropriate tier (Now/Next/Later) in the Master List
  - Include who's involved, deadlines, and blockers inline
- Update the relevant person's file in `$EA_ROOT/memory/people/` with context

#### Browser execution for delete/archive

Use the following escalation strategy. Try each level in order; fall back to the next if the current approach fails.

##### Level 1: MCP tools (preferred)

If your email MCP connector supports delete/archive/move operations, use those directly. This is the fastest and most reliable path.

##### Level 2: Browser — inbox list interface

When MCP tools don't support write operations, fall back to browser automation:

1. Use `tabs_context_mcp` (with `createIfEmpty: true`) to get browser context
2. Create a new tab and navigate to the email client inbox URL
3. Wait for the page to fully load (may take 6-8 seconds for webmail clients)
4. Search for each email by subject/sender to locate it in the list
5. Click to select, then click the **Delete** or **Archive** button in the toolbar
6. Take a screenshot after each batch to verify
7. **Important:** Email clients re-render the DOM after each action — always re-read the page (`read_page`) to get fresh refs. Never reuse stale refs.

**If this fails** (e.g. virtualized rendering returns 0 items in DOM, screenshots timeout, inbox list doesn't render), escalate to Level 3.

##### Level 3: Browser — individual email deep links

When the inbox list interface is unusable (e.g. virtualized rendering returns 0 DOM children), navigate to each email individually using deep links. Most webmail clients support opening a single message by URL, which renders a full toolbar independently of the list view.

**How it works:**
1. Construct a deep link URL for each email using its message ID from the MCP search results. URL-encode the ID as needed.
   <!-- Outlook example: https://outlook.office365.com/owa/?ItemID={urlEncodedMessageId}&exvsurl=1&viewmodel=ReadMessageItem -->
   <!-- Gmail example: https://mail.google.com/mail/u/0/#inbox/{messageId} -->
2. Navigate to the deep link — the email client renders the single message with its own toolbar.
3. Wait for the page to fully load and toolbar to render (6-8 seconds for most webmail clients).
4. Execute the action by clicking the **Delete** or **Archive** button in the toolbar. Use `aria-label` selectors or visible button text to locate the correct control.
5. **Tab lifecycle:** The tab may become unresponsive after an action. Always call `tabs_context_mcp(createIfEmpty: true)` before navigating to the next email — if the tab is gone, a new one is created automatically.
6. Process emails one at a time: navigate → wait → click action → next.

**Tips:**
- If the page says the message was moved or deleted — the email is already gone. Skip it.
- If the page loads but shows 0 action buttons after 8+ seconds, close the tab and retry with a fresh one.
- This approach is slower (~10s per email) but highly reliable since each email renders its own toolbar independently.

#### Responding / forwarding
- Ask the user for approval before sending any replies
- Draft the reply content and present it for review
- For forwards, suggest who to forward to based on `memory/people/` files (domain ownership, team structure)

#### Content digestion during execution

**Before archiving any email that contains substantive content** (meeting summaries, decision threads, action item lists), you MUST read and digest the content first:

1. Use your email MCP connector to fetch the full email body
2. Extract actionable content: action items, decisions, commitments, observations
3. Update the relevant memory files (my-work.md, projects.md, people files, dynamics.md)
4. Only then proceed with the archive action

This is especially critical for meeting recap/summary emails from Zoom, Teams, etc. — they often contain the only structured record of what was discussed and agreed. Skipping digestion means losing information permanently.

### Phase 6: Summary

After processing, report:
- How many emails deleted, archived, actioned
- New work items added to my-work.md
- Remaining items that need manual attention
- Current inbox count

## Rules

- Never delete without user approval for the category
- Never send emails without explicit approval
- **Don't send read receipts** — these are typically requested by cold outreach senders
- Always cross-reference memory files for internal senders
- Flag potential phishing — don't delete, escalate
- **Re-read the page after every deletion/archive** to get fresh element references. Email clients often invalidate refs on every DOM change.
- Prefer DELETE over ARCHIVE — if data lives elsewhere, delete the email
- When in doubt about an email, put it in the DECIDE category rather than guessing
- **Self-assessment completion emails (TRIGGER):** When an HR system email says someone completed their self-assessment, check if `$EA_ROOT/outputs/assessments/[name]/self-assessment-YYYY.md` exists. If not, flag as action item: "Fetch and save [Name]'s self-assessment, then run comparison with manager assessment." If both assessments now exist, trigger the Assessment Comparison Workflow (see assess skill). Delete the email after processing — the data is saved locally and in the HR system.
