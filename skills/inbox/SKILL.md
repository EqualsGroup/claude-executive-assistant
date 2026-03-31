---
name: inbox
description: >
  Process your email inbox to reach inbox zero. Triage, delete junk and system
  notifications, archive unique content, log new work, and surface action items.
  Use when the user says "inbox", "email", "triage", or "inbox zero".
---

## Instructions

### Phase 1+2: Load context and read inbox (parallel)

**Context (parallel reads from $SECRETARY_ROOT/):**
- `memory/people/` — list filenames only (resolve people lazily per email)
- `memory/projects.md` — active initiatives
- `memory/my-work.md` — current work items
- `outputs/assessments/` — scan directory for existing assessments

**Inbox (paginated):**
<!-- CUSTOMIZE: Choose your email integration -->
<!-- Option A: Microsoft 365 MCP -->
Use your ~~email connector to fetch inbox emails. Paginate until all emails are retrieved.
For ambiguous emails, read the full body for more context.

As a fallback or concrete example, you can use the `mcp__claude_ai_Microsoft_365__outlook_email_search` tool directly:

1. First call: `outlook_email_search` with `folderName: "Inbox"`, `limit: 50`, `offset: 0`
2. If 50 results returned, continue with `offset: 50`, then `offset: 100`, etc. until fewer than 50 results come back
3. For emails that need more context (ambiguous categorization, action items), use `mcp__claude_ai_Microsoft_365__read_resource` with the email's URI (`mail:///messages/{messageId}`) to read the full body

<!-- Option B: Google Workspace MCP — adapt the tool calls accordingly -->

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

**Exception — Meeting summary/recap emails:** These are NOT system noise. They contain AI-generated meeting recaps with action items. **Digest the content** (update relevant memory files: `my-work.md` for action items, `projects.md` for decisions, the relevant person's file in `memory/people/` for observations) and then **archive** (not delete) — the summary is unique content not captured elsewhere.

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
- Log action items to `$SECRETARY_ROOT/memory/my-work.md`:
  - Add to the appropriate tier (Now/Next/Later) in the Master List
  - Include who's involved, deadlines, and blockers inline
- Update the relevant person's file in `$SECRETARY_ROOT/memory/people/` with context

#### Browser execution for delete/archive

When using the browser to execute deletions and archives:

1. Use `mcp__claude-in-chrome__tabs_context_mcp` (with `createIfEmpty: true`) to get browser context
2. Create a new tab with `mcp__claude-in-chrome__tabs_create_mcp`
3. Navigate to your email client URL using `mcp__claude-in-chrome__navigate`
4. Wait for the page to load

**Deleting emails:**
- Search for each email by subject/sender to locate it in the list
- Click each junk email in the list to select it
- Click the **Delete button in the toolbar**
- Take a screenshot after each batch to verify
- **Important:** Email clients re-render the DOM after each deletion — always re-read the page (`read_page`) to get fresh refs before the next action. Never reuse stale refs.

**Archiving emails:**
- Click each email to select it
- Click the **Archive button** in the toolbar
- Same ref-freshness rules as deletion

#### Responding / forwarding
- Ask the user for approval before sending any replies
- Draft the reply content and present it for review
- For forwards, suggest who to forward to based on `memory/people/` files (domain ownership, team structure)

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
- **Self-assessment completion emails (TRIGGER):** When an HR system email says someone completed their self-assessment, check if `$SECRETARY_ROOT/outputs/assessments/[name]/self-assessment-YYYY.md` exists. If not, flag as action item: "Fetch and save [Name]'s self-assessment, then run comparison with manager assessment." If both assessments now exist, trigger the Assessment Comparison Workflow (see assess skill). Delete the email after processing — the data is saved locally and in the HR system.
