---
name: setup
description: >
  Interactive setup wizard — initializes the EA memory folder, fills in
  placeholders, and checks connector availability. Use when the user says
  "setup", "initialize", "get started", or when the SessionStart hook reports
  memory is not initialized.
---

## Instructions

### Phase 0: Detect Environment

1. Check the session context for `SECRETARY_ROOT`. If the SessionStart hook
   already output it, use that path.
2. If not set, detect the environment:
   - **Cowork**: Look for a user-mounted folder under `/sessions/*/mnt/` (any
     directory that is not `outputs` or `uploads`). If found, set
     `SECRETARY_ROOT` to `{mount}/secretary`.
   - **Claude Code / local dev**: Use `~/secretary/` (shared across all projects).
   - **Task session** (Cowork with no mount): Stop and tell the user:
     "EA needs a Project session with a folder selected. Please start
     a new Project and select your EA folder."
3. If `$SECRETARY_ROOT/memory` already exists, skip to Phase 0b then Phase 2.
4. If `$SECRETARY_ROOT` doesn't exist yet, confirm:
   "I'll create `~/secretary/` to store your persistent memory. This folder
   is shared across all your projects. OK?"

### Phase 0b: Migration Check

Check if the SessionStart hook set `LOCAL_SECRETARY` — this means the current
working directory has secretary files (from the old clone-based setup) that
differ from the shared location.

Also independently scan for secretary files in the current directory (`memory/`
dir + `CLAUDE.md` present) even if the hook didn't flag it.

**If local files found and shared location is empty (first-time plugin install):**
- Offer to move: "I found existing secretary files in `[cwd]`. Want me to move
  them to `~/secretary/` so they're shared across all your projects?"
- If yes: move all files, update `SECRETARY_ROOT`, continue setup.
- If no: ask if they want to keep using the current directory instead. If yes,
  set `SECRETARY_ROOT` to the current directory and continue.

**If local files found and shared location also has files (merge scenario):**
- For each file, compare by modification date:
  - **Exists in both locations:** keep the more recently modified version.
  - **Exists only in one location:** copy it to the other.
- Offer: "Both `[cwd]` and `~/secretary/` have secretary files. I can merge them
  — for each file, I'll keep the most recent version. Want me to show you the
  plan first?"
- Always show the merge plan before executing. List each file, which version wins,
  and why (modification date).
- After merge, the shared location (`~/secretary/`) becomes the single source of
  truth. Offer to clean up the local copy.

### Phase 1: Initialize Memory Folder

```bash
mkdir -p "$SECRETARY_ROOT/memory/people"
mkdir -p "$SECRETARY_ROOT/outputs/meeting-prep"
mkdir -p "$SECRETARY_ROOT/outputs/assessments"
mkdir -p "$SECRETARY_ROOT/outputs/drafts"
mkdir -p "$SECRETARY_ROOT/outputs/proposals"
mkdir -p "$SECRETARY_ROOT/outputs/reviews"
mkdir -p "$SECRETARY_ROOT/sync"
```

Copy scaffold templates from the plugin's `scaffold/` directory into `$SECRETARY_ROOT/`.
Use `${CLAUDE_PLUGIN_ROOT}/scaffold/` to locate them.

Initialize git:
```bash
cd "$SECRETARY_ROOT" && git init && git add -A && git commit -m "Initialize EA memory"
```

### Phase 2: Check connector and tool availability

Check which MCP tools are available in the current session. **Check browser
tools first** — they unlock several later steps (GitHub token creation, HR
system access).

1. **~~browser (Claude in Chrome)** — use ToolSearch for `chrome` or
   `Claude_in_Chrome` to detect browser tools.
   - **If found:** note that browser automation is available. This enables:
     - Automated GitHub token creation (step 7)
     - HR system access for performance reviews
     - Any web-based workflow the user needs
   - **If not found:** explain what browser tools enable and guide setup:
     "Browser tools let me interact with websites on your behalf — creating
     GitHub tokens, accessing HR systems, and more. To set it up:"
     1. Install the **Claude in Chrome** extension from the Chrome Web Store
     2. Open Chrome and click the extension icon to activate it
     3. Come back here and I'll detect it automatically

     Offer to continue without it — browser tools are optional but strongly
     recommended, especially in Cowork where `gh` CLI isn't available.
     If the user sets it up, re-run the ToolSearch to confirm detection.

2. **~~messaging (Slack)** — use ToolSearch for `slack` to detect Slack tools. If found, note that Slack IDs can be auto-populated.
3. **~~documents (Notion)** — use ToolSearch for `notion` to detect Notion tools. If found, note that database links can be verified.
4. **~~email (Microsoft 365 / Google)** — use ToolSearch for `microsoft` or `outlook` (Microsoft 365) or `google` (Google Workspace) to detect email tools.
5. **~~calendar** — search for calendar tools
6. **~~hr-system** — use ToolSearch for `bamboo`, `workday`, `hibob`, or
   `lattice` to detect HR system tools. If none found but browser tools were
   detected in step 1, note that browser-based HR access is available as a
   fallback. If neither, HR features (performance reviews, assessments) will
   be unavailable.

For each missing connector, explain what it enables and whether it's required
or optional.

Also check for GitHub access — try methods in order until one works:

7. **GitHub** — three auth methods, checked in priority order:

   **Method A: Environment token (check first in all environments)**

   Check if `GITHUB_TOKEN` or `GH_TOKEN` is already set in the environment:
   ```bash
   [ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ] && echo "GitHub token found in environment"
   ```
   - **If set:** verify it works by running:
     ```bash
     curl -s -H "Authorization: Bearer ${GITHUB_TOKEN:-$GH_TOKEN}" \
       https://api.github.com/user | jq -r .login
     ```
     If this returns a username, the environment token is valid. Set Auth
     Method to `env-token` in `sync/sources.md` and auto-populate the
     username. No further GitHub setup needed.
   - **If not set or verification fails:** continue to Method B or C.

   **Method B: `gh` CLI (preferred in Claude Code / local dev)**

   Run `gh auth status` to check if `gh` CLI is installed and authenticated.
   - **If available and authenticated:** set Auth Method to `gh-cli` in
     `sync/sources.md` and auto-populate the username from
     `gh api user --jq .login`.
   - **If `gh` is installed but not authenticated:** guide the user through
     `gh auth login` — explain they'll need to follow the browser flow. After
     they complete it, re-run `gh auth status` to verify.
   - **If `gh` is not installed and NOT in Cowork:** explain that GitHub
     integration is optional but useful — it enables PR tracking, stale PR
     detection in standup prep, and activity syncing. Point them to
     https://cli.github.com for installation, then they can run
     `gh auth login`. Offer to continue setup without it.
   - After any `gh` auth setup (fresh login or installation), **always verify**
     by running `gh api user --jq .login` to confirm access works. If
     verification succeeds, set Auth Method to `gh-cli` in `sync/sources.md`
     and auto-populate the username — same as the "already authenticated"
     branch. If verification fails, suggest checking for stale `GITHUB_TOKEN`
     exports in shell profiles.

   **Method C: Personal Access Token file (required in Cowork / fallback elsewhere)**

   If in Cowork (detected by `/sessions` directory existing), or if neither
   Method A nor B is available and the user wants GitHub integration:

   - Explain: "In this environment we can't use the `gh` CLI, but we can use
     the GitHub API directly with a Personal Access Token (PAT)."
   - Check if a token already exists at `$SECRETARY_ROOT/.github-token`. If
     it does, verify it works (see verification step below). If valid, skip
     token creation.
   - If no token exists, offer two paths:

     **Path 1: Automated (if browser tools available from step 1)**

     Offer: "I can create the GitHub token for you using your browser. You
     just need to be logged into GitHub. Want me to do that?"

     If yes, use Claude in Chrome to:
     1. Navigate to https://github.com/settings/tokens?type=beta
     2. If not logged in, stop and ask the user to log in, then retry
     3. Click **"Generate new token"**
     4. Fill in:
        - Token name: "EA - Cowork"
        - Expiration: 90 days
        - Resource owner: select the organization configured in
          `sync/sources.md` (if not visible, stop and explain they need
          an admin to enable fine-grained tokens for the org)
        - Repository access: "All repositories"
     5. Under Repository permissions, set:
        - Pull requests: Read-only
        - Issues: Read-only
        - Contents: Read-only
        - Metadata: Read-only (auto-selected)
     6. Click **"Generate token"**
     7. Read the token value from the page
     8. Save it to `$SECRETARY_ROOT/.github-token`

     If any step fails unexpectedly (CAPTCHA, 2FA prompt, page layout
     doesn't match, or the token value can't be read), fall back to
     Path 2 and explain what happened so the user can finish manually.

     **Path 2: Manual (if no browser tools, or user prefers)**

     Guide the user through creating one themselves:

     **Token creation steps:**
     1. Go to https://github.com/settings/tokens?type=beta (Fine-grained tokens)
     2. Click **"Generate new token"**
     3. **Token name:** Something like "EA - Cowork"
     4. **Expiration:** 90 days (they'll need to regenerate periodically)
     5. **Resource owner:** Select the organization listed in `sync/sources.md`
        - If the org doesn't appear, they need to request access — ask an
          admin to enable fine-grained tokens for the org
     6. **Repository access:** "All repositories" (or "Public repositories" if
        they only need public repo access)
     7. **Permissions** — under "Repository permissions":
        - Pull requests: **Read-only**
        - Issues: **Read-only**
        - Contents: **Read-only** (needed for PR diffs)
        - Metadata: **Read-only** (auto-selected)
     8. Click **"Generate token"** and copy the value

     Once the user provides the token, save it.

   - **Ensure `.github-token` is gitignored before saving** — existing
     secretary folders from before this feature may not have the entry.
     If the secretary folder is a git repo, check and fix first:
     ```bash
     if [ -d "$SECRETARY_ROOT/.git" ]; then
       grep -qxF '.github-token' "$SECRETARY_ROOT/.gitignore" 2>/dev/null || \
         echo '.github-token' >> "$SECRETARY_ROOT/.gitignore"
     fi
     ```
     In Cowork there's no git repo, so this step is skipped — the token
     lives in the mounted cloud folder alongside the rest of the secretary
     files.
   - Save the token (both paths):
     ```bash
     printf '%s' "{token}" > "$SECRETARY_ROOT/.github-token"
     chmod 600 "$SECRETARY_ROOT/.github-token"
     ```
   - **Verify the token** by running:
     ```bash
     curl -s -H "Authorization: Bearer $(cat "$SECRETARY_ROOT/.github-token")" \
       https://api.github.com/user | jq -r .login
     ```
     If this returns a username, the token works. Set Auth Method to
     `api-token` in `sync/sources.md` and auto-populate the username.
   - If verification fails, do NOT set the Auth Method. Common issues:
     - Token wasn't copied correctly (trailing whitespace, newlines)
     - Token doesn't have the right permissions
     - Token wasn't approved for the organization

   **Token renewal reminder:** When verifying an existing token, also check
   if it's close to expiry by examining the `github-authentication-token-expiration`
   response header. If expiring within 14 days, warn the user.

### Phase 3: Auto-populate from connectors

Fill in what we can before asking the user anything:

- If Slack available:
  - Read the current user's profile (no user_id needed — defaults to self) to
    get their name, title, timezone, and Slack ID
  - Pre-fill CLAUDE.md placeholders ([Your Name], [Your Title])
  - Look up Slack IDs for any contacts the user mentioned and populate the cache table
  - Populate contact IDs for key DM contacts
- If Notion available:
  - Verify the pre-configured database links are accessible, flag any that return errors

### Phase 4: Gather remaining information interactively

Scan all `.md` files in `$SECRETARY_ROOT/` for square bracket placeholders that
were not already filled by Phase 3. Ignore placeholders in code blocks, markdown
links, checkboxes, HTML comments, and template examples.

Walk through remaining placeholders in batches:
1. **CLAUDE.md** — company, direct reports, key channels (name/title already filled if Slack was available)
2. **sync/sources.md** — team channels, key contacts, source URLs
3. **memory/my-work.md** — current top priorities
4. **memory/company.md** — department, team tools

Present auto-populated values for confirmation — don't silently apply them.

### Phase 5: Apply and offer first sync

Fill in all placeholders. Present summary. Ask: "Want me to run
/ea:sync now to populate your memory files from existing data?"

## Rules

- Check if `$SECRETARY_ROOT/` already exists FIRST — don't overwrite user's data
- Don't overwhelm — batch questions, be conversational
- Use available connectors to auto-populate instead of asking
- Skip template examples (meeting prep templates stay as patterns)
- Initialize git in `$SECRETARY_ROOT/` — version history is valuable
