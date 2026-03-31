# Connector Mapping

Skills in this plugin use generic connector categories (prefixed with `~~`) so they
work regardless of which specific tool you've wired up. The plugin relies on
whatever connectors are already available in your session — configured at the org
level by your admin, or personally in Claude Desktop.

| Category | Typical Connector | Alternatives |
|----------|------------------|--------------|
| ~~messaging | Slack | Microsoft Teams, Discord |
| ~~project-tracker | Notion | Linear, Jira, Asana, Monday, ClickUp |
| ~~email | Microsoft 365 (Outlook) | Google Workspace (Gmail) |
| ~~calendar | Google Calendar | Microsoft 365 (Outlook Calendar) |
| ~~documents | Notion | Google Docs, Confluence |
| ~~hr-system | BambooHR (via browser) | Workday, HiBob, Lattice |
| ~~code | GitHub (via `gh` CLI or API token) | GitLab, Bitbucket |

Skills gracefully handle missing connectors — if a source isn't available, it's
skipped during sync and the setup wizard flags what's missing.
