---
name: sync
description: >
  Sync memory files from external sources (~~documents, ~~messaging, ~~code)
  using parallel subagents. Use when the user says "sync", "refresh", "pull
  latest", or "update from sources".
---

## Instructions

### Phase 1: Read current state (parallel)

Read these files from `$SECRETARY_ROOT/` in parallel:
- `sync/sources.md` — all source URLs, channel IDs, key contacts
- `memory/company.md`
- `memory/people/` — all person files
- `memory/projects.md`
- `memory/my-work.md`
- `memory/dynamics.md`
- `memory/meetings.md`

Check the `*Last synced:*` line at the top of each memory file for an ISO 8601
timestamp. Use the oldest as the cutoff. If none exists, use 7 days ago.

Convert the cutoff timestamp to a Unix timestamp (seconds since epoch) for ~~messaging API calls.

### Phase 2: Fetch from all sources (parallel subagents)

Launch subagents in parallel — research only, no file edits. Only launch for
sources actually configured in `sync/sources.md`.

Each subagent must capture a UTC timestamp (`date -u +%Y-%m-%dT%H:%MZ`)
immediately before its first API call and return it as `pull_timestamp`.

#### Subagent 1: ~~documents Sources
- Use `mcp__notion__notion-query-data-sources` to fetch from each configured database
- Apply filters as specified in sources.md (e.g. Status, Type filters)
- Also fetch any secondary/reference sources if accessible
- Return structured summary of new/changed items

#### Subagent 2: ~~messaging Channels
- Load the ~~messaging tools using ToolSearch
- Read recent messages from monitored channels (only those with `Access: Yes` in sources.md) since cutoff. Pass the channel names and IDs directly into the subagent prompt from the sources file — do not hardcode channel lists in this skill.
- Use the `oldest` parameter with the Unix timestamp of the cutoff date
- Use `response_format: "concise"` to keep output manageable
- Return summary by channel: decisions, action items, status updates, dynamics

#### Subagent 3: ~~messaging DMs
- Load the ~~messaging tools using ToolSearch
- Use cached user IDs from `sync/sources.md` (User ID Cache table) — do NOT look up IDs at sync time unless someone is missing from the cache
- Search for recent DM conversations with each key contact using the messaging connector's search capabilities:
  - For each person in the "Key DM contacts to monitor" list, search their recent DMs since cutoff
  - Also run a broad catch-all for messages sent by and to the user
- For each DM conversation found, note:
  - Who the conversation was with (use full names)
  - Key topics discussed
  - Any decisions, commitments, or action items
  - Anything relevant to `memory/people/` (relationship dynamics, working style observations)
  - Anything relevant to my-work.md (new tasks, priorities)
- Return summary grouped by person (using full names)

#### Subagent 4: ~~code Activity
- Only launch if ~~code is configured in `sync/sources.md`
- Check the **Auth Method** in `sync/sources.md` to determine how to call the API:

  **If `env-token`:** Use `curl` with `-H "Authorization: Bearer ${GITHUB_TOKEN:-$GH_TOKEN}"`
  against `https://api.github.com/`. If neither variable is set, skip GitHub sync
  and note it in the results.
  **If `gh-cli`:** Verify `gh` is available and authenticated by running
  `gh auth status`. If the command fails (binary not found or not authenticated),
  skip GitHub sync and note it in the results. Otherwise use `gh api` commands
  as shown below.
  **If `api-token`:** Read the token from `$SECRETARY_ROOT/.github-token` and use
  `curl` with `-H "Authorization: Bearer {token}"` against `https://api.github.com/`.
  If the token file is missing or empty, skip GitHub sync and note it in the results.

- Fetch PRs authored, reviewed, and pending review since cutoff. Run the
  queries from the "What to Sync" table in `sync/sources.md` in parallel,
  using the GitHub Search Issues API endpoint (`/search/issues`).

  **Transport** (based on Auth Method):
  - **`gh-cli`:** `gh api search/issues --method GET -f q="{query}" -f per_page=30 --jq '.items[] | {repo: (.repository_url | split("/") | .[-1]), title: .title, state: .state, number: .number, user: .user.login, created: .created_at, updated: .updated_at, url: .html_url}'`
  - **`api-token`:** `curl -s -H "Authorization: Bearer {token}" "https://api.github.com/search/issues?q={query_url_encoded}&per_page=30"` — parse the JSON `.items[]` array to extract the same fields.

- For each PR authored, note which project/initiative it relates to and current state
- For PRs pending review, flag as potential action items for my-work.md
- Return: PRs authored (project context), PRs reviewed (people context), pending reviews (action items)

### Phase 3: Consolidate and propose changes

After all subagents return:

1. Compare results against current memory files
2. Draft proposed changes grouped by file:
   - **projects.md** — new/updated initiatives, status changes, active PRs showing current engineering work
   - **memory/people/** — new info about individuals, working style observations, collaboration patterns (create or update per-person files)
   - **company.md** — org structure changes, domain assignments
   - **my-work.md** — new action items, commitments discovered in ~~messaging, PRs pending review, in-flight PRs authored
   - **dynamics.md** — team dynamics, relationships, sensitivities observed
   - **meetings.md** — if any meeting-related info surfaces
3. Present summary and **ask before applying** — sync is an exception to the "never ask for confirmation" rule because it proposes bulk changes across multiple memory files at once; the user should review the batch before it's written.
4. When applying, set `*Last synced:*` to the earliest `pull_timestamp` returned by the subagents — **NOT** the current time (data may have changed between the fetch and the apply)

## Rules

- Do NOT remove existing memory entries unless explicitly told to
- Do NOT add duplicate content already captured
- Ask about ambiguous items rather than guessing
- Subagents are research-only — all edits happen in main agent after user approval
- When adding work items discovered in ~~messaging, follow the my-work.md conventions (Now/Next/Later tiers)
- my-work.md items must be actionable — only add items where the user needs to act, decide, follow up, or monitor an outcome. Do NOT add FYI items, completed events, things other people own with no user involvement, or general awareness items. Those belong in projects.md, the relevant person's file in `memory/people/`, or company.md instead. If an item has no clear "user should do X" or "user needs to check Y", it does not belong in my-work.md.
- Note sync timestamp (ISO 8601) at top of each updated file
