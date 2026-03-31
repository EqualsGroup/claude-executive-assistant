---
name: improve
description: >
  Full system improvement — mines recent sessions for missed insights, audits
  memory architecture, performs hygiene cleanup, removes stale content, fixes
  cross-references, and optimizes the EA system. Use when the user says
  "improve", "clean up", "audit", or "optimize the system".
---

## Instructions

### Execution Architecture

```
Phase 1: Read (main agent, parallel reads)
    │
    ├── Extract session messages since last improve (main agent, bash)
    │
    ▼
Phase 2: Analyze (7 parallel subagents — all research-only, no file edits)
    │
    ├── Subagent 1: Session Mining — Decisions & Context
    ├── Subagent 2: Session Mining — Missed Work Items
    ├── Subagent 3: Session Mining — People & Relationships
    ├── Subagent 4: Session Mining — Workflow Patterns
    ├── Subagent 5: Architecture Review (structure, context budget, CLAUDE.md, skills, sync sources)
    ├── Subagent 6: Hygiene Audit (completed items, duplication, stale content, reference integrity)
    └── Subagent 7: Outputs Cleanup (digest unique content from outputs/ into memory, then delete)
    │
    ▼
Phase 3: Apply (main agent — consolidates all subagent findings, applies tiered changes)
    │
    ▼
Phase 4: Report + timestamp (main agent — structured summary, update last-improve marker)
```

**Why this shape:** Phase 2's seven concerns are independent — they read the same inputs but look for different things. Running them in parallel cuts wall-clock time vs sequential. The main agent handles file reads (Phase 1), session extraction (bash), and all file edits (Phase 3) to avoid conflicts.

---

### Phase 1: Read & Extract (main agent)

**Step 1 — Read all files in parallel:**
Read everything from `$SECRETARY_ROOT/`:
- All memory files in `memory/`
- `CLAUDE.md`
- `sync/sources.md`
- All files in `outputs/`
- All skill files (from the plugin's `skills/` directory)

**Step 2 — Extract session messages since last improve:**

Check when `/improve` was last run — the timestamp is on line 1 of `$SECRETARY_ROOT/CLAUDE.md`:
```bash
head -1 $SECRETARY_ROOT/CLAUDE.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z' || echo "never"
```
The format is `*Last improved: 2026-03-17T15:30Z*`. If no timestamp found, default to 7 days ago.

Session history is stored differently depending on the environment. Search **all available locations** and combine results:

**Location 1 — Claude Code** (`~/.claude/projects/`):
Sessions are stored per-project, keyed by the encoded working directory (non-alphanumeric chars replaced with `-`). Since the EA plugin can be active in **any** project, search all recent session files across all projects.

**Location 2 — Cowork / Claude Desktop** (`~/Library/Application Support/Claude/`):
Sessions are stored under `claude-code-sessions/` (current) or `local-agent-mode-sessions/` (legacy), grouped by account/org rather than project.

**Search both locations, use whichever exist:**
```bash
LAST_IMPROVE=$(head -1 $SECRETARY_ROOT/CLAUDE.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z' || echo "")
if [ -z "$LAST_IMPROVE" ]; then
  DAYS_AGO=7
else
  IMPROVE_DATE=$(echo "$LAST_IMPROVE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
  IMPROVE_EPOCH=$(date -d "$IMPROVE_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$IMPROVE_DATE" +%s 2>/dev/null || echo "")
  NOW_EPOCH=$(date +%s)
  if [ -n "$IMPROVE_EPOCH" ]; then
    DAYS_AGO=$(( (NOW_EPOCH - IMPROVE_EPOCH) / 86400 + 1 ))
  else
    DAYS_AGO=7
  fi
fi

# Claude Code sessions
find ~/.claude/projects/ -name "*.jsonl" -mtime -"$DAYS_AGO" 2>/dev/null | head -20

# Cowork / Claude Desktop sessions (current location)
find ~/Library/Application\ Support/Claude/claude-code-sessions/ -name "*.jsonl" -mtime -"$DAYS_AGO" 2>/dev/null | head -20

# Cowork / Claude Desktop sessions (legacy location)
find ~/Library/Application\ Support/Claude/local-agent-mode-sessions/ -name "*.jsonl" -mtime -"$DAYS_AGO" 2>/dev/null | head -20
```

Combine all results. **Filter to EA sessions only** — most session files won't be EA-related. For each candidate file, do a quick check before full parsing:
```bash
grep -l "SECRETARY_ROOT" "$file" 2>/dev/null
```
Only process files that contain `SECRETARY_ROOT` — this confirms the EA plugin was active in that session. Discard the rest.

If no EA session files are found in any location, skip session mining entirely — the architecture/hygiene subagents (5, 6, 7) don't need session data and should still run.

For each matching session file (skip any >10MB), try multiple extraction patterns since the JSONL schema varies:
```bash
# Try both "human" and "user" type fields, and handle both string and array message formats
jq -r 'select(.type == "user" or .type == "human") | .message |
  if type == "string" then .
  elif type == "object" then (.content // empty) | if type == "string" then . elif type == "array" then .[] | select(.type == "text") | .text else empty end
  elif type == "array" then .[] | select(.type == "text") | .text
  else empty end' "$file" 2>/dev/null | head -200
```

Filter out noise: skip lines starting with `<` (XML tags), `[` or `{` (JSON tool results), and lines >500 characters (skill expansions). Focus on short, direct user messages.

Collect all extracted user messages. Note the filename (which contains a timestamp/ID) so subagents can reference session dates.

**If session extraction partially fails** (some files unreadable, jq errors, empty results), proceed with whatever data was extracted. Note which sessions failed in the Phase 4 report. The architecture/hygiene subagents (5, 6, 7) don't need session data and should always run regardless.

**Step 3 — Prepare subagent payloads:**
Each subagent needs: the extracted user messages + the relevant memory file contents. Compose these as part of each subagent's prompt. Pass the content directly — subagents should NOT need to re-read files or re-extract sessions.

---

### Phase 2: Analyze (7 parallel subagents)

Launch all 7 subagents simultaneously. Each is research-only — returns structured findings, edits nothing.

#### Subagent 1: Session Mining — Decisions & Context
**Input:** All user messages + all memory file contents
**Task:**
- Scan for decision signals: "let's go with", "I decided", "we agreed", "the plan is", "going to", "confirmed", "approved", "actually let's", "changed my mind"
- Scan for context the user explains that should be in memory: how things work, relationships, historical context, explanations of why
- Cross-reference each finding against memory files
- Flag anything discussed but not captured
- Flag topics re-explained across multiple sessions (= memory gap)
**Output:** List of uncaptured decisions and context gaps, with session identifiers

#### Subagent 2: Session Mining — Missed Work Items
**Input:** All user messages + `my-work.md` content
**Task:**
- Scan for commitment language: "I need to", "I'll", "remind me", "follow up", "TODO", "action item", "I should", "I have to", "I promised", "committed to"
- Cross-reference each against `my-work.md` Master List (all tiers)
- Ignore items clearly completed in the same session
- Flag anything discussed but never added
**Output:** List of potential missing work items with session context

#### Subagent 3: Session Mining — People & Relationships
**Input:** All user messages + all person files from `memory/people/` + `dynamics.md` content
**Task:**
- Extract all person names mentioned
- Cross-reference against people/dynamics files
- Flag people appearing in 3+ sessions with thin (< 5 lines) or no entries
- Look for relationship dynamics, opinions, or observations not captured
**Output:** List of people gaps and uncaptured dynamics

#### Subagent 4: Session Mining — Workflow Patterns
**Input:** All user messages + all skill file contents
**Task:**
- Identify repetitive multi-step workflows across sessions
- Look for manual work complaints: "every time I have to", "this is tedious", "I keep doing"
- Map common workflows against existing skills
- Identify tool usage patterns suggesting missing automation
**Output:** List of skill improvements and new skill candidates

#### Subagent 5: Architecture Review
**Input:** All memory file contents + CLAUDE.md + sync/sources.md + all skill files + session message summaries (topic frequency, not full text)
**Task:**
- **Structure audit:** For each memory file, count lines per ## and ### section. Flag sections >100 lines. Flag sections with zero session references (stale). Identify session topics with no home (missing).
- **Context budget:** Estimate tokens per file. Flag low-value-per-token sections. Flag sections where >50% is historical/resolved.
- **Context placement:** Assess whether content is in the right file given CLAUDE.md's Context Placement Rule. CLAUDE.md is loaded every session — it should contain only rules, routing, voice guidelines, and cross-cutting principles (~200 lines max). Domain-specific content belongs in memory files. Flag: (a) domain-specific content that leaked into CLAUDE.md (move to memory file), (b) cross-cutting rules in memory files that should be in CLAUDE.md, (c) high-frequency session topics whose context is in a file that's rarely loaded (wrong routing), (d) CLAUDE.md memory file registry accuracy — do trigger words, format headers, and descriptions still match actual file contents?
- **CLAUDE.md review:** Compare instructions against session patterns. Flag unused rules, missing instructions, outdated conventions. Verify CLAUDE.md stays under ~200 lines.
- **Skill coverage:** Map session workflows against skills. Flag gaps and mismatches.
- **Sync sources:** Cross-reference sources.md against memory content. Flag unused/redundant sources.
- **Skill execution efficiency:** Analyse each skill's SKILL.md for agent orchestration optimisation opportunities. Specifically assess:
  - **Parallelism:** Are there sequential phases that could run as parallel subagents instead? Look for phases with independent inputs/outputs — if phase B doesn't depend on phase A's results, they should run concurrently.
  - **Subagent decomposition:** Are there monolithic phases doing multiple unrelated tasks? Each concern should be a separate subagent so they run in parallel.
  - **Data flow:** Are subagents re-reading files the main agent already read? Data should be passed into subagent prompts directly. Flag any skill where subagents are instructed to read files themselves.
  - **Main agent vs subagent split:** Only the main agent should do file I/O (reads at start, edits at end). Subagents should be pure analysis/research. Flag skills where subagents edit files or where the main agent does analysis work that could be delegated.
  - **Fan-out/fan-in pattern:** The ideal shape is: main agent reads -> fan out to N parallel subagents -> fan in results -> main agent applies. Flag skills that don't follow this pattern and could benefit from it.
  - For each skill, output: current execution shape (sequential/parallel/mixed), recommended shape, specific changes, estimated speedup.
**Output:** Structured architecture report with data-backed findings (line counts, reference frequencies) + skill execution efficiency assessment

#### Subagent 6: Hygiene Audit
**Input:** All memory file contents
**Task:**
- **Completed items:** Scan for `[x]`, "done"/"resolved"/"completed"/"shipped"/"delivered"/"merged"/"closed"/"landed", `~~strikethrough~~`. For each, note if win-worthy.
- **Cross-file duplication:** Flag content in 3+ files. Note which file should own it.
- **People entries:** Check for missing roles, missing domains for direct reports, orphan fragments.
- **meetings.md coverage:** Verify all direct reports have 1:1 entries, upcoming events listed, prep notes current.
- **Stale technical changes:** Flag merged/closed PRs and items >2 weeks stale.
- **Dynamics ordering:** Check high-sensitivity items are at top.
- **Priority accuracy:** Check dashboard matches actual Now list urgency.
- **Stale wins:** Flag wins >6 months old with no ongoing relevance.
- **Orphan tracking:** Flag Track items with zero session mentions.
- **Reference integrity:** Find all cross-references, verify targets exist.
**Output:** Categorized list of issues with file, section, and recommended action

#### Subagent 7: Outputs Cleanup
**Input:** List of all files in `$SECRETARY_ROOT/outputs/` directory + all memory file contents
**Task:**
- For each file in `outputs/` (meeting preps, proposals, assessments, announcements, transcripts, etc.):
  1. Read the file content
  2. Cross-reference against memory files — is the unique content already captured?
  3. Classify: **digest** (unique content not yet in memory), **stale** (already captured or one-time event now past), or **active** (still in progress, keep)
- For files classified as "digest":
  - Identify the target memory file(s) and section(s)
  - Extract the specific content that should be added (not full file — just the gaps)
  - Note any file references in memory files that point to this output (these need updating)
- For files classified as "stale":
  - Confirm no memory file references point to them
- For files classified as "active":
  - Note why they should be kept (e.g., "meeting hasn't happened yet", "decision still pending")
**Output:** For each file: classification, content to digest (if any), target memory location, and any stale references to fix. Return as structured data the main agent can act on.

---

### Phase 3: Apply Improvements (main agent)

Consolidate all 7 subagent results. Apply in three tiers:

#### Tier 1: Auto-apply (no permission needed)
- Remove completed items cleanly (promote win-worthy ones to Recent Wins first)
- Replace duplicated content with cross-references (`*See [file].md for details.*`)
- Fix broken cross-references
- Remove stale technical changes (merged/closed PRs)
- Reorder dynamics file (high-sensitivity items to top)
- Fill in missing people data where context allows
- **Outputs cleanup:** Digest unique content from stale output files into memory, update/remove stale file references in memory, then delete the output files. Keep files classified as "active" by Subagent 7.
- **Context placement fixes:** Move domain-specific content from CLAUDE.md to memory files. Move cross-cutting rules from memory files to CLAUDE.md. Update CLAUDE.md memory file registry (trigger words, format headers) to match actual file contents.

#### Tier 2: Propose with rationale (batch approval)
Present as a single list for user to approve/reject:
- New memory file sections (from architecture review)
- Section reordering within files (from session frequency analysis)
- Context placement changes that alter which file owns a topic (from architecture review)
- New work items in `my-work.md` (from session mining)
- New/updated people entries (from session mining)
- Skill file modifications (including execution architecture rewrites from efficiency assessment)

#### Tier 3: Report only (user decides later)
- New skill suggestions (from workflow patterns)
- Major architecture changes (file splits, new files, archiving)
- CLAUDE.md instruction changes
- Sync source changes
- Context window budget recommendations

---

### Phase 4: Report + Timestamp (main agent)

**Update the last-improve marker** on line 1 of `$SECRETARY_ROOT/CLAUDE.md` at the end of a successful run:
```bash
NEW_TS=$(date -u +%Y-%m-%dT%H:%MZ)
```
Then edit line 1 of `$SECRETARY_ROOT/CLAUDE.md` to: `*Last improved: $NEW_TS*`

**Report template:**

```
## Session Insights

### Uncaptured Decisions
- [decision] — from session [id/date]. Should live in [file].

### Memory Gaps (repeated context)
- [topic] — explained in [N] sessions. Suggests missing/thin coverage in [file].

### Missed Work Items
- [item] — mentioned in session [id/date], not in Master List.

### People Gaps
- [person] — mentioned in [N] sessions, thin/no entry.

### Skill Opportunities
- [pattern] — done manually [N] times, could be a skill.

## Architecture Findings

### Context Budget
| File | Lines | Est. Tokens | Session References | Value Density |
|------|-------|-------------|-------------------|---------------|

### Bloated Sections
- [file > section] — [N] lines, referenced [M] times.

### Missing Structure
- [topic] — discussed in [N] sessions, no home in memory.

### Stale Structure
- [file > section] — zero references in last 20 sessions.

### Context Placement
| Content | Current Location | Should Be | Reason |
|---------|-----------------|-----------|--------|
CLAUDE.md line count: [N] (target: ≤200)
Registry accuracy: [any trigger words, format headers, or descriptions that need updating]

### Skill Execution Efficiency
| Skill | Current Shape | Recommended Shape | Est. Speedup |
|-------|--------------|-------------------|--------------|
For each skill with optimisation opportunities:
- [skill] — [specific change: e.g. "Phase 2 and 3 are independent, run as parallel subagents"]

## Hygiene Changes Applied

### [filename]
- [what changed and why]

### Stats
- X completed items removed
- X duplications consolidated
- X entries filled in
- X stale items flagged
- X cross-references repaired
- X orphan tracking items flagged

## Outputs Cleanup

### Digested & Deleted
- [file] → digested [what] into [memory file > section]

### Kept (active)
- [file] — [reason]

### Stats
- X output files deleted
- X output files kept
- X memory references updated

## Proposed Changes (Tier 2 — awaiting approval)
- [change and rationale]

## Suggestions (Tier 3 — for later)
- [suggestion and rationale]

## Items Needing Input
- [anything ambiguous]
```

---

## Rules

- **All subagents are research-only.** They return findings. Only the main agent edits files (Phase 3).
- **Launch all 7 subagents in a single message** to maximize parallelism. Do NOT wait for one before launching the next.
- **Pass data into subagent prompts directly** — subagents should not re-read files or re-extract sessions. This avoids redundant I/O and keeps subagents fast.
- **Fix everything you can in Tier 1.** Only flag items you genuinely can't resolve without user input.
- **Don't auto-add content from sessions** — propose in Tier 2. Session mining produces candidates, not certainties.
- **Cross-reference format:** `*See [file].md for details.*` or `*See [section] in [file].md.*`
- **Win-worthy items** being removed -> add to Recent Wins before deletion.
- **Preserve context** — when removing a completed item, keep still-relevant monitoring notes.
- **Skip session files >10MB.** Cap subagent prompts to avoid context overflow.
- **Never quote session content verbatim** — summarize. Sessions may contain sensitive unfiltered thoughts.
- **Architecture suggestions must cite data** — "section X is N lines, referenced 0 times" not "seems unnecessary."
- **If a subagent fails or times out**, proceed with partial results from the others. Report what was missed.
