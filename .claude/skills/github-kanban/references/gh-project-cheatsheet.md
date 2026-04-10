# gh project — CLI Cheatsheet

Quick reference for all `gh project` subcommands. Run `gh project --help` for the current authoritative list.

## Global Flags
- `--owner <OWNER>` — `@me` for personal, or an org name
- `--format json` — machine-readable output (pipe into `jq`)

## Project Management

| Command | Purpose |
|---------|---------|
| `gh project list --owner <OWNER>` | List all projects for a user/org |
| `gh project view <NUMBER> --owner <OWNER>` | View project details |
| `gh project create --owner <OWNER> --title <TITLE>` | Create a new project |
| `gh project delete <NUMBER> --owner <OWNER>` | Delete a project (prompts for confirmation) |
| `gh project edit <NUMBER> --owner <OWNER> --title <NEW_TITLE>` | Rename |
| `gh project close <NUMBER> --owner <OWNER>` | Close (archive) a project |
| `gh project copy <NUMBER> --source-owner <OWNER> --target-owner <OWNER> --title <TITLE>` | Copy/template a project |

## Field Management

| Command | Purpose |
|---------|---------|
| `gh project field-list <NUMBER> --owner <OWNER>` | List fields |
| `gh project field-create <NUMBER> --owner <OWNER> --name <NAME> --data-type <TYPE>` | Create field |
| `gh project field-delete --id <FIELD_ID>` | Delete field |

**Field data types:** `TEXT`, `NUMBER`, `DATE`, `SINGLE_SELECT`, `ITERATION`

**Single-select options:** pass `--single-select-options "Option1,Option2,Option3"`

## Item Management

| Command | Purpose |
|---------|---------|
| `gh project item-list <NUMBER> --owner <OWNER>` | List items on the board |
| `gh project item-add <NUMBER> --owner <OWNER> --url <URL>` | Add existing issue/PR |
| `gh project item-create <NUMBER> --owner <OWNER> --title <T> --body <B>` | Create a draft item |
| `gh project item-edit --project-id <PID> --id <IID> --field-id <FID> --<VALUE_FLAG> <VAL>` | Edit an item's field |
| `gh project item-delete --project-id <PID> --id <IID>` | Delete from project (doesn't delete issue) |
| `gh project item-archive --project-id <PID> --id <IID>` | Archive item |

## Item Value Flags

For `gh project item-edit`, the value flag depends on the field's data type:

| Field Type | Flag |
|------------|------|
| `TEXT` | `--text "value"` |
| `NUMBER` | `--number 5` |
| `DATE` | `--date 2026-04-15` |
| `SINGLE_SELECT` | `--single-select-option-id <OPTION_ID>` |
| `ITERATION` | `--iteration-id <ITERATION_ID>` |

## Authentication

| Command | Purpose |
|---------|---------|
| `gh auth status` | Check logged-in account and scopes |
| `gh auth refresh -h github.com -s project` | Add `project` scope to existing auth |
| `gh auth login` | Fresh login (prompts for scopes) |

## Useful `jq` Patterns

```bash
# Extract just titles and statuses
| jq '.items[] | {title: .content.title, status}'

# Filter by status
| jq '.items[] | select(.status == "In Progress")'

# Count
| jq '.items | length'

# Sum a numeric field
| jq '[.items[] | .["story points"] // 0] | add'

# Group by a field
| jq '.items | group_by(.status) | map({status: .[0].status, count: length})'
```

## Common Gotchas

- **`project` scope must be enabled.** Default `gh auth login` doesn't grant it.
- **Long vs short IDs.** `--project-id` takes the long `PVT_...` form. Positional `<NUMBER>` takes the short number like `3`.
- **JSON field names are lowercased.** `Story Points` in the UI becomes `"story points"` in JSON. Use bracket notation in jq: `.["story points"]`.
- **Draft items** don't have `content.number` or `content.url`. Handle both cases in scripts.
- **Archived items** aren't returned by default — use `--archived` flag to include them.
- **Rate limits apply** — `gh` inherits the GitHub API rate limit (5000/hr authenticated). Bulk operations on very large projects may hit it.
