*Last updated: <!-- CUSTOMIZE: date -->*

# Tooling Caveats

Stable, known quirks of the tools `/ea:sync` and `/ea:inbox` rely on. Each entry is stated **once**, with its workaround.

**Do not append a new note per run.** If a caveat reproduces, that is expected — say so in the sync report, not here. Only edit this file when a caveat's behaviour actually changes, or a new one is found.

Keeping this separate from `sources.md` matters: `sources.md` is configuration (what to pull), this is operational knowledge (how the tools misbehave). Mixing them turns the config file into a log.

---

<!-- CUSTOMIZE: delete the example below and record your own as you hit them. -->

## Example — GitHub `reviewed-by:` / `commenter:` return stale hits

**Behaviour:** the search API filters on the issue-level `updated_at`, which reflects *other contributors'* later activity on the PR, not your own review timestamp. Bare-date qualifiers also match the whole calendar day rather than a time-of-day cutoff.

**Workaround:** cross-check each hit against `/pulls/{n}/reviews` or `/issues/{n}/comments` and compare the real timestamp to the cutoff. Append an explicit ISO timestamp to date qualifiers rather than using a bare date.
