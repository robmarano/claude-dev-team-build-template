---
name: ticketing-setup
description: >
  Run the first-time ticketing setup interview when a project derived from the
  claude-dev-team-build-template is opened and no ticketing system has been configured yet.
  The SessionStart hook (.claude/hooks/check-first-run.sh) injects a reminder asking to run
  this skill when .claude/.ticketing-configured is missing. This skill interviews the user to
  choose between GitHub Projects and JIRA Cloud, walks through secure CLI setup, verifies the
  connection, writes .claude/.ticketing-config.json, and creates the marker file. Also invoke
  this skill anytime the user asks to "set up ticketing", "configure tickets", "reset ticketing
  config", or manually via "/ticketing-setup".
---

# ticketing-setup — First-Run Ticketing Interview

This skill runs a one-time interactive setup to choose and configure a ticketing system for the project. It's triggered automatically on the first session after the project is cloned from the template (via a SessionStart hook), or manually if the user wants to reconfigure.

## When This Skill Runs

### Automatic Trigger
The `.claude/hooks/check-first-run.sh` script runs at session start. If it detects that `.claude/.ticketing-configured` doesn't exist, it injects a system reminder telling you (Claude) to invoke this skill before proceeding with other work.

### Manual Trigger
The user can also invoke this skill directly:
- `/ticketing-setup`
- *"set up ticketing for this project"*
- *"reconfigure ticketing"*
- *"I want to switch from GitHub to JIRA"* (or vice versa)

## The Interview Flow

Walk the user through these steps. Be conversational but efficient. Respect their choices — don't try to talk them into one system over the other.

### Step 1: Introduce the Choice

Tell the user:
> This project ships with two ticketing skills pre-installed: one for GitHub Projects (kanban via `gh project`) and one for JIRA Cloud (via `jira-cli`, `acli`, or REST API). Which would you like to use for this project?
>
> - **GitHub Projects** — best if your code already lives on GitHub and you want tickets in the same place. Uses the `gh` CLI you already have installed.
> - **JIRA Cloud** — best if your team uses JIRA for agile management, or if you need advanced features like sprints, epics, custom workflows, and rich reporting.
>
> You can switch later by running `/ticketing-setup` again.

Wait for their choice. If they're unsure, ask: *"Does your team already use one of these? If yes, match the team. If this is greenfield, GitHub Projects is simpler to start with."*

### Step 2 (if GitHub Projects): Set Up `gh project`

Follow this checklist:

#### 2.1 Verify `gh` CLI is installed
```bash
gh --version
```
If missing, tell the user to install it (`brew install gh` on macOS) and run the skill again.

#### 2.2 Check authentication
```bash
gh auth status
```
If not logged in: `gh auth login`. Walk through the interactive prompts.

#### 2.3 Add `project` scope
```bash
gh auth refresh -h github.com -s project
```
This is critical — default `gh` auth doesn't include project permissions.

#### 2.4 Determine the project owner
Ask: *"Do you want to use a project owned by your personal account, or an organization? If organization, what's the org name?"*

Store as:
- Personal: `owner = "@me"`
- Org: `owner = "<org-name>"`

#### 2.5 Find or create a project
```bash
gh project list --owner <OWNER>
```
Show the list. Ask: *"Do you want to use one of these existing projects, or create a new one?"*

If create new:
```bash
gh project create --owner <OWNER> --title "<project-title>"
```
Capture the project number from output.

#### 2.6 Verify you can query the project
```bash
gh project view <NUMBER> --owner <OWNER>
```

#### 2.7 Write the config file
See "Writing the Config File" section below.

### Step 3 (if JIRA Cloud): Set Up JIRA CLI

Follow this checklist:

#### 3.1 Choose a CLI tool
Tell the user:
> You have three choices for interacting with JIRA from the command line:
>
> 1. **`jira-cli`** (ankitpokhrel) — the de-facto community standard. Mature, ergonomic, feature-rich. **Recommended for most users.**
> 2. **`acli`** — Atlassian's official CLI. Newer, supports Confluence/Bitbucket too. Good if you need multi-product.
> 3. **`curl`** + REST API — no install needed, works anywhere. Good for scripts but verbose for daily use.
>
> Which would you like?

Let them pick. If unsure, recommend `jira-cli`. Users can install multiple — they coexist.

#### 3.2 Install the chosen tool

**For `jira-cli`:**
```bash
# macOS
brew install ankitpokhrel/jira-cli/jira-cli

# Linux (snap)
sudo snap install jira-cli

# Linux (binary)
# See https://github.com/ankitpokhrel/jira-cli/releases
```

Verify: `jira version`

**For `acli`:**
```bash
# macOS
brew install --cask atlassian-acli

# Linux
curl -o acli.deb https://acli.atlassian.com/linux/latest/acli_amd64.deb
sudo dpkg -i acli.deb
```

Verify: `acli --version`

**For `curl`:** already installed on all Unix systems.

#### 3.3 Generate an API token
Walk the user through:
> 1. Open https://id.atlassian.com/manage-profile/security/api-tokens in your browser
> 2. Click **Create API token**
> 3. Label it (e.g., "jira-cli for my-project on laptop")
> 4. Copy the token immediately — you cannot view it again
> 5. Come back here when you have it

Wait for them to confirm.

#### 3.4 Get their JIRA details
Ask:
- *"What's your Atlassian site URL? (e.g., `yourorg.atlassian.net`)"*
- *"What's the email you log into JIRA with?"*
- *"Which JIRA project key do you want as the default? (e.g., `PROJ`)"*

#### 3.5 Store the token securely
**Critical security step.** Help them choose and execute one of these three options:

**Option A — OS Keychain (most secure):**
```bash
# macOS
security add-generic-password -a "$(whoami)" -s "jira-cloud" -w
# Press Enter, then paste the token, press Ctrl+D

# Linux (libsecret)
secret-tool store --label="jira-cloud" service jira-cloud
# Paste the token at the prompt
```

Then add to their shell rc (`~/.zshrc`, `~/.bashrc`):
```bash
# macOS
export JIRA_API_TOKEN=$(security find-generic-password -a "$(whoami)" -s "jira-cloud" -w 2>/dev/null)

# Linux
export JIRA_API_TOKEN=$(secret-tool lookup service jira-cloud 2>/dev/null)
```

**Option B — Per-project `.envrc` with direnv (recommended for project-scoped tokens):**

First verify direnv: `which direnv`. If missing, offer to install it: `brew install direnv` + shell hook setup.

Then create:
```bash
# At project root
cat > .envrc <<'EOF'
export JIRA_API_TOKEN="<paste-token-here>"
export JIRA_EMAIL="<their-email>"
export JIRA_SITE="<their-site>"
EOF

# Ensure .envrc is gitignored
grep -qxF '.envrc' .gitignore || echo '.envrc' >> .gitignore

# Create .envrc.example for other contributors
cat > .envrc.example <<'EOF'
export JIRA_API_TOKEN=""
export JIRA_EMAIL=""
export JIRA_SITE=""
EOF

# Activate
direnv allow
```

**Option C — jira-cli built-in config (least secure, most convenient):**
```bash
jira init
```
Walk them through the prompts. The token ends up in `~/.config/.jira/.config.yml` at `0600` perms. This is fine for personal machines but explicit: never use this for shared machines, containers, or CI.

#### 3.6 Verify the connection
Based on the tool they chose:
```bash
# jira-cli
jira me

# acli
acli jira auth status && acli jira project list

# curl
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://$JIRA_SITE/rest/api/3/myself" | jq .displayName
```

If it works: great. If not: debug common issues (401 = bad token, 403 = permissions, network = proxy).

#### 3.7 Write the config file
See "Writing the Config File" section below.

### Step 4: Write the Config File

Once the chosen tool is set up and verified, write `.claude/.ticketing-config.json`:

**For GitHub Projects:**
```json
{
  "system": "github",
  "configured_at": "2026-04-10T11:00:00Z",
  "github": {
    "owner": "<owner>",
    "project_number": <number>,
    "project_title": "<title>"
  }
}
```

**For JIRA Cloud:**
```json
{
  "system": "jira",
  "configured_at": "2026-04-10T11:00:00Z",
  "jira": {
    "site": "<site>",
    "email": "<email>",
    "default_project": "<project-key>",
    "tool": "jira-cli | acli | curl",
    "token_storage": "keychain | envrc | config-file"
  }
}
```

Use `date -u +%FT%TZ` for the `configured_at` timestamp. **Never include the API token in this file** — only references to where it's stored.

### Step 5: Create the Marker File

```bash
touch .claude/.ticketing-configured
```

This prevents the SessionStart hook from re-running the interview next time.

### Step 6: Confirm and Summarize

Tell the user:
> Ticketing is configured. From now on:
> - Your chosen system is **<GitHub Projects | JIRA Cloud>**
> - When you need to create a ticket, move a card, or run agile reports, the **<github-kanban | jira-agile>** skill will activate automatically
> - Your config is in `.claude/.ticketing-config.json`
> - You can reconfigure anytime by running `/ticketing-setup`

## Reconfiguration (User-Initiated)

If the user wants to switch ticketing systems or re-run setup:
1. Confirm they want to overwrite the current config
2. Delete `.claude/.ticketing-configured` and `.claude/.ticketing-config.json`
3. Run the interview again from Step 1

## Security Checklist

Before completing the setup, verify:

- [ ] No API tokens are committed to git (`git status` should show no `.envrc` or credential files tracked)
- [ ] `.envrc` is in `.gitignore` (if used)
- [ ] `.claude/.ticketing-config.json` does NOT contain the token itself — only storage location references
- [ ] The user knows how to rotate the token (quarterly recommended)
- [ ] File permissions are appropriate (`.envrc` should be `0600`, `~/.config/.jira/.config.yml` should be `0600`)

## Troubleshooting

### SessionStart hook doesn't trigger the skill
- Verify `.claude/settings.json` has the hook configured
- Verify `.claude/hooks/check-first-run.sh` is executable (`chmod +x`)
- Check the hook script output manually: `bash .claude/hooks/check-first-run.sh`

### User already configured ticketing elsewhere
- Ask if they want to reuse existing credentials or set up fresh
- If reusing: verify the existing setup works (`gh auth status` or `jira me`), then just write the config file and marker

### User declines to choose
- Offer to skip setup: `touch .claude/.ticketing-skipped` instead of `.ticketing-configured`
- The hook should check for either marker
- Tell them they can run `/ticketing-setup` anytime they change their mind
