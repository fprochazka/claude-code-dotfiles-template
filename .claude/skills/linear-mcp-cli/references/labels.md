# Labels Reference

Labels can be scoped to a workspace (available to all teams) or a specific team.

## list_issue_labels

List available issue labels.

```bash
# All labels (workspace + all teams)
linear-mcp list_issue_labels

# Labels for a specific team
linear-mcp list_issue_labels --team "Engineering"

# Filter by name
linear-mcp list_issue_labels --name "bug"
```

| Option | Description |
|--------|-------------|
| `--team` | Team name or ID |
| `--name` | Filter by label name |
| `--limit` | Max results (default 50, max 250) |

## create_issue_label

Create a new issue label.

```bash
# Workspace-level label (available to all teams)
linear-mcp create_issue_label --name "critical" --color "#FF0000"

# Team-specific label
linear-mcp create_issue_label --name "frontend" --teamId "team-uuid" --color "#3B82F6"

# With description
linear-mcp create_issue_label --name "needs-review" \
  --description "Issues requiring code review" \
  --color "#F59E0B"

# Create a label group (cannot be applied directly to issues)
linear-mcp create_issue_label --name "Priority" --isGroup true

# Child label in a group
linear-mcp create_issue_label --name "P0" --parent "Priority" --color "#EF4444"
```

| Option | Description |
|--------|-------------|
| `--name` | Label name (required) |
| `--color` | Hex color code |
| `--description` | Label description |
| `--teamId` | Team UUID (omit for workspace label) |
| `--parent` | Parent label group name |
| `--isGroup` | Create as label group (default false) |

**Note:** `--teamId` requires an internal UUID.
