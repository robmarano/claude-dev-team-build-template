# jira-cli Reference (ankitpokhrel/jira-cli)

Complete command reference for the community-standard [`ankitpokhrel/jira-cli`](https://github.com/ankitpokhrel/jira-cli) tool. This is the recommended CLI for interactive JIRA work.

## Installation

### macOS
```bash
brew install ankitpokhrel/jira-cli/jira-cli
```

### Linux
```bash
# Snap
sudo snap install jira-cli

# Or download the binary from https://github.com/ankitpokhrel/jira-cli/releases
wget https://github.com/ankitpokhrel/jira-cli/releases/latest/download/jira_Linux_x86_64.tar.gz
tar -xzf jira_Linux_x86_64.tar.gz
sudo mv jira /usr/local/bin/
```

### Windows
```bash
scoop install jira-cli
# or
choco install jira-cli
```

### Verify
```bash
jira version
```

## Initial Setup

```bash
jira init
```

Interactive prompts:
- **Installation type:** Cloud
- **Link to JIRA server:** `https://yourorg.atlassian.net`
- **Login email:** your Atlassian account email
- **API token:** paste the token you generated at https://id.atlassian.com/manage-profile/security/api-tokens
- **Default project:** your most-used project key (can change later)
- **Default board:** pick one from the list

The config is written to `~/.config/.jira/.config.yml`. File perms should be `0600`.

### Using Environment Variables Instead of Config File

For security or CI:
```bash
export JIRA_API_TOKEN="your_token"
jira --login your@email.com --server https://yourorg.atlassian.net me
```

Or set all three via env:
```bash
export JIRA_AUTH_TYPE="basic"
export JIRA_API_TOKEN="your_token"
# jira-cli reads login/server from config OR flags
```

## Projects and Boards

```bash
# List all projects
jira project list

# List boards in current project
jira board list

# Use a specific project for a single command
jira --project OTHER issue list
```

## Issues

### Create
```bash
# Interactive
jira issue create

# Non-interactive
jira issue create \
  --project PROJ \
  --type Story \
  --summary "Add password reset endpoint" \
  --body "AC: POST /api/auth/reset sends email..." \
  --priority High \
  --label backend --label auth \
  --assignee "john@example.com"
```

### View
```bash
# View in terminal
jira issue view PROJ-123

# Open in browser
jira open PROJ-123
```

### List / Search
```bash
# All issues in current project
jira issue list

# Filter by assignee
jira issue list --assignee "$(jira me --plain)"

# Filter by status
jira issue list --status "In Progress"

# Complex JQL
jira issue list -q 'project = PROJ AND status = "In Progress" AND labels = urgent ORDER BY priority DESC'

# Plain output (for scripting)
jira issue list --plain --no-headers --columns key,status,summary
```

### Update / Edit
```bash
# Edit in terminal editor
jira issue edit PROJ-123

# Set specific fields
jira issue edit PROJ-123 \
  --summary "New summary" \
  --priority Critical \
  --label added-label \
  --assignee me
```

### Transition Status (Move Across Board)
```bash
# See available transitions for an issue
jira issue move PROJ-123

# Move to a specific status
jira issue move PROJ-123 "In Progress"
jira issue move PROJ-123 "In Review"
jira issue move PROJ-123 "Done"
```

### Assign
```bash
jira issue assign PROJ-123 "jane@example.com"
jira issue assign PROJ-123 x  # unassign
jira issue assign PROJ-123 $(jira me --plain)  # assign to self
```

### Comment
```bash
jira issue comment add PROJ-123 "This blocks PROJ-456"
```

### Link Issues
```bash
# Link two issues (block, duplicate, relate)
jira issue link PROJ-123 PROJ-456 "Blocks"
jira issue link PROJ-123 PROJ-456 "Is blocked by"
jira issue link PROJ-123 PROJ-456 "Relates"
```

### Worklog
```bash
jira issue worklog add PROJ-123 "2h" "Investigated root cause"
jira issue worklog add PROJ-123 "30m" "Code review"
```

## Sprints

### List Sprints
```bash
jira sprint list
```

### View a Sprint
```bash
jira sprint list --state active
jira sprint list --state closed
jira sprint list --state future
```

### Add Issues to a Sprint
```bash
# Sprint ID is from `jira sprint list`
jira sprint add 42 PROJ-123 PROJ-124 PROJ-125
```

### Move Issue Between Sprints
```bash
jira sprint remove 42 PROJ-123
jira sprint add 43 PROJ-123
```

## Epics

```bash
# Create an epic
jira epic create --project PROJ --summary "User profile redesign" --name "USER_PROFILE"

# List epics
jira epic list

# List issues in an epic
jira epic list PROJ-100

# Add existing issues to an epic
jira epic add PROJ-100 PROJ-123 PROJ-124
```

## Bulk Operations

### Bulk Transition (via JQL + xargs)
```bash
jira issue list -q "project = PROJ AND status = 'Ready' AND fixVersion = 2.0" \
  --plain --no-headers --columns key \
  | awk '{print $1}' \
  | xargs -I {} jira issue move {} "In Progress"
```

### Bulk Reassign
```bash
jira issue list -q "assignee = old@example.com AND status != Done" \
  --plain --no-headers --columns key \
  | awk '{print $1}' \
  | xargs -I {} jira issue assign {} new@example.com
```

## Sprint Planning Workflow

```bash
# 1. See the backlog
jira issue list -q 'project = PROJ AND sprint is EMPTY AND status = "Backlog" ORDER BY priority DESC, created ASC'

# 2. Get the upcoming sprint ID
UPCOMING_SPRINT=$(jira sprint list --state future --plain --no-headers | head -1 | awk '{print $1}')

# 3. Add top-priority items to the sprint (manually pick based on capacity)
jira sprint add $UPCOMING_SPRINT PROJ-101 PROJ-102 PROJ-103 PROJ-104 PROJ-105

# 4. Verify total points
jira issue list -q "sprint = $UPCOMING_SPRINT" --plain --columns key,summary,storypoints
```

## Reports

### Velocity (Completed Points Per Sprint)
```bash
for sprint in $(jira sprint list --state closed --plain --no-headers | awk '{print $1}' | head -5); do
  points=$(jira issue list -q "sprint = $sprint AND status = Done" --plain --no-headers --columns storypoints | awk '{sum+=$1} END {print sum}')
  echo "Sprint $sprint: $points points"
done
```

### Cycle Time (Average Days from In Progress to Done)
```bash
# Requires resolution date and "started" date (custom field or worklog)
jira issue list -q "project = PROJ AND status = Done AND resolved >= -30d" \
  --plain --columns key,created,resolutiondate
```

### WIP Count by Assignee
```bash
jira issue list -q "project = PROJ AND status = 'In Progress'" \
  --plain --no-headers --columns assignee \
  | sort | uniq -c | sort -rn
```

## Useful Config Tweaks

Edit `~/.config/.jira/.config.yml`:

```yaml
installation: cloud
server: https://yourorg.atlassian.net
login: you@example.com
project:
  key: PROJ
  type: classic
board:
  id: 3
  name: PROJ Board
  type: scrum
epic:
  name: Epic Name
  link: Epic Link
issue:
  fields:
    custom:
      - name: Story Points
        key: customfield_10016
        type: number
```

Custom field keys vary per JIRA instance. Find yours with:
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://$JIRA_SITE/rest/api/3/field" | jq '.[] | select(.name == "Story Points")'
```

## Troubleshooting

### `Error: 401 Unauthorized`
Token expired or wrong email. Regenerate token at https://id.atlassian.com/manage-profile/security/api-tokens and run `jira init` again.

### `Error: no such field 'Story Points'`
Custom fields need explicit mapping in config. Add the field under `issue.fields.custom`.

### `Error: board not found`
Board ID changed or you switched projects. Run `jira board list` and update config.

### Commands hang with no output
Check network and proxy settings. `jira-cli` respects `HTTPS_PROXY` env var.
