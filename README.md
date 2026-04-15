# Claude Executive Assistant

A Claude plugin that remembers everything about your work — your team, your
projects, the org politics nobody writes down — and uses it all to actually
help you get things done.

## How It Works

The plugin provides the **intelligence layer** (skills, commands, connectors)
while your **persistent memory lives in a folder you choose**. Think of it as
giving Claude a filing cabinet that survives between conversations.

- Memory persists across sessions — no more re-explaining your org
- Plugin updates don't touch your data — they're completely separate

## See It In Action

> *Meet Jamie, an Engineering Manager at ACME Corp. Jamie installed the plugin
> last week. Here's a random Tuesday.*

**8:45 AM** — Jamie opens Claude:

```
prep me for my meetings today
```

The assistant checks Jamie's calendar, sees a 1:1 with River at 10am, and
pulls context from memory: River's been frustrated about the platform
migration timeline, mentioned wanting to lead the API redesign last week,
and their self-assessment is due Friday. It generates a prep doc with talking
points, open questions, and a suggested agenda — all without Jamie explaining
any of this.

**9:30 AM** — 47 unread emails overnight:

```
go through my inbox
```

The assistant triages everything: archives 31 automated notifications, flags
a compliance deadline from Legal that affects the Q3 roadmap, surfaces a
passive-aggressive thread between Platform and Product that Jamie should
probably weigh in on, and drafts a reply to the VP asking for headcount
projections. Jamie reviews the drafts, tweaks one, and hits send. Inbox zero
in 8 minutes.

**2:00 PM** — Someone shares a Notion doc proposing a new incident response
process:

```
can you review this https://notion.so/acme/incident-response-v2
```

The assistant reads the doc, cross-references it against ACME's current
on-call structure, flags that the proposed escalation path skips the team
that actually owns the payment service, notes a political sensitivity with
the author, and presents a review plan: 3 comments to post, 1 strategic
suggestion. Jamie approves two, edits one, drops the last. Comments appear
on the Notion doc in Jamie's voice.

**Meanwhile, throughout the day** — Jamie doesn't type a thing. Sync runs
automatically at 9 AM, 1 PM, and 5 PM (Jamie
[scheduled](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-cowork)
it once and forgot about it), pulling from Slack, email, Notion, and GitHub.
Here's what the 5 PM sync picks up on its own:

- The 1:1 with River generated a Notion meeting transcript. In it, River
  expressed frustration about the migration timeline slipping again — second
  time this month. The assistant updates River's people file with coaching
  context and flags it for the next 1:1 prep.
- Jamie merged two PRs on the monitoring dashboard. The assistant marks the
  dashboard work item as shipped and logs the win.
- In `#platform-eng`, someone from the vendor shared that the API
  deprecation date moved from September to July. The assistant updates the
  platform migration project with the new deadline and flags it as a risk
  in tomorrow's meeting prep.
- Jamie closed three Notion tickets during the day. Done items get archived
  automatically.

**Jamie didn't report any of this.** No end-of-day summary, no manual
updates. The assistant pieced it together from meeting transcripts, merged
PRs, Slack channels, and closed tickets — the same tools Jamie was already
working in.

> For power users: every natural language prompt above also has a short
> command form — `/ea:meeting-prep`, `/ea:inbox`, `/ea:review-doc`, etc.

---

## Getting Started

### Installation

**Org-wide (admin):** Go to **Organization settings > Plugins**, add the
plugin by pointing to this repository's URL, and set it to "Installed by
default" for all team members.

**Individual:** Install via the plugin marketplace or manually through your
Claude settings. Works with Cowork, Claude Code, and Claude Desktop.

### First-Time Setup

```
help me get set up
```

The setup wizard detects your environment and walks you through everything:

1. **Finds your persistent folder** — Cowork mount or `~/secretary/`
2. **Creates the memory structure** — the filing cabinet for your context
3. **Checks your connectors** — Slack, Notion, GitHub, email, etc.
4. **Sets up GitHub** *(optional)* — enables PR tracking and activity syncing
5. **Fills in your profile** — name, role, team, reporting structure
6. **Offers a first sync** — pulls data from your configured sources

<details>
<summary><b>Cowork (Claude Desktop / Web)</b></summary>

Start a **Project session** with a folder selected, then run `/ea:setup`.
The wizard creates a `secretary/` directory in your selected folder.

**Important:** Use a Project session, not a Task session. Task sessions have
no persistent storage — memory files would be lost.
</details>

<details>
<summary><b>Claude Code (CLI) / Claude Desktop</b></summary>

Run `/ea:setup` from any project. Memory is stored in `~/secretary/`
by default — shared across all your projects so context is always available.

If you have existing secretary files from a previous setup, the wizard will
detect them and offer to migrate.
</details>

## Skills

| Command | What it does |
|---------|-------------|
| `/ea:setup` | Initialize memory, configure connectors |
| `/ea:sync` | Pull updates from Notion, Slack, GitHub into memory |
| `/ea:done` | Process completed items — archive, promote wins, update people files |
| `/ea:inbox` | Triage email to inbox zero — delete junk, surface actions, draft replies |
| `/ea:meeting-prep` | Generate prep docs with full context for any meeting |
| `/ea:assess` | Compare self-assessments against your manager notes |
| `/ea:draft-reply` | Draft a reply in your voice with full memory context |
| `/ea:review-doc` | Review a document, present feedback plan, post approved comments |
| `/ea:improve` | Audit and optimize the entire memory system |
| `/ea:upgrade` | Align data files with the latest plugin scaffold |

## Scheduling Sync

The plugin gets much more powerful when sync runs automatically. Schedule
`/ea:sync` to run a few times a day and your memory stays current
without you thinking about it.

| Environment | How to schedule | Guide |
|-------------|----------------|-------|
| **Cowork** (Desktop / Web) | Scheduled tasks UI — set frequency and prompt | [Cowork scheduling guide](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-cowork) |
| **Claude Code on the web** | Cloud scheduled tasks — runs even when your machine is off | [Cloud scheduling guide](https://docs.anthropic.com/en/docs/claude-code/web-scheduled-tasks) |
| **Claude Code CLI** | `/loop` for session-scoped polling, or Desktop scheduled tasks for persistence | [CLI scheduling guide](https://docs.anthropic.com/en/docs/claude-code/scheduled-tasks) |

A good starting cadence is **3x/day** (morning, midday, end of day). Each
sync pulls the latest from your configured sources — messaging threads,
email, document updates, code activity — and writes what changed into
memory. By the time you need it, it's already there.

## Keeping Up to Date

When the plugin gets updated (new skills, improved prompts, better scaffold
templates), your existing memory files aren't touched — that's by design.
But sometimes a plugin update introduces new sections, better formatting, or
structural changes that your data files could benefit from.

After a plugin update, just ask:

```
check if my files need upgrading
```

The assistant compares your data files against the latest scaffold templates
and tells you what's changed. It won't overwrite anything — it shows you
what's new and lets you decide what to adopt.

## Connectors

The plugin uses whatever integrations are already available in your session —
org-level connectors from your admin, or personal ones from Claude Desktop.
No additional MCP configuration needed.

Skills reference generic connector categories (`~~messaging`, `~~email`,
`~~documents`) so they work regardless of your tool stack. See
[CONNECTORS.md](CONNECTORS.md) for the full mapping.

## Memory Structure

```
secretary/
├── CLAUDE.md              # Hot cache (~100 lines) — loaded every session
├── memory/
│   ├── my-work.md         # Tasks, priorities, wins, goals
│   ├── people/            # One file per person
│   │   ├── river.md
│   │   └── _relationship-map.md
│   ├── projects.md        # Active initiatives
│   ├── dynamics.md        # Org politics, sensitivities, landmines
│   ├── company.md         # Org structure, systems, processes
│   └── meetings.md        # Recurring meetings, prep templates
├── outputs/               # Generated artifacts
│   ├── meeting-prep/
│   ├── assessments/
│   ├── drafts/
│   └── reviews/
└── sync/
    └── sources.md         # External source configuration
```

Everything is plain markdown. You can read it and edit it directly.

## Customization

**Company context** — Edit files in `secretary/memory/` to add your org
structure, projects, people profiles, and meeting schedules.

**Voice** — The `## User Voice` section in your CLAUDE.md defines how drafted
text sounds. Loaded every session, always active.

**Sync sources** — Edit `secretary/sync/sources.md` to add Notion databases,
Slack channels, and other sources to monitor.

## Multi-Device Access

If you use Claude Code on your main machine and want to access your
assistant from other devices without syncing files, you can use
**Claude Dispatch** to remotely talk to the EA running on your primary
device. Your memory files stay local — Dispatch just bridges the
conversation.

## Architecture

```
plugin/
├── .claude-plugin/plugin.json    # Manifest
├── hooks/                        # SessionStart detects memory root
│   ├── hooks.json
│   └── detect-root.sh
├── CONNECTORS.md                 # Tool-agnostic connector mapping
├── skills/                       # 10 skill definitions
└── scaffold/                     # Template for memory initialization
```

The key design decision: **the plugin is stateless**. All persistent state
lives in your folder, not in the plugin. Plugin updates never touch your
data. The SessionStart hook auto-detects the memory location across
environments — Cowork mounted folder or local `~/secretary/`.

## License

AGPL-3.0 — see [LICENSE](LICENSE)
