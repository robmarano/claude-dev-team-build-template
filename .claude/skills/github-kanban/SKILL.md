---
name: github-kanban
description: >
  Manage agile/kanban ticketing using GitHub Projects via the gh CLI. Use this skill whenever the
  user wants to create tickets, move cards between kanban columns, plan sprints, track story points,
  manage backlogs, link epics, or run any agile workflow against GitHub Projects. Also trigger when
  the user says "/github-kanban", mentions GitHub Projects, asks about "the board", talks about
  tickets/issues/cards in a GitHub context, or wants to report on sprint velocity or burndown.
  Prefer this skill when the project uses GitHub Projects (check .claude/.ticketing-config.json).
---

# github-kanban — GitHub Projects Agile Workflow via CLI

This skill teaches you how to run a full kanban/agile workflow against GitHub Projects using the `gh` CLI. Everything — creating projects, defining fields, adding items, moving cards, planning sprints, running reports — is done from the command line.

GitHub Projects v2 (the modern version) is a flexible table/kanban system backed by issues and pull requests. It supports custom fields, multiple views (board, table, roadmap), and cross-repo item linking. All of this is accessible via `gh project` subcommands.

## When to Use This Skill

- Creating or managing a project board
- Adding issues/PRs to the board
- Moving cards between columns (Todo → In Progress → Done)
- Defining custom fields (priority, story points, sprint, component)
- Planning sprints by assigning items to a sprint field
- Querying items by status, assignee, or custom field value
- Reporting on velocity, burndown, or sprint completion

If the project uses JIRA instead of GitHub Projects (check `.claude/.ticketing-config.json`), use the `jira-agile` skill instead.

## Prerequisites

### 1. `gh` CLI Authenticated with Project Scope

The default `gh auth login` does NOT grant project permissions. You must explicitly add the `project` scope:

```bash
gh auth refresh -h github.com -s project
```

Verify:
```bash
gh auth status
# Look for: Token scopes: ..., 'project', ...
```

### 2. Project Owner Identified

Every project belongs to either a **user** (`@me`) or an **organization** (`@myorg`). You'll pass this as `--owner` to most commands.

```bash
# Your personal account
gh project list --owner "@me"

# An organization
gh project list --owner myorg
```

## Core Workflows

The most common operations are in `references/workflows.md`. Read that file when you need specific command sequences. Below is the high-level map.

### Creating and Configuring a Project

```bash
# Create a new project
gh project create --owner "@me" --title "My Project"

# Returns a project number. Use it in subsequent commands.
# To find existing projects:
gh project list --owner "@me"
```

See `references/workflows.md` → "Creating a Project Board" for full details including field creation (Status, Priority, Sprint, Story Points).

### Adding Items to the Board

```bash
# Add an existing issue
gh project item-add <PROJECT_NUMBER> --owner "@me" --url https://github.com/owner/repo/issues/42

# Create a draft item (no backing issue yet)
gh project item-create <PROJECT_NUMBER> --owner "@me" --title "Implement login" --body "AC: ..."
```

### Moving Cards Across Columns

Moving a card is done by updating its Status field. First get the project's field ID, then update the item:

```bash
# Find the Status field ID and its options
gh project field-list <PROJECT_NUMBER> --owner "@me" --format json

# Update an item's Status to "In Progress"
gh project item-edit \
  --project-id <PROJECT_ID> \
  --id <ITEM_ID> \
  --field-id <STATUS_FIELD_ID> \
  --single-select-option-id <IN_PROGRESS_OPTION_ID>
```

See `references/workflows.md` → "Moving Items Across Columns" for a script that does this by field/option names instead of raw IDs.

### Querying the Board

```bash
# List all items in the project
gh project item-list <PROJECT_NUMBER> --owner "@me" --format json

# Filter items by a field value (requires jq)
gh project item-list <PROJECT_NUMBER> --owner "@me" --format json \
  | jq '.items[] | select(.status == "In Progress")'
```

## Agile Patterns

### Sprint Planning

GitHub Projects has a built-in "Iteration" field type designed for sprints. Create one once, then assign items to each iteration.

```bash
# Create an iteration field (from the web UI is easier, but CLI works)
gh project field-create <PROJECT_NUMBER> --owner "@me" \
  --name "Sprint" --data-type "ITERATION"
```

See `references/workflows.md` → "Sprint Management" for the full pattern including sprint planning sessions, mid-sprint adjustments, and sprint retrospectives.

### Story Points

```bash
gh project field-create <PROJECT_NUMBER> --owner "@me" \
  --name "Story Points" --data-type "NUMBER"
```

Then update each item with a point value. Use `gh project item-edit --number <N>`.

### Epics → Stories Linking

GitHub Projects doesn't have a native "epic" concept. The two common patterns:

1. **Issue-as-epic** — create an issue labeled `epic`, and link child issues via task lists in the epic's body (GitHub auto-tracks completion).
2. **Parent-Child field** — define a custom text field "Parent Epic" and reference the epic issue number.

See `references/workflows.md` → "Epic Management" for both patterns.

### Velocity and Burndown Reports

`gh project item-list --format json` returns everything you need. Pipe through `jq` to aggregate. Full reporting scripts are in `references/reports.md`.

## Security Notes

- The `project` scope grants read/write access to all projects owned by you or orgs you're a member of. Only add it if you need it.
- `gh` stores credentials in the OS keychain (macOS Keychain, Linux secret-service, Windows Credential Manager). Don't manually set `GH_TOKEN` unless you're in CI.
- Never commit `.github/auth-token` or similar files. `gh` doesn't create these by default, but be wary of scripts that do.

## Team-Build Integration (Future)

This skill is designed to work standalone today. A future integration with the `team-build` skill will enable patterns like:

- **After `/team-build` finishes:** Auto-create tickets in the project for any UAT "GO WITH NOTES" follow-ups
- **Before `/team-build` starts:** Pull a task description from an existing GitHub Projects item and use it as the team's spec
- **During `/team-build`:** Move the corresponding card from "Todo" → "In Progress" → "In Review" → "Done" as phases complete

When you're ready to enable this, the orchestrator should read `.claude/.ticketing-config.json` to determine which ticketing system is configured and dispatch the appropriate commands. Ask the user: *"Do you want to cross-integrate team-build with your ticketing system?"* and they can decide when it's time.

## Reference Files

Read these when you need command-level detail:

- `references/workflows.md` — Complete command sequences for every common task (creating projects, fields, items; moving cards; querying)
- `references/reports.md` — Reporting scripts: velocity, burndown, cycle time, WIP tracking
- `references/gh-project-cheatsheet.md` — Quick reference for all `gh project` subcommands and their flags
