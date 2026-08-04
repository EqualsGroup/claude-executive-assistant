---
name: sync
description: >
  Sync memory files from external sources (~~documents, ~~messaging, ~~code)
  using parallel subagents. Use when the user says "sync", "refresh", "pull
  latest", or "update from sources".
---

## Instructions

### Phase 1: Read current state (parallel)

Read these files from `$EA_ROOT/` in parallel:
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
  **If `api-token`:** Read the token from `$EA_ROOT/.github-token` and use
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
2. Draft proposed changes. **Every change must name a target file AND a target section that already exists in that file.** If nothing fits, say so in the report and ask — do not invent a new top-level section, and never create a dated one.

   | Finding | File > Section |
   |---|---|
   | New/changed initiative or epic | projects.md > ## Active Initiatives |
   | Priority shift | projects.md > ## Current Priorities |
   | Incident opened/updated | projects.md > ## Active Incidents (resolved = remove) |
   | Significant architectural change, or stalled >2wk | projects.md > ## In-Flight Technical Changes |
   | Release state | projects.md > ## Release Approval Queue |
   | New service, tool or URL | projects.md > ## Systems & Platforms, or company.md > ## Key Systems / ## Key Tools / ## Service URLs |
   | Action the user must take | my-work.md > ## Master List > ### Now / Next / Later / Parked |
   | Completed item | my-work.md — remove from Master List; if win-worthy add to ## Recent Wins |
   | Recurring failure pattern | my-work.md > ## Systemic Issues |
   | Person observation, working style, coaching signal | memory/people/[first-last].md > matching ## heading |
   | Sensitivity, friction, political risk | dynamics.md > ## HIGH Sensitivity / ## Team Dynamics / ## Event-Based Dynamics / ## Organizational Sensitivities |
   | Org structure, domain ownership, process change | company.md > ## Engineering Organization / ## Key Processes / ## Recent Changes |
   | Meeting recording, cadence change, prep note | meetings.md > ## Recurring Meetings > relevant subsection |

   For each change state one of: **NEW** (add a bullet inside that section), **UPDATE** (rewrite an identified existing bullet — quote the line you are replacing), or **REMOVE** (resolved or superseded).

   `company.md > ## Recent Changes` is a curated rolling list of *org* changes, not a per-run log. Cap it at ~15 bullets and drop the oldest.
3. Present summary and **ask before applying** — sync is an exception to the "never ask for confirmation" rule because it proposes bulk changes across multiple memory files at once; the user should review the batch before it's written.
4. When applying, set `*Last synced:*` to the earliest `pull_timestamp` returned by the subagents — **NOT** the current time (data may have changed between the fetch and the apply)

## Rules

- **Merge, don't append.** Every finding lands *inside* an existing canonical section. Superseded text is rewritten in place, not left alongside the new version. Removing an entry is correct when this run's findings supersede or resolve it — that is not licence to delete unrelated content.
- Do NOT add duplicate content already captured
- Ask about ambiguous items rather than guessing
- Subagents are research-only — all edits happen in main agent after user approval
- When adding work items discovered in ~~messaging, follow the my-work.md conventions (Now/Next/Later tiers)
- my-work.md items must be actionable — only add items where the user needs to act, decide, follow up, or monitor an outcome. Do NOT add FYI items, completed events, things other people own with no user involvement, or general awareness items. Those belong in projects.md, the relevant person's file in `memory/people/`, or company.md instead. If an item has no clear "user should do X" or "user needs to check Y", it does not belong in my-work.md.
- Set the `*Last synced:*` line on line 1 of each updated file to the ISO 8601 timestamp. **That line is the only thing written at the top of a memory file.**
- **NEVER create a dated section in a memory file.** Do not write headings of the form `## Recent Changes (<date>, <run> sync)`, `## <Month> <Day> ... Sync`, `### <date> sync — no new developments`, or anything containing `(added by ... sync)`. Memory files are a snapshot of current truth with no run history in them.
- **If a run finds nothing for a file, write nothing to that file.** Do not record "no new developments" in memory — record it in the sync report.
- **Precedent is not permission.** If a memory file already contains dated sections, that is drift left over from before this rule, not the format. Do not match it.
- Tooling quirks go in `sync/tooling-caveats.md` (edited only when the behaviour changes), never as notes prepended to `sync/sources.md` — that file is configuration, not a log.

### Phase 5: Write the sync report

Write the run narrative to `$EA_ROOT/sync/YYYY-MM-DD-<run>-sync-report.md` (`<run>` = morning | midday | evening | scheduled). **This file is the only place a dated account of the run is recorded.**

```
# Sync Report — YYYY-MM-DD <Run>
**Cutoff:** <iso> → **Pull window end:** <iso>   **Mode:** <attended|scheduled>
## Subagents run
## Changes applied (file > section > NEW/UPDATE/REMOVE)
## Findings not written to memory (judgement calls)
## Open items surfaced
## Tooling/data-quality notes
```
