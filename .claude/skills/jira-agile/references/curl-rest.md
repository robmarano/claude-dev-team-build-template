# JIRA Cloud REST API via curl

Raw REST API patterns for scripting, CI/CD pipelines, and operations not covered by the CLI tools. Use this approach when:

- You can't install a CLI tool (e.g., minimal CI container)
- You need operations the CLIs don't expose
- You're writing a one-off script and don't want to add a dependency
- You need precise control over request/response handling

## Authentication

JIRA Cloud uses HTTP Basic Auth with `email:api_token`:

```bash
# Set once
export JIRA_EMAIL="you@example.com"
export JIRA_API_TOKEN="your_token"
export JIRA_SITE="yourorg.atlassian.net"
export JIRA_AUTH="-u $JIRA_EMAIL:$JIRA_API_TOKEN"
```

Verify:
```bash
curl -s $JIRA_AUTH "https://$JIRA_SITE/rest/api/3/myself" | jq .displayName
```

## API Versions

- `/rest/api/3/` — current REST API (use this for most operations)
- `/rest/api/2/` — legacy; avoid for new code
- `/rest/agile/1.0/` — Agile operations (boards, sprints, backlog)

## Issue Operations

### Get Issue
```bash
curl -s $JIRA_AUTH "https://$JIRA_SITE/rest/api/3/issue/PROJ-123" | jq .
```

### Get Specific Fields Only
```bash
curl -s $JIRA_AUTH \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123?fields=summary,status,assignee" \
  | jq .
```

### Create Issue
```bash
curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "fields": {
      "project": {"key": "PROJ"},
      "issuetype": {"name": "Story"},
      "summary": "Add password reset endpoint",
      "description": {
        "type": "doc",
        "version": 1,
        "content": [{
          "type": "paragraph",
          "content": [{"type": "text", "text": "AC: POST /api/auth/reset sends email"}]
        }]
      },
      "priority": {"name": "High"},
      "labels": ["backend", "auth"]
    }
  }' \
  "https://$JIRA_SITE/rest/api/3/issue"
```

**Note:** JIRA Cloud's API v3 uses the Atlassian Document Format (ADF) for the `description` field — a rich JSON structure, not plain text. For simple scripts, you can embed plain text in a single paragraph as shown.

### Update Issue
```bash
curl -s $JIRA_AUTH \
  -X PUT \
  -H "Content-Type: application/json" \
  --data '{
    "fields": {
      "summary": "Updated summary",
      "priority": {"name": "Critical"}
    }
  }' \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123"
```

### Delete Issue
```bash
curl -s $JIRA_AUTH \
  -X DELETE \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123"
```

## Transitions (Move Across Board)

### List Available Transitions
```bash
curl -s $JIRA_AUTH \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123/transitions" \
  | jq '.transitions[] | {id, name}'
```

### Execute a Transition
```bash
# Get the transition ID from the list above
TRANSITION_ID=21

curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data "{\"transition\": {\"id\": \"$TRANSITION_ID\"}}" \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123/transitions"
```

### Helper: Transition by Name
```bash
jira_transition() {
  local issue=$1
  local target_status=$2
  local transition_id=$(curl -s $JIRA_AUTH \
    "https://$JIRA_SITE/rest/api/3/issue/$issue/transitions" \
    | jq -r --arg name "$target_status" '.transitions[] | select(.name == $name) | .id')

  if [ -z "$transition_id" ]; then
    echo "No transition named '$target_status' available for $issue" >&2
    return 1
  fi

  curl -s $JIRA_AUTH \
    -X POST \
    -H "Content-Type: application/json" \
    --data "{\"transition\": {\"id\": \"$transition_id\"}}" \
    "https://$JIRA_SITE/rest/api/3/issue/$issue/transitions"
}

# Usage
jira_transition PROJ-123 "In Progress"
jira_transition PROJ-123 "Done"
```

## JQL Search

### Basic Search
```bash
curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "jql": "project = PROJ AND status = \"In Progress\"",
    "fields": ["summary", "status", "assignee"],
    "maxResults": 50
  }' \
  "https://$JIRA_SITE/rest/api/3/search"
```

### Extract Key Fields Only
```bash
curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"jql": "project = PROJ AND status = \"In Progress\"", "fields": ["summary"]}' \
  "https://$JIRA_SITE/rest/api/3/search" \
  | jq -r '.issues[] | "\(.key)\t\(.fields.summary)"'
```

### Paginate Through Large Result Sets
```bash
start_at=0
batch_size=50
while true; do
  response=$(curl -s $JIRA_AUTH \
    -X POST \
    -H "Content-Type: application/json" \
    --data "{\"jql\": \"project = PROJ\", \"startAt\": $start_at, \"maxResults\": $batch_size}" \
    "https://$JIRA_SITE/rest/api/3/search")

  echo "$response" | jq '.issues[] | .key'

  total=$(echo "$response" | jq '.total')
  start_at=$((start_at + batch_size))
  [ $start_at -ge $total ] && break
done
```

## Sprints (Agile API)

### List Boards
```bash
curl -s $JIRA_AUTH "https://$JIRA_SITE/rest/agile/1.0/board" | jq '.values[] | {id, name, type}'
```

### Get Sprints for a Board
```bash
BOARD_ID=3
curl -s $JIRA_AUTH \
  "https://$JIRA_SITE/rest/agile/1.0/board/$BOARD_ID/sprint?state=active,future" \
  | jq '.values[] | {id, name, state, startDate, endDate}'
```

### Get Issues in a Sprint
```bash
SPRINT_ID=42
curl -s $JIRA_AUTH \
  "https://$JIRA_SITE/rest/agile/1.0/sprint/$SPRINT_ID/issue" \
  | jq '.issues[] | {key, summary: .fields.summary, status: .fields.status.name}'
```

### Add Issues to a Sprint
```bash
curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"issues": ["PROJ-123", "PROJ-124", "PROJ-125"]}' \
  "https://$JIRA_SITE/rest/agile/1.0/sprint/$SPRINT_ID/issue"
```

### Create a Sprint
```bash
curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "name": "Sprint 42",
    "originBoardId": 3,
    "startDate": "2026-04-15T00:00:00.000Z",
    "endDate": "2026-04-29T00:00:00.000Z"
  }' \
  "https://$JIRA_SITE/rest/agile/1.0/sprint"
```

### Start / Close a Sprint
```bash
curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"state": "active"}' \
  "https://$JIRA_SITE/rest/agile/1.0/sprint/$SPRINT_ID"

curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"state": "closed"}' \
  "https://$JIRA_SITE/rest/agile/1.0/sprint/$SPRINT_ID"
```

## Comments

```bash
# Add comment
curl -s $JIRA_AUTH \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{
    "body": {
      "type": "doc",
      "version": 1,
      "content": [{
        "type": "paragraph",
        "content": [{"type": "text", "text": "Blocking on PROJ-456"}]
      }]
    }
  }' \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123/comment"

# List comments
curl -s $JIRA_AUTH \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123/comment" \
  | jq '.comments[] | {author: .author.displayName, body: .body, created}'
```

## Custom Fields

Custom fields have keys like `customfield_10016`. Find yours:
```bash
curl -s $JIRA_AUTH "https://$JIRA_SITE/rest/api/3/field" \
  | jq '.[] | select(.custom == true) | {id, name}'
```

Set a custom field value:
```bash
curl -s $JIRA_AUTH \
  -X PUT \
  -H "Content-Type: application/json" \
  --data '{"fields": {"customfield_10016": 5}}' \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123"
```

## Error Handling

### Check HTTP Status in Scripts
```bash
http_code=$(curl -s $JIRA_AUTH \
  -o /tmp/jira-response.json \
  -w "%{http_code}" \
  "https://$JIRA_SITE/rest/api/3/issue/PROJ-123")

if [ "$http_code" = "200" ]; then
  cat /tmp/jira-response.json | jq .summary
else
  echo "Error: HTTP $http_code" >&2
  cat /tmp/jira-response.json >&2
  exit 1
fi
```

### Common Errors
- `401 Unauthorized` — bad token or email
- `403 Forbidden` — token valid but user lacks permission
- `404 Not Found` — issue/sprint doesn't exist or isn't accessible
- `400 Bad Request` — malformed JSON body; verify with `jq .` first

## Rate Limits

JIRA Cloud enforces rate limits:
- Standard plan: 5 requests/second per user
- Premium: 10 req/sec
- Enterprise: higher

Bulk scripts should sleep between requests:
```bash
for key in PROJ-{100..200}; do
  curl -s $JIRA_AUTH "https://$JIRA_SITE/rest/api/3/issue/$key" | jq .fields.status.name
  sleep 0.3
done
```

## Security

- Always quote `$JIRA_AUTH` in subshells to avoid token exposure via `ps` or shell history
- Use `set +x` before auth-sensitive commands if you have `set -x` trace on
- Never log full request bodies in CI — tokens can leak into CI artifacts
- Rotate tokens quarterly via https://id.atlassian.com/manage-profile/security/api-tokens
