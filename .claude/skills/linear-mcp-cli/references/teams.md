# Teams Reference

**Important:** When filtering issues/projects by team, use the **exact full team name** (e.g., `"Frontend Engineering"`), not the issue prefix abbreviation (e.g., `"FE"`). Run `list_teams` first to find correct names.

## list_teams

List teams in the workspace.

```bash
# All teams
linear-mcp list_teams

# Search by name
linear-mcp list_teams --query "Engineering"

# Recently updated
linear-mcp list_teams --updatedAt "-P30D"
```

| Option | Description |
|--------|-------------|
| `--query` | Search in team name |
| `--createdAt`, `--updatedAt` | ISO-8601 or duration |
| `--limit` | Max results (default 50, max 250) |
| `--includeArchived` | Include archived teams |

## get_team

Get team details.

```bash
# By name
linear-mcp get_team --query "Engineering"

# By key
linear-mcp get_team --query "ENG"

# By UUID
linear-mcp get_team --query "team-uuid"
```

**Note:** `--query` accepts team name, key, or UUID.

## list_issue_statuses

List workflow statuses for a team. Statuses are team-specific.

```bash
linear-mcp list_issue_statuses --team "Engineering"
```

Returns statuses with their names and types. When filtering issues by `--state`, use the **status name** (e.g., `"In Progress"`, `"Backlog"`), not the type (e.g., `"started"`, `"backlog"`). Names are case-insensitive.

**Note:** `--team` accepts exact team name or ID.

## get_issue_status

Get details of a specific issue status.

```bash
linear-mcp get_issue_status --team "Engineering" --name "In Progress"

# Or by ID
linear-mcp get_issue_status --team "Engineering" --id "status-uuid"
```

## list_cycles

List cycles (sprints) for a team.

```bash
# All cycles
linear-mcp list_cycles --teamId "team-uuid"

# Current cycle only
linear-mcp list_cycles --teamId "team-uuid" --type "current"

# Previous cycle
linear-mcp list_cycles --teamId "team-uuid" --type "previous"

# Next cycle
linear-mcp list_cycles --teamId "team-uuid" --type "next"
```

**Note:** `--teamId` requires the internal UUID from `list_teams`.

| Option | Description |
|--------|-------------|
| `--teamId` | Team UUID (required) |
| `--type` | `current`, `previous`, `next`, or omit for all |
