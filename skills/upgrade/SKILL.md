---
name: upgrade
description: >
  Compare user's data files against the current plugin scaffold to find and fix
  structural drift — missing sections, wrong placements, format mismatches,
  CLAUDE.md rule drift, stale placeholders, and directory gaps. Use when the
  user says "upgrade", "check for updates", "compare scaffold", or after a
  plugin update.
---

## Instructions

### Purpose

When the plugin evolves — new sections added, conventions changed, rules updated
— existing user data directories fall out of sync. `/improve` handles content
quality; `/upgrade` handles **structural alignment** with the canonical scaffold.

Run this after plugin updates, or periodically to catch drift.

### Execution Architecture

```
Phase 1: Read (main agent, parallel reads)
    │
    ├── Read all user data files from $SECRETARY_ROOT/
    ├── Read all scaffold templates from ${CLAUDE_PLUGIN_ROOT}/scaffold/
    │
    ▼
Phase 2: Analyze (4 parallel subagents — all research-only, no file edits)
    │
    ├── Subagent 1: Structure & Sections — missing/extra/reordered sections
    ├── Subagent 2: CLAUDE.md Drift — rules, routing, registry accuracy
    ├── Subagent 3: Conventions & Format — heading levels, frontmatter, naming
    └── Subagent 4: Placement & Migration — wrongly placed content, deprecated patterns
    │
    ▼
Phase 3: Apply (main agent — consolidates findings, applies tiered changes)
    │
    ▼
Phase 4: Report (main agent — structured summary)
```

**Why this shape:** The four concerns are independent reads of the same data.
Parallel subagents cut wall-clock time. The main agent handles all file I/O.

---

### Phase 1: Read (main agent)

**Step 1 — Read all user data files in parallel:**

From `$SECRETARY_ROOT/`:
- `CLAUDE.md`
- All files in `memory/` (including `memory/people/*`)
- `sync/sources.md`
- List of all files/directories in `outputs/`

**Step 2 — Read all scaffold templates in parallel:**

From `${CLAUDE_PLUGIN_ROOT}/scaffold/`:
- `CLAUDE.md`
- All files in `memory/` (including `memory/people/*`)
- `sync/sources.md`

Also list the expected directory structure:
```bash
find "${CLAUDE_PLUGIN_ROOT}/scaffold/" -type d | sed "s|${CLAUDE_PLUGIN_ROOT}/scaffold/||"
```

**Step 3 — Prepare subagent payloads:**

Each subagent receives: full content of all user data files + full content of
all scaffold templates. Pass content directly — subagents should NOT re-read files.

---

### Phase 2: Analyze (4 parallel subagents)

Launch all 4 subagents simultaneously. Each is research-only — returns
structured findings, edits nothing.

#### Subagent 1: Structure & Sections

**Input:** All user data files + all scaffold templates
**Task:**

For each scaffold file, compare against the corresponding user data file:

1. **Missing sections:** Scaffold has `## Section` or `### Section` headers
   that don't exist in the user's file. These represent new features or
   organizational improvements added since setup.
   - Distinguish between _structural sections_ (headings that organize content)
     and _template examples_ (headings inside code blocks, HTML comments, or
     clearly marked as examples like `#### [Name]`). Only flag missing
     structural sections.

2. **Extra sections:** User's file has sections not in the scaffold. These are
   fine if they contain real data — flag only if they look like they were
   copied from an old scaffold version and never populated (empty or still
   have placeholder text).

3. **Section ordering:** Check if the user's sections follow the scaffold's
   ordering. Minor drift is fine — flag only when it causes functional issues
   (e.g., Dashboard not at top of my-work.md, HIGH Sensitivity not at top of
   dynamics.md).

4. **Missing directories:** Check the user's directory structure against the
   scaffold's expected directories:
   - `memory/people/`
   - `outputs/meeting-prep/`
   - `outputs/assessments/`
   - `outputs/drafts/`
   - `outputs/proposals/`
   - `outputs/reviews/`
   - `sync/`

5. **Missing files:** Scaffold has files that don't exist in the user's data at
   all (e.g., a new memory file was added to the scaffold).

**Output:** For each finding: file, section, issue type (missing/extra/ordering/
directory), scaffold reference, recommended action.

#### Subagent 2: CLAUDE.md Drift

**Input:** User's CLAUDE.md + scaffold CLAUDE.md
**Task:**

The scaffold CLAUDE.md contains the canonical rules, routing table, and
conventions. The user's CLAUDE.md should have all of these plus their
customizations. Compare them:

1. **Missing rules/instructions:** Scaffold has paragraphs, bullet points, or
   sections that don't appear in the user's file. These are new rules added
   since setup. For each, determine:
   - Is it a _rule_ (behavioral instruction)? → Must be added.
   - Is it a _template/placeholder_ (e.g., `[Your Name]`)? → Skip if the user
     has already customized this section.

2. **Modified rules:** User's file has a rule that's similar to but different
   from the scaffold version. Flag only if the scaffold version is strictly
   better (e.g., more complete, fixes a bug in the instruction). Don't flag
   legitimate user customizations.

3. **Memory File Registry accuracy:** Compare the registry table in the user's
   CLAUDE.md against the scaffold's. Check:
   - Missing files (new memory files added to scaffold)
   - Wrong trigger words
   - Wrong/outdated purpose descriptions
   - Wrong format reference strings

4. **Outdated conventions:** User's CLAUDE.md references conventions or patterns
   that the scaffold no longer uses.

5. **Line count:** Check if user's CLAUDE.md exceeds ~200 lines. If so, flag
   sections that could be moved to memory files per the Context Placement Rule.

**Output:** For each finding: location (line range or section), issue type
(missing-rule/modified-rule/registry-drift/outdated-convention/bloated),
scaffold reference, recommended action. Include the exact text to add/replace
where applicable.

#### Subagent 3: Conventions & Format

**Input:** All user data files + all scaffold templates
**Task:**

1. **Frontmatter:** Each memory file and sync/sources.md should start with
   `*Last synced: [date or never]*`. CLAUDE.md should start with
   `*Last improved: [date or never]*`. Flag files missing this.

2. **Heading hierarchy:** Check that heading levels are consistent:
   - File title: `# Title`
   - Major sections: `## Section`
   - Subsections: `### Subsection`
   - Flag any heading level skips (e.g., `#` → `###` without `##`)

3. **People file format:** Each file in `memory/people/` should follow:
   ```
   # Full Name
   **Role:** ...
   **Domain:** ...
   ## Working Style
   ## Coaching Points
   ## Performance Review Insights
   ## Current Focus
   ## Recent Context
   ```
   Flag files missing required sections or using wrong heading levels.
   Flag files not using kebab-case naming (`first-last.md`).

4. **Placeholder remnants:** Scan all files for unfilled `[square bracket]`
   placeholders. Ignore:
   - Placeholders in code blocks or HTML comments
   - Markdown links `[text](url)`
   - Checkboxes `[x]` or `[ ]`
   - Known template patterns meant to stay (e.g., `[Name]` in meetings.md
     template sections)

5. **Stale sync timestamps:** Flag any file where `*Last synced:*` is older
   than 30 days (suggests the file isn't being maintained).

6. **People migration check:** If `memory/people.md` exists (monolithic format),
   flag for migration to per-person files in `memory/people/`.

**Output:** For each finding: file, location, issue type, recommended fix.

#### Subagent 4: Placement & Migration

**Input:** All user data files + all scaffold templates + scaffold CLAUDE.md
(for Context Placement Rules and format reference)
**Task:**

1. **Wrongly placed data:** Using the format reference from CLAUDE.md, check
   whether content in each file actually belongs there:
   - Work items (tasks, TODOs, commitments) outside `my-work.md` →
     should be in my-work.md Master List
   - Person-specific info (working style, coaching points) outside
     `memory/people/` → should be in person files
   - Domain-specific content in `CLAUDE.md` → should be in a memory file
   - Cross-cutting rules in memory files → should be in CLAUDE.md
   - Project/initiative details in `my-work.md` → should be in projects.md
     (my-work.md tracks _your_ tasks, not project status)
   - Meeting-specific content outside `meetings.md` → should be in meetings.md
   - Dynamics/sensitivity content outside `dynamics.md` → should be in
     dynamics.md

2. **Deprecated patterns:** Check for patterns the scaffold no longer uses:
   - Monolithic `people.md` (should be per-person files)
   - Strikethroughs `~~text~~` in memory files (should be clean-removed)
   - `[x]` completed checkboxes still present (should be removed)
   - Revision annotations ("Updated on...", "Changed from...", "Previously...")
   - Self-referential commentary ("Claude learned...", "Added based on...")

3. **sources.md structure:** Compare user's `sync/sources.md` against scaffold:
   - Missing source categories (e.g., new connector type added)
   - Wrong table formats
   - Missing configuration fields

4. **Output directory naming:** Check files in `outputs/` follow conventions:
   - `meeting-prep/YYYY-MM-DD-[name].md`
   - `assessments/[name]/`
   - `drafts/YYYY-MM-DD-[recipient]-[topic].md`
   - `reviews/YYYY-MM-DD-[doc-name].md`

**Output:** For each finding: file, content snippet, current location, correct
location, issue type, recommended action.

---

### Phase 3: Apply Improvements (main agent)

Consolidate all 4 subagent results. Apply in three tiers:

#### Tier 1: Auto-apply (no permission needed)

These are safe structural additions that don't modify existing content:

- **Create missing directories** (mkdir -p)
- **Add missing sections** to files — insert at the correct position with the
  scaffold's default content (empty or with standard comments). Never overwrite
  existing sections.
- **Fix heading hierarchy** — adjust heading levels where they skip
- **Add missing frontmatter** (`*Last synced: never*` or `*Last improved: never*`)
- **Remove deprecated patterns** — delete `~~strikethroughs~~`, `[x]` completed
  items, revision annotations, self-referential commentary
- **Update Memory File Registry** in CLAUDE.md — add missing entries, fix
  trigger words and format references to match current scaffold
- **Add missing CLAUDE.md rules** — append new rules/sections that exist in
  scaffold but not in user's file. Insert at the correct location. Never
  modify user's customized sections.

#### Tier 2: Propose with rationale (batch approval)

Present as a single list for user to approve/reject:

- **Move wrongly placed content** — show source, destination, and why
- **Replace modified rules** in CLAUDE.md — show diff of scaffold vs user version
- **Migrate monolithic people.md** to per-person files
- **New memory files** from scaffold that don't exist yet (require user to
  decide if they want them)
- **sources.md structural changes** — new source categories or config fields

#### Tier 3: Report only (user decides later)

- **Stale placeholders** — list them so user can fill in during normal use
- **Stale sync timestamps** — suggest running /sync
- **CLAUDE.md over 200 lines** — suggest what to move out
- **Output naming violations** — informational, user can rename if they care
- **Extra sections** not in scaffold — informational, user may want to keep them

---

### Phase 4: Report (main agent)

**Report template:**

```
## Upgrade Summary

**Plugin version:** [version from plugin.json]
**Data location:** $SECRETARY_ROOT

### Structure Alignment

| File | Missing Sections | Added | Extra (kept) |
|------|-----------------|-------|--------------|

### Directories
- [Created/already existed]

### CLAUDE.md Drift

| Change | Type | Action |
|--------|------|--------|
| [description] | missing-rule / registry-drift / ... | auto-applied / proposed / reported |

CLAUDE.md line count: [N] (target: ≤200)

### Format Fixes Applied
- [file] — [what was fixed]

### Content Placement Issues

| Content | From | Should Be In | Action |
|---------|------|-------------|--------|
| [snippet] | [file:section] | [file:section] | proposed / reported |

### Deprecated Patterns Removed
- [file] — [what was removed]

### Stale Placeholders (fill when convenient)
- [file:line] — `[placeholder text]`

### Proposed Changes (Tier 2 — awaiting approval)
- [change and rationale]

### Suggestions (Tier 3 — for later)
- [suggestion and rationale]

### Stats
- X sections added
- X directories created
- X rules synced to CLAUDE.md
- X format issues fixed
- X deprecated patterns removed
- X placement issues found
- X stale placeholders found
```

---

## Rules

- **All subagents are research-only.** They return findings. Only the main agent edits files (Phase 3).
- **Launch all 4 subagents in a single message** to maximize parallelism.
- **Pass data into subagent prompts directly** — subagents should not re-read files.
- **Never delete user content.** Adding missing structure is safe. Moving or removing content requires approval.
- **Scaffold is the source of truth for structure.** User data is the source of truth for content. Don't replace user's filled-in content with scaffold placeholders.
- **Preserve user customizations.** If a user has renamed a section, added custom sections, or changed wording, don't revert it unless it causes a functional issue.
- **CLAUDE.md merge strategy:** Add missing rules at the correct location. Never overwrite the `## Important Context` section or any section the user has clearly customized (contains no `[placeholder]` text).
- **Idempotent:** Running /upgrade twice in a row should produce no changes on the second run.
- **Git commit after changes:** After applying Tier 1 changes and any approved Tier 2 changes, commit with message: `upgrade: align data files with plugin scaffold vX.Y.Z`
