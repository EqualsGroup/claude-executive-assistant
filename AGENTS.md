<!-- managed-public-guidance:v1 -->
# Repository guidance

- Read the README, CLAUDE.md, contribution guide and relevant documentation before editing.
- Follow repository-specific instructions, tooling and conventions, including instructions in nested directories.
- Keep changes focused and preserve unrelated work and existing repository guidance.
- Use an isolated worktree for code changes and follow the repository's branch and commit conventions.
- Use setup, build and test commands defined by the repository; inspect scripts before running them.
- Add a failing regression test for a bug, then make it pass with the smallest suitable change.
- Run relevant automated checks and manually verify the changed behaviour before reporting completion.
- Keep secrets, credentials and personal data out of source, test fixtures, logs and commits.
- Report what changed, the checks actually run and any unresolved limitations.
