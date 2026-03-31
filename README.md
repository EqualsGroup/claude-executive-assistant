# Secretary Plugin

A personal secretary plugin with persistent memory — tracks your work, people,
projects, and org dynamics across sessions.

## How It Works

The plugin provides the **intelligence layer** (skills, commands, connectors)
while your **persistent memory lives in a folder you choose**. The plugin
detects the right location based on your environment, or you can point it
anywhere.

- Memory persists across sessions
- You can git-track it for version history
- The plugin can be updated without losing your data

## Installation

**Org-wide (admin):** Upload the plugin ZIP to **Organization settings > Plugins**
and set it to "Installed by default" for all team members.

**Individual:** Install the plugin via the plugin marketplace or manually through
your Claude settings. Works with Cowork, Claude Code, and Claude Desktop.

## First-Time Setup

Once the plugin is installed, run `/secretary:setup`. The setup wizard detects
your environment and walks you through everything.

### Cowork (Claude Desktop / Web)

Start a **Project session** with a folder selected, then run `/secretary:setup`.
The wizard will create a `secretary/` directory in your selected folder.

**Important:** Use a Project session, not a Task session. Task sessions have no
persistent storage — memory files would be lost.

### Claude Code (CLI) / Claude Desktop

Run `/secretary:setup` from any project. Memory is stored in `~/secretary/` by
default — shared across all your projects so your context is always available.

If you have existing secretary files from the old clone-based setup, the wizard
will detect them and offer to migrate.

### What setup does

The setup wizard will:
1. **Detect your environment** — find the persistent folder (Cowork mount or `~/secretary/`)
2. **Initialize `secretary/`** — create the memory folder structure
3. **Check your connectors** — which integrations (Slack, Notion, etc.) are available
4. **Set up GitHub (optional)** — if you have the `gh` CLI installed and authenticated,
   setup will enable PR tracking and activity syncing. If not, it will walk you through
   installation and authentication. This is optional — you can skip it and add it later.
5. **Walk you through placeholders** — fill in your name, role, team, etc.
6. **Offer a first sync** — pull data from your configured sources

## Skills & Commands

### Commands (you invoke these)

| Command | Description |
|---------|-------------|
| `/secretary:setup` | Initialize memory, configure connectors |
| `/secretary:sync` | Pull updates from Notion, Slack, GitHub into memory |
| `/secretary:done` | Process completed items — remove from lists, promote wins |
| `/secretary:inbox` | Triage email to inbox zero |
| `/secretary:meeting-prep` | Generate meeting prep docs with full context |
| `/secretary:assess` | Performance review comparison workflow |
| `/secretary:draft-reply` | Draft a reply in your voice with memory context |
| `/secretary:review-doc` | Review a document and post targeted comments |
| `/secretary:improve` | Audit and optimize the entire memory system |
| `/secretary:upgrade` | Align data files with latest plugin scaffold |


## Connectors

The plugin uses whatever integrations are already available in your session —
org-level connectors configured by your admin, or personal connectors you've
set up in Claude Desktop. No additional MCP configuration needed.

Skills reference generic connector categories (e.g. `~~messaging`, `~~email`)
so they work regardless of your tool stack. See [CONNECTORS.md](CONNECTORS.md)
for the full mapping.

## Memory Structure

```
secretary/
├── CLAUDE.md              # Hot cache (~100 lines) — loaded every session
├── memory/
│   ├── my-work.md         # Tasks, priorities, wins, goals
│   ├── people/            # Per-person files
│   │   ├── jane-doe.md
│   │   └── _relationship-map.md
│   ├── projects.md        # Active initiatives
│   ├── dynamics.md        # Org politics, sensitivities
│   ├── company.md         # Org structure, systems
│   └── meetings.md        # Recurring meetings, templates
├── outputs/               # Generated artifacts
│   ├── meeting-prep/
│   ├── assessments/
│   ├── drafts/
│   └── reviews/
└── sync/
    └── sources.md         # External source configuration
```

## Version History

The `secretary/` folder is git-initialized during setup. Memory files are
clean snapshots of current truth — git provides the changelog. You can:

```bash
cd secretary
git log --oneline           # See what changed and when
git diff HEAD~1             # See the last update
git log -- memory/people/   # Track changes to people files
```

## Customization

### Adding Company Context

Edit the memory files in `secretary/memory/` to add your company's specific:
- Org structure and team composition (`company.md`)
- Active projects and initiatives (`projects.md`)
- People profiles and coaching points (`people/`)
- Meeting schedules and prep templates (`meetings.md`)

### Adjusting Voice

The "User Voice" section in CLAUDE.md defines how drafted text sounds. Since
CLAUDE.md is loaded every session, your voice guidelines are always active.
To customize, edit the `## User Voice` section in your CLAUDE.md.

### Adding Sync Sources

Edit `secretary/sync/sources.md` to add Notion databases, Slack channels,
and other sources to monitor.

## Architecture

```
plugin/
├── .claude-plugin/plugin.json    # Manifest
├── hooks/                        # SessionStart detects memory root, loads CLAUDE.md
│   ├── hooks.json
│   └── detect-root.sh
├── CONNECTORS.md                 # Tool-agnostic connector mapping
├── skills/                       # 10 skills (commands)
├── agents/                       # Sync worker agent
└── scaffold/                     # Template for memory folder initialization
```

The key architectural decision: **the plugin is stateless**. All persistent
state lives in the user's project folder, not in the plugin. This means plugin
updates don't affect your data. The SessionStart hook auto-detects the memory
folder location across environments (Cowork mounted folder or local dev).
