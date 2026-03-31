# Sync Sources

Configure your external data sources here. The `/secretary:sync` skill reads
this file to know where to pull data from.

---

## Project Tracking — Primary Sources

<!-- CUSTOMIZE: Add your project management tool sources below.
     Examples are provided for Notion, but adapt to your tool (Linear, Jira, Asana, etc.) -->

### Tasks Database
**URL:** [Your tasks/issues URL]
<!-- For Notion: **Data Source:** `collection://[database-id]` -->
**Use For:** Individual tasks, bugs, stories, spikes
**Sync To:** projects.md (active items)

### Initiatives, Epics & Milestones
**URL:** [Your initiatives/epics URL]
<!-- For Notion: **Data Source:** `collection://[database-id]` -->
**Use For:** High-level project tracking
**Sync To:** projects.md
**Key Filters:**
- Status: In development, Scoping, Backlog
- Type: Initiative, Epic

### Team / Domain Management
**URL:** [Your team structure source URL]
<!-- For Notion: **Data Source:** `collection://[database-id]` -->
**Use For:** Team structure, who's on what domain
**Sync To:** memory/people/, company.md

---

## Reference Sources

<!-- CUSTOMIZE: Add documentation, ADRs, PRDs, and other reference sources -->

### [Documentation Home]
**URL:** [Your documentation URL]
**Use For:** Org structure, resources, processes

---

## Slack Sources

### Monitored Channels

<!-- CUSTOMIZE: Add channels relevant to you. Use /secretary:setup to auto-detect IDs. -->

| Channel | ID | Sync To |
|---------|-----|---------|
| [your-team-channel] | `[channel-id]` | projects.md, memory/people/ |
| [your-engineering-channel] | `[channel-id]` | projects.md, company.md |

### Direct Messages
**Your Slack ID:** `[your-slack-user-id]`
**Tool:** `slack_search_public_and_private` — search DMs per person using `in:<@THEIR_SLACK_ID> after:YYYY-MM-DD`
**Sync To:** memory/people/, my-work.md, dynamics.md

**Key DM contacts to monitor:**
<!-- CUSTOMIZE: Add your direct reports, manager, key collaborators -->
- [Name] — [relationship, e.g. "direct report", "manager"]

### Slack User ID Cache

Use cached IDs below instead of looking up at sync time. Refresh cache periodically via `slack_search_users`.

| Name | Slack ID | Title |
|------|----------|-------|
| [Your Name] | `[id]` | *(self)* |

---

## GitHub Sources

### Configuration
**GitHub Username:** `[your-username]`
**Organization:** `[your-org]`
**Auth Method:** `[env-token, gh-cli, or api-token]`

<!-- Auth method is set automatically by /secretary:setup.
     - env-token: Uses GITHUB_TOKEN or GH_TOKEN from the environment (no file needed)
     - gh-cli: Uses `gh` CLI authenticated via system keyring (Claude Code / local dev)
     - api-token: Uses a Personal Access Token stored in $SECRETARY_ROOT/.github-token (Cowork / environments without gh CLI)
     Run /secretary:setup again to reconfigure. -->

### What to Sync
| Activity | API Query (`q` parameter) | Sync To |
|----------|--------------------------|---------|
| PRs authored | `is:pr author:{username} org:{org} sort:updated-desc created:>={cutoff_date}` | projects.md, my-work.md |
| PRs reviewed | `is:pr reviewed-by:{username} org:{org} sort:updated-desc updated:>={cutoff_date}` | projects.md, memory/people/ |
| PRs awaiting review | `is:pr review-requested:{username} org:{org} is:open` | my-work.md |
| PR comments | `is:pr commenter:{username} org:{org} sort:updated-desc updated:>={cutoff_date}` | projects.md |

<!-- These queries work with both auth methods:
     - gh CLI: `gh api search/issues --method GET -f q="..." -f per_page=30`
     - API token: `curl -s -H "Authorization: Bearer {token}" "https://api.github.com/search/issues?q=...&per_page=30"` -->

---

## Sync Procedures

### Full Sync (uses parallel subagents)
1. Launch subagents in parallel (see sync command for details):
   - **Project tracker agent**: Fetch initiatives, tasks, team structure from primary sources
   - **Slack channels agent**: Read recent messages from all accessible monitored channels
   - **Slack DMs agent**: Search recent DMs with key contacts
   - **GitHub agent**: Fetch recent PRs authored, reviewed, and requested for review
2. Main agent reads all current memory files
3. Consolidate results, propose changes grouped by memory file
4. Ask before applying updates

### Quick Sync (Projects Only)
1. Fetch initiatives database with active filter
2. Update projects.md with current status

### Person Sync
1. Fetch relevant entries from project tracker
2. Search Slack DMs with that person (`in:<@USERID> after:LAST_SYNC_DATE`)
3. Search Slack channels for mentions (`from:<@USERID> after:LAST_SYNC_DATE`)
4. Update the person's file in memory/people/
