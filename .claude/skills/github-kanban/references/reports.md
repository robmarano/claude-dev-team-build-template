# GitHub Projects — Reporting & Analytics

Shell scripts for generating common agile reports from GitHub Projects data. All scripts assume you've set `PROJECT_NUMBER` and use `gh project item-list --format json` as the data source.

## Velocity Report

Points completed per sprint.

```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '
      [.items[] | select(.status == "Done")]
      | group_by(.sprint)
      | map({
          sprint: .[0].sprint,
          total_points: (map(.["story points"] // 0) | add),
          item_count: length
        })
    '
```

Output:
```json
[
  {"sprint": "Sprint 21", "total_points": 34, "item_count": 8},
  {"sprint": "Sprint 22", "total_points": 42, "item_count": 11},
  {"sprint": "Sprint 23", "total_points": 38, "item_count": 9}
]
```

## Burndown (Current Sprint)

Remaining points in the active sprint.

```bash
CURRENT_SPRINT="Sprint 23"

gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq --arg sprint "$CURRENT_SPRINT" '
      .items
      | map(select(.sprint == $sprint))
      | {
          total: (map(.["story points"] // 0) | add),
          done: (map(select(.status == "Done") | .["story points"] // 0) | add),
          in_progress: (map(select(.status == "In Progress") | .["story points"] // 0) | add),
          todo: (map(select(.status == "Todo") | .["story points"] // 0) | add)
        }
    '
```

## Cycle Time

Average time from `In Progress` → `Done`. Requires item activity history (GraphQL):

```bash
gh api graphql -f query='
  query {
    viewer {
      projectV2(number: '"$PROJECT_NUMBER"') {
        items(first: 100) {
          nodes {
            content { ... on Issue { number, createdAt, closedAt } }
          }
        }
      }
    }
  }' | jq '
    [.data.viewer.projectV2.items.nodes[]
      | select(.content.closedAt != null)
      | {
          number: .content.number,
          days: ((.content.closedAt | fromdate) - (.content.createdAt | fromdate)) / 86400
        }
    ]
    | {
        count: length,
        avg_days: ((map(.days) | add) / length)
      }
  '
```

## Work In Progress (WIP)

Count of items in each `In Progress` state per assignee. Helps spot WIP limit violations.

```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '
      [.items[] | select(.status == "In Progress")]
      | group_by(.content.assignees[0].login // "unassigned")
      | map({assignee: .[0].content.assignees[0].login // "unassigned", wip_count: length})
    '
```

## Backlog Health

How much is in the backlog, how old, and how it's distributed.

```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '
      [.items[] | select(.status == "Todo")]
      | {
          total: length,
          by_priority: (group_by(.priority) | map({priority: .[0].priority, count: length})),
          unestimated: ([.[] | select(.["story points"] == null)] | length),
          total_points: (map(.["story points"] // 0) | add)
        }
    '
```

## Sprint Completion Rate

Historical view of what percentage of planned work actually got done each sprint.

```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq '
      [.items[] | select(.sprint != null)]
      | group_by(.sprint)
      | map({
          sprint: .[0].sprint,
          planned: length,
          completed: (map(select(.status == "Done")) | length),
          completion_rate: (((map(select(.status == "Done")) | length) / length * 100) | floor)
        })
    '
```

## Export to CSV for External Tools

If you need to feed data into spreadsheets, BI tools, or presentations:

```bash
gh project item-list $PROJECT_NUMBER --owner "@me" --format json \
  | jq -r '
      ["Title", "Status", "Priority", "Sprint", "Points", "Assignee"],
      (.items[] | [
        .content.title,
        .status,
        .priority,
        .sprint,
        (.["story points"] // 0),
        (.content.assignees[0].login // "unassigned")
      ])
      | @csv
    ' > project-export.csv
```
