# GitHub Projects — Complete Workflow Reference

Detailed command sequences for every common GitHub Projects operation via the `gh` CLI. All commands assume you've already authenticated with the `project` scope (`gh auth refresh -s project`).

## Table of Contents
1. [Creating a Project Board](#1-creating-a-project-board)
2. [Defining Fields](#2-defining-fields)
3. [Adding Items to the Board](#3-adding-items-to-the-board)
4. [Moving Items Across Columns](#4-moving-items-across-columns)
5. [Querying and Filtering](#5-querying-and-filtering)
6. [Sprint Management](#6-sprint-management)
7. [Epic Management](#7-epic-management)
8. [Bulk Operations](#8-bulk-operations)
9. [Automation Patterns](#9-automation-patterns)

---

## 1. Creating a Project Board

### Personal Project
```bash
gh project create --owner "@me" --title "Q2 Feature Work"
```

### Organization Project
```bash
gh project create --owner myorg --title "Platform Roadmap"
```

### Verify Creation and Get Project Number
```bash
gh project list --owner "@me" --format json | jq '.projects[] | {number, title, id}'
```

You need both the **number** (short form for CLI commands) and the **ID** (long form for GraphQL operations). The id starts with `PVT_`.

### Get Everything in One Variable Block
```bash
PROJECT_NUMBER=$(gh project list --owner "@me" --format json | jq -r '.projects[] | select(.title == "Q2 Feature Work") | .number')
PROJECT_ID=$(gh project list --owner "@me" --format json | jq -r '.projects[] | select(.title == "Q2 Feature Work") | .id')
echo "Number: $PROJECT_NUMBER, ID: $PROJECT_ID"
```

---

## 2. Defining Fields

Projects come with a default `Status` field (Todo, In Progress, Done). You can add custom fields for agile workflows.

### Field Types Available
- `TEXT` — free-form text
- `NUMBER` — for story points, estimates
- `DATE` — for due dates
- `SINGLE_SELECT` — for priority, type, component
- `ITERATION` — for sprints/iterations (built-in sprint support)

### Create a Priority Single-Select Field
```bash
gh project field-create $PROJECT_NUMBER --owner "@me" \
  --name "Priority" \
  --data-type "SINGLE_SELECT" \
  --single-select-options "P0,P1,P2,P3"
```

### Create a Story Points Field
```bash
gh project field-create $PROJECT_NUMBER --owner "@me" \
  --name "Story Points" \
  --data-type "NUMBER"
```

### Create a Sprint (Iteration) Field
```bash
gh project field-create $PROJECT_NUMBER --owner "@me" \
  --name "Sprint" \
  --data-type "ITERATION"
```

**Note:** The CLI creates the field with default iteration settings (2-week sprints starting today). To customize iteration duration and start dates, you currently need the web UI or GraphQL API. See section 9 for GraphQL examples.

### List All Fields and Their IDs
```bash
gh project field-list $PROJECT_NUMBER --owner "@me" --format json
```

Capture field IDs you'll use repeatedly:
```bash
STATUS_FIELD_ID=$(gh project field-list $PROJECT_NUMBER --owner "@me" --format json | jq -r '.fields[] | select(.name == "Status") | .id')
PRIORITY_FIELD_ID=$(gh project field-list $PROJECT_NUMBER --owner "@me" --format json | jq -r '.fields[] | select(.name == "Priority") | .id')
POINTS_FIELD_ID=$(gh project field-list $PROJECT_NUMBER --owner "@me" --format json | jq -r '.fields[] | select(.name == "Story Points") | .id')
```

---

## 3. Adding Items to the Board

### Add an Existing Issue
```bash
gh project item-add $PROJECT_NUMBER --owner "@me" \
  --url https://github.com/myorg/myrepo/issues/42
```

### Add an Existing Pull Request
```bash
gh project item-add $PROJECT_NUMBER --owner "@me" \
  --url https://github.com/myorg/myrepo/pull/123
```

### Create a Draft Item (No Backing Issue)
Useful for quick capture during sprint planning:
```bash
gh project item-create $PROJECT_NUMBER --owner "@me" \
  --title "Investigate login latency" \
  --body "Users report 2s+ login times in the EU region. Investigate cause."
```

### Convert a Draft Item to a Real Issue
Use the web UI — there's no CLI command for this yet. Alternatively, create the issue first with `gh issue create`, then add it with `gh project item-add`.

### Bulk Add Multiple Issues
```bash
for issue in 10 11 12 13 14; do
  gh project item-add $PROJECT_NUMBER --owner "@me" \
    --url "https://github.com/myorg/myrepo/issues/$issue"
done
```

---

## 4. Moving Items Across Columns

Moving a card in kanban = updating its Status field. This requires the item's ID and the target option's ID.

### Step 1: Get the Item's ID
```bash
ITEM_ID=$(gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq -r '.items[] | select(.content.number == 42) | .id')
```

### Step 2: Get the Target Status Option ID
```bash
IN_PROGRESS_OPTION_ID=$(gh project field-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq -r '.fields[] | select(.name == "Status") | .options[] | select(.name == "In Progress") | .id')
```

### Step 3: Update the Item
```bash
gh project item-edit \
  --project-id $PROJECT_ID \
  --id $ITEM_ID \
  --field-id $STATUS_FIELD_ID \
  --single-select-option-id $IN_PROGRESS_OPTION_ID
```

### All-In-One Helper Function
Save this in your shell rc for convenience:
```bash
# Usage: gh-move-card <project-number> <issue-number> <column-name>
gh-move-card() {
  local proj_num=$1
  local issue_num=$2
  local column=$3
  local owner="@me"

  local proj_id=$(gh project list --owner "$owner" --format json | jq -r ".projects[] | select(.number == $proj_num) | .id")
  local item_id=$(gh project item-list "$proj_num" --owner "$owner" --format json | jq -r ".items[] | select(.content.number == $issue_num) | .id")
  local status_field_id=$(gh project field-list "$proj_num" --owner "$owner" --format json | jq -r '.fields[] | select(.name == "Status") | .id')
  local option_id=$(gh project field-list "$proj_num" --owner "$owner" --format json | jq -r ".fields[] | select(.name == \"Status\") | .options[] | select(.name == \"$column\") | .id")

  gh project item-edit \
    --project-id "$proj_id" \
    --id "$item_id" \
    --field-id "$status_field_id" \
    --single-select-option-id "$option_id"
}

# Usage
gh-move-card 3 42 "In Progress"
gh-move-card 3 42 "Done"
```

### Setting Story Points
```bash
gh project item-edit \
  --project-id $PROJECT_ID \
  --id $ITEM_ID \
  --field-id $POINTS_FIELD_ID \
  --number 5
```

---

## 5. Querying and Filtering

### List All Items (JSON)
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json
```

### Filter: Only Items In Progress
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '.items[] | select(.status == "In Progress") | {title: .content.title, assignees: .content.assignees}'
```

### Filter: High-Priority Items
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '.items[] | select(.["priority"] == "P0" or .["priority"] == "P1")'
```

### Count Items by Status
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '.items | group_by(.status) | map({status: .[0].status, count: length})'
```

### Items Assigned to Me
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq --arg me "$(gh api user --jq .login)" '.items[] | select(.content.assignees[]?.login == $me)'
```

---

## 6. Sprint Management

### Current Sprint Iteration
The Iteration field type has a "current" concept. Use GraphQL to find it:
```bash
gh api graphql -f query='
  query {
    viewer {
      projectV2(number: '"$PROJECT_NUMBER"') {
        field(name: "Sprint") {
          ... on ProjectV2IterationField {
            configuration {
              iterations {
                id
                title
                startDate
                duration
              }
            }
          }
        }
      }
    }
  }'
```

### Assign Item to a Sprint
```bash
SPRINT_FIELD_ID=$(gh project field-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq -r '.fields[] | select(.name == "Sprint") | .id')

# The iteration ID comes from the GraphQL query above
gh project item-edit \
  --project-id $PROJECT_ID \
  --id $ITEM_ID \
  --field-id $SPRINT_FIELD_ID \
  --iteration-id <ITERATION_ID>
```

### Sprint Planning Checklist (what to run)
1. Query all `Todo` items in the backlog sorted by priority
2. Calculate team capacity (e.g., 40 points for the sprint)
3. Select items until capacity reached
4. Assign selected items to the current sprint iteration
5. Move them from `Todo` → `Sprint Backlog` (if you have that column) or leave as `Todo`

### Mid-Sprint: See What's In-Flight
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '.items[] | select(.sprint == "Sprint 23" and .status == "In Progress")'
```

### Sprint Retrospective: Completed vs Planned
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '.items[] | select(.sprint == "Sprint 23") | {title: .content.title, status: .status, points: .["story points"]}'
```

---

## 7. Epic Management

GitHub Projects doesn't have a native Epic type. Two patterns:

### Pattern A — Issue-as-Epic with Task Lists

Create an epic issue:
```bash
gh issue create --repo myorg/myrepo --title "[EPIC] User profile redesign" --body "$(cat <<'EOF'
## Overview
Redesign the user profile page to match the new design system.

## Child Issues
- [ ] #101 — Design tokens extraction
- [ ] #102 — Profile header component
- [ ] #103 — Avatar upload flow
- [ ] #104 — Mobile responsive styles
EOF
)" --label epic
```

GitHub auto-tracks completion — as child issues close, the task list checkboxes update and you can see epic progress in the issue header.

Add the epic to your project board too:
```bash
gh project item-add $PROJECT_NUMBER --owner "@me" \
  --url https://github.com/myorg/myrepo/issues/100
```

### Pattern B — "Parent Epic" Custom Field

```bash
gh project field-create $PROJECT_NUMBER --owner "@me" \
  --name "Parent Epic" \
  --data-type "TEXT"
```

Then for each child item, set the Parent Epic field to the epic's issue number or title. Query epic progress:
```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '.items[] | select(.["parent epic"] == "User profile redesign")'
```

---

## 8. Bulk Operations

### Move All Items from One Sprint to Another
Use when a sprint slips and unfinished work rolls forward:
```bash
# Get items from old sprint that aren't Done
ITEMS=$(gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq -r '.items[] | select(.sprint == "Sprint 22" and .status != "Done") | .id')

# Reassign each to the new sprint
for item_id in $ITEMS; do
  gh project item-edit \
    --project-id $PROJECT_ID \
    --id "$item_id" \
    --field-id $SPRINT_FIELD_ID \
    --iteration-id <NEW_ITERATION_ID>
done
```

### Archive Completed Items
```bash
DONE_ITEMS=$(gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq -r '.items[] | select(.status == "Done") | .id')

for item_id in $DONE_ITEMS; do
  gh project item-archive --project-id $PROJECT_ID --id "$item_id"
done
```

---

## 9. Automation Patterns

### GraphQL for Advanced Operations
Some operations (like setting custom sprint start dates) require GraphQL:
```bash
gh api graphql -f query='
  mutation {
    updateProjectV2Field(input: {
      projectId: "'"$PROJECT_ID"'"
      fieldId: "'"$SPRINT_FIELD_ID"'"
      name: "Sprint"
      configuration: {
        iterations: [
          {startDate: "2026-04-01", duration: 14}
          {startDate: "2026-04-15", duration: 14}
        ]
      }
    }) {
      projectV2Field { id }
    }
  }'
```

### GitHub Actions Integration
You can trigger project updates from CI:
```yaml
# .github/workflows/project-sync.yml
on:
  issues:
    types: [opened]
jobs:
  add-to-project:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/add-to-project@v0.5.0
        with:
          project-url: https://github.com/orgs/myorg/projects/3
          github-token: ${{ secrets.PROJECT_TOKEN }}
```

---

## Troubleshooting

### "HTTP 403: Resource not accessible by integration"
Your token lacks the `project` scope. Fix:
```bash
gh auth refresh -h github.com -s project
```

### "Could not find field with name 'Sprint'"
The field doesn't exist yet. Create it or check the exact name:
```bash
gh project field-list $PROJECT_NUMBER --owner "@me"
```

### Item Edit Doesn't Persist
Double-check that `--project-id` uses the long `PVT_...` ID, not the short number. The short number goes in positional arguments; the long ID goes in `--project-id`.
