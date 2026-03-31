# Connector Mapping

Skills in this plugin use generic connector categories (prefixed with `~~`) so they
work regardless of which specific tool you've wired up. The plugin relies on
whatever connectors are already available in your session — configured at the org
level by your admin, or personally in Claude Desktop.

| Category | Common Connectors |
|----------|------------------|
| ~~messaging | Slack, Microsoft Teams, Discord |
| ~~email | Outlook (Microsoft 365), Gmail (Google Workspace) |
| ~~calendar | Outlook Calendar, Google Calendar |
| ~~documents | Notion, Google Docs, Confluence, SharePoint |
| ~~project-tracker | Jira, Linear, Notion, Asana, Monday, ClickUp |
| ~~code | GitHub, GitLab, Bitbucket |
| ~~hr-system | Workday, BambooHR, HiBob, Lattice |
| ~~files | Google Drive, OneDrive, Dropbox, Box |

Skills gracefully handle missing connectors — if a source isn't available, it's
skipped during sync and the setup wizard flags what's missing.
