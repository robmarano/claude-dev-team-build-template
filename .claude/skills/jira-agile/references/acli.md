# acli Reference — Atlassian Official CLI

[`acli`](https://developer.atlassian.com/cloud/acli/) is Atlassian's official command-line interface, supporting JIRA, Confluence, Bitbucket, and Compass from a unified tool. It's newer than `jira-cli` and less feature-complete for pure agile workflows, but offers advantages:

- Official support from Atlassian
- Unified experience across Atlassian products
- Automatic updates tied to API changes
- Cloud-native (not designed for Server/DC)

## When to Prefer `acli` Over `jira-cli`

- You also need to manage Confluence pages or Bitbucket PRs from the same tool
- You want official Atlassian support
- You're in an enterprise environment that prefers vendor-supported tools
- You need rovodev (Atlassian's AI assistant) integration

For pure JIRA work with heavy agile focus, `jira-cli` is more ergonomic.

## Installation

### macOS (Homebrew)
```bash
brew install --cask atlassian-acli
```

### Linux
```bash
curl -o acli.deb https://acli.atlassian.com/linux/latest/acli_amd64.deb
sudo dpkg -i acli.deb
```

### Windows
Download the MSI from https://acli.atlassian.com/windows/

### Verify
```bash
acli --version
```

## Authentication

```bash
acli jira auth login
```

Interactive prompts for:
- Site URL (e.g., `yourorg.atlassian.net`)
- Email
- API token

Credentials are stored in `~/.atlassian/acli/` with OS-appropriate permissions.

### Verify Login
```bash
acli jira auth status
acli jira project list
```

## Common Commands

### Projects
```bash
acli jira project list
acli jira project view --project PROJ
```

### Issues — Create
```bash
acli jira issue create \
  --project PROJ \
  --issue-type Story \
  --summary "Add password reset endpoint" \
  --description "AC: POST /api/auth/reset sends email..."
```

### Issues — View
```bash
acli jira issue view PROJ-123
```

### Issues — Search (JQL)
```bash
acli jira issue search --jql "project = PROJ AND status = 'In Progress'"
```

### Issues — Update
```bash
acli jira issue update PROJ-123 \
  --summary "Updated summary" \
  --priority High
```

### Issues — Transition
```bash
# List available transitions
acli jira issue transitions PROJ-123

# Transition to a status
acli jira issue transition PROJ-123 --transition-name "In Progress"
```

### Issues — Assign
```bash
acli jira issue assign PROJ-123 --assignee jane@example.com
```

### Issues — Comment
```bash
acli jira issue comment add PROJ-123 --body "Blocking on PROJ-456"
```

### Sprints
```bash
# List sprints on a board
acli jira sprint list --board 3

# Add issues to sprint
acli jira sprint add-issues --sprint 42 --issues PROJ-123,PROJ-124,PROJ-125

# Start / close sprint
acli jira sprint start --sprint 42
acli jira sprint close --sprint 42
```

### Epics
```bash
acli jira epic create --project PROJ --summary "User profile redesign"
acli jira epic list --project PROJ
```

## Output Formats

`acli` supports JSON output for scripting:
```bash
acli jira issue search --jql "project = PROJ" --output json
```

Pipe through `jq`:
```bash
acli jira issue search --jql "project = PROJ AND assignee = currentUser()" --output json \
  | jq '.issues[] | {key, summary: .fields.summary, status: .fields.status.name}'
```

## Limitations vs jira-cli

- No interactive TUI for issue browsing
- Fewer convenience shortcuts (e.g., `jira me` doesn't exist; use `acli jira auth status`)
- Less flexible JQL shortcuts
- No built-in worklog management as of current version
- Epic operations are more verbose

## When to Switch From `acli` to `jira-cli`

If you find yourself doing a lot of:
- Interactive issue browsing
- Rapid sprint planning
- Bulk operations
- Worklog management
- Custom field manipulation

...switch to `jira-cli`. The two tools can coexist (they just read credentials from different files).

## Multi-Product Use Cases

This is where `acli` shines. Example: update a JIRA ticket and a linked Confluence page in one workflow:

```bash
# Transition ticket
acli jira issue transition PROJ-123 --transition-name "In Review"

# Update the linked design doc
acli confluence page update --id 123456 \
  --title "Password reset design" \
  --content "Updated flow diagram after review"
```

Or link a Bitbucket PR to a JIRA ticket:
```bash
acli bitbucket pullrequest create \
  --repository myorg/myrepo \
  --source feature/password-reset \
  --destination main \
  --title "PROJ-123: Password reset endpoint"
```

The JIRA ticket auto-detects the PR mention and shows it in the development panel.

## Troubleshooting

### `acli: command not found` after install
Check `echo $PATH`. The installer may put `acli` in `/opt/atlassian/acli/bin/` which isn't in PATH by default.

### Auth works but commands return "forbidden"
API token scope is insufficient or your user doesn't have permission for that project. Verify in the JIRA web UI.

### Commands are slow
`acli` makes more API calls for some operations than `jira-cli`. If latency matters, switch tools.

## Reference Links

- Official docs: https://developer.atlassian.com/cloud/acli/
- Release notes: https://developer.atlassian.com/cloud/acli/release-notes/
- GitHub issues: https://github.com/atlassian-labs/acli
