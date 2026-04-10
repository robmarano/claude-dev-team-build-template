---
name: jira-agile
description: >
  Manage agile ticketing in JIRA Cloud via CLI tools. Use this skill whenever the user wants to
  create tickets, update statuses, manage sprints, work with epics, query issues, or run any agile
  workflow against JIRA Cloud. Triggers on "/jira-agile", mentions of JIRA tickets, JIRA sprints,
  JIRA epics, JQL queries, or discussions about the backlog/board in a JIRA context. Supports three
  CLI approaches: the de-facto-standard jira-cli (ankitpokhrel), Atlassian's official acli, and
  raw REST API via curl. Prefer this skill when the project uses JIRA Cloud (check
  .claude/.ticketing-config.json).
---

# jira-agile — JIRA Cloud Agile Workflow via CLI

This skill teaches you how to run a full agile workflow against JIRA Cloud using command-line tools. It supports three different CLI approaches so you can choose the right tool for each situation.

## Tool Comparison — Which CLI to Use

| Tool | When to Use | Pros | Cons |
|------|-------------|------|------|
| **`jira-cli`** (ankitpokhrel/jira-cli) | Default for interactive work | Mature, TUI, fast, great ergonomics, full agile features | Third-party, requires separate install |
| **`acli`** (Atlassian official) | When you want official support + multi-product (JIRA, Confluence, Bitbucket) | Official Atlassian tool, unified UX across products | Newer, fewer agile-specific features, verbose |
| **`curl`** + REST API | Scripting, CI/CD, edge cases not covered by CLIs | No install needed, works anywhere, complete API coverage | Verbose, you handle auth and JSON manually |

### Decision Framework
- **Interactive human work** → `jira-cli`
- **Scripts, automation, CI** → `jira-cli` non-interactive mode OR `curl`
- **Need Confluence/Bitbucket too** → `acli`
- **One-off operation, don't want to install a tool** → `curl`

Detailed command references live in the `references/` directory — load the relevant one when you need specific commands:

- `references/jira-cli.md` — Complete reference for `ankitpokhrel/jira-cli`
- `references/acli.md` — Atlassian's official CLI
- `references/curl-rest.md` — Raw REST API patterns

## When to Use This Skill

- Creating, viewing, updating, or transitioning JIRA issues
- Managing sprints (create, start, close, assign issues)
- Working with epics and stories (creation, linking, hierarchy)
- Running JQL queries to find issues
- Generating agile reports (velocity, burndown, cycle time)
- Bulk operations (mass update, reassign, move across projects)
- Commenting, attaching files, adding worklogs

If the project uses GitHub Projects instead, use the `github-kanban` skill.

## Prerequisites

### Authentication — API Tokens (Not Passwords)

JIRA Cloud requires API tokens. Passwords do not work for API access. Get a token:

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click **Create API token**
3. Label it (e.g., "jira-cli local machine")
4. Copy the token immediately — you cannot view it again

### Secure Storage of the Token

**Never commit the token to a repo.** Three recommended storage options in order of preference:

#### Option A — OS Keychain (Most Secure)
macOS Keychain:
```bash
security add-generic-password -a "$(whoami)" -s "jira-cloud" -w "YOUR_API_TOKEN_HERE"
# Retrieve later:
JIRA_API_TOKEN=$(security find-generic-password -a "$(whoami)" -s "jira-cloud" -w)
```

Linux `secret-tool` (from libsecret):
```bash
echo -n "YOUR_API_TOKEN_HERE" | secret-tool store --label="jira-cloud" service jira-cloud
# Retrieve:
JIRA_API_TOKEN=$(secret-tool lookup service jira-cloud)
```

#### Option B — Per-Project `.envrc` with direnv
Install `direnv` (`brew install direnv`), hook it to your shell, then:
```bash
# .envrc at project root (GITIGNORED)
export JIRA_API_TOKEN="your_token_here"
export JIRA_EMAIL="you@example.com"
export JIRA_SITE="yourorg.atlassian.net"
```
```bash
# .envrc.example (CHECKED IN)
export JIRA_API_TOKEN=""
export JIRA_EMAIL=""
export JIRA_SITE=""
```
Add `.envrc` to `.gitignore`. Run `direnv allow` in the project directory.

#### Option C — `jira-cli` Built-In Config (Convenient, Less Secure)
`jira init` writes a config to `~/.config/.jira/.config.yml`. The token is stored as plaintext in that file with `0600` perms. Acceptable for personal machines if your home directory is encrypted. Not recommended for shared machines or CI.

### Verify Authentication Works

```bash
# Using jira-cli
jira me

# Using acli
acli jira project list

# Using curl
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://$JIRA_SITE/rest/api/3/myself" | jq .displayName
```

All three should return your user info. If you get `401 Unauthorized`, check the token and email are correct.

## Core Workflows Overview

All three tools cover the same common operations. Here's the mental model — pick your tool, then read the specific reference file for exact commands.

### Creating Issues
- **jira-cli:** `jira issue create --project PROJ --type Story --summary "..." --description "..."`
- **acli:** `acli jira issue create --project PROJ --issue-type Story --summary "..."`
- **curl:** POST to `/rest/api/3/issue` with JSON body

### Transitioning Status (Move Across Board)
- **jira-cli:** `jira issue move PROJ-123 "In Progress"`
- **acli:** `acli jira issue transition PROJ-123 --transition-name "In Progress"`
- **curl:** GET available transitions, then POST to `/rest/api/3/issue/{key}/transitions`

### JQL Queries
- **jira-cli:** `jira issue list -q "project = PROJ AND status = 'In Progress'"`
- **acli:** `acli jira issue search --jql "project = PROJ AND status = 'In Progress'"`
- **curl:** POST to `/rest/api/3/search` with JQL in the body

### Sprint Management
- **jira-cli:** `jira sprint list`, `jira sprint add --sprint 42 PROJ-123`
- **acli:** `acli jira sprint list`, `acli jira sprint add-issues`
- **curl:** Agile API at `/rest/agile/1.0/sprint/{sprintId}/issue`

See the tool-specific reference files for the full command set and flags.

## Agile Patterns

### Sprint Planning Workflow

1. Query the backlog: items in `Backlog` status, no sprint assigned, sorted by priority
2. Assign selected items to the upcoming sprint
3. Verify total story points match capacity
4. Move items from `Backlog` → `To Do`

See `references/jira-cli.md` → "Sprint Planning" for the complete command sequence.

### Epic → Story Hierarchy

JIRA has first-class Epic support:
1. Create an Epic (Issue type = Epic)
2. Create Stories linked to the Epic via the Epic Link field
3. Use `jira issue list --parent EPIC-KEY` to see all stories in an epic

### Sub-Tasks
Sub-tasks are first-class children of an issue. Create with `jira issue create --parent PROJ-123 --type Sub-task --summary "..."`.

### Bulk Updates
All three tools support bulk. JQL queries + xargs is the universal pattern:
```bash
jira issue list -q "project = PROJ AND fixVersion = 2.0 AND status = 'To Do'" --plain --no-headers \
  | awk '{print $1}' \
  | xargs -I {} jira issue move {} "In Progress"
```

## Agile Reports

JIRA's native board view includes velocity and burndown charts. For CLI-driven reports, see:
- `references/jira-cli.md` → "Reports" for velocity, cycle time, WIP
- `references/curl-rest.md` → "Agile API" for the raw endpoints

## Security Notes

- **API tokens are long-lived.** Rotate them quarterly via the Atlassian security page.
- **Scope matters.** A personal API token has full access to everything your user can see. For CI, consider creating a dedicated service account user with limited project permissions.
- **Audit logs are limited on JIRA Cloud Standard.** If you need detailed access auditing, Enterprise plans have better logs.
- **Never log tokens.** Scripts that echo command lines or errors to files may leak tokens. Use `set +x` before sensitive operations and `set -x` after.

## Team-Build Integration (Future)

This skill is designed to work standalone today. A future integration with the `team-build` skill will enable patterns like:

- **After `/team-build` finishes:** Auto-create JIRA tickets for UAT "GO WITH NOTES" follow-ups
- **Before `/team-build` starts:** Pull a task description from an existing JIRA ticket and use it as the team's spec
- **During `/team-build`:** Transition the corresponding ticket `To Do` → `In Progress` → `In Review` → `Done` as phases complete
- **Cross-project linking:** Link team-build outputs to JIRA Epic for traceability

When you're ready to enable this, the orchestrator should read `.claude/.ticketing-config.json` to determine which ticketing system is configured and dispatch the appropriate commands. Ask the user: *"Do you want to cross-integrate team-build with JIRA?"* and they can decide when it's time.

## Reference Files

- `references/jira-cli.md` — Complete command reference for ankitpokhrel/jira-cli (the recommended tool)
- `references/acli.md` — Atlassian's official CLI commands
- `references/curl-rest.md` — Raw REST API patterns with curl (useful for scripts and CI)
