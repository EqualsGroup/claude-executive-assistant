---
name: done
description: >
  Process daily completion notes — remove done items from memory, promote wins,
  update cross-references. Use when the user says "done", "finished", "completed",
  "shipped", or lists things they've accomplished.
---

## Instructions

Process the user's "done" items and update all memory files accordingly.

### Phase 1: Read current state (parallel)

Read all memory files from `$EA_ROOT/` in parallel:
- `memory/my-work.md`
- `memory/projects.md`
- `memory/people/` — read all person files
- `memory/dynamics.md`
- `memory/company.md`
- `memory/meetings.md`

### Phase 2: Parse done items

For each item the user mentions as completed:

1. **Classify:** Task completion, project milestone, people observation, decision, or FYI
2. **Locate** the item across all memory files — check my-work.md Master List (all tiers: Now, Next, Later, Parked) and Track sections, projects.md for related initiatives, and memory/people/ for related person files
3. **Assess win-worthiness** — CV-worthy, demonstrates impact, or shows initiative?

### Phase 3: Apply changes

**Task completions:**
1. Remove from my-work.md (clean removal, no strikethroughs)
2. If win-worthy, add to the appropriate Recent Wins subsection in my-work.md
3. Update projects.md if related to an initiative
4. Update person files if someone notable was involved

**Project milestones:**
1. Update status in projects.md
2. Remove related tracking items from my-work.md
3. Add to Recent Wins if win-worthy

**People observations:**
1. Update the person's file in `memory/people/`
2. Update dynamics.md if it reveals a team/org dynamic

**Decisions:**
1. Add to the appropriate memory file
2. If the decision creates new work, add to my-work.md

**FYI items:**
1. Route to the appropriate memory file
2. Only add to my-work.md if the user needs to act on it

### Phase 4: Confirm

Report what was updated:
```
## Done Processing

### Removed from my-work.md
- [item] (was in [tier])

### Added to Recent Wins
- [item] — [why it's a win]

### Updated
- [file]: [what changed]

### New items added
- [item] → [file] ([tier] if my-work.md)
```

## Rules

- Never use strikethroughs — clean removal only
- Don't ask for confirmation — apply directly
- Be aggressive about removal — if the user says it's done, it's done
- Be conservative about wins — not every completion is a win
- Preserve still-relevant context — if a completed item has monitoring notes that are still active, keep the monitoring note and remove only the completed action
- Cross-update — a single done item may touch multiple files
- Items the user marks as done for others — update projects.md and the person's file in `memory/people/` but only remove from my-work.md if it was the user's tracking item
