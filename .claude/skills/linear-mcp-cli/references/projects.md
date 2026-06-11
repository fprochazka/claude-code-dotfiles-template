# Projects Reference

## list_projects

List projects in the workspace.

```bash
# All projects
linear-mcp list_projects

# By team
linear-mcp list_projects --team "Engineering"

# By state
linear-mcp list_projects --state "started"

# My projects
linear-mcp list_projects --member "me"

# Search by name
linear-mcp list_projects --query "Q1"

# Recently updated
linear-mcp list_projects --updatedAt "-P7D"
```

| Option | Description |
|--------|-------------|
| `--team` | Team name or ID |
| `--state` | State name or ID |
| `--initiative` | Initiative name or ID |
| `--member` | User ID, name, email, or `"me"` |
| `--query` | Search in project name |
| `--createdAt`, `--updatedAt` | ISO-8601 or duration |
| `--limit` | Max results (default 50, max 250) |
| `--includeArchived` | Include archived projects |

## get_project

Get project details.

```bash
# By name
linear-mcp get_project --query "Q1 Roadmap"

# By ID
linear-mcp get_project --query "project-uuid"
```

**Note:** `--query` accepts project name, ID, or slug.

## save_project

Create or update a project. If `--id` is provided, updates the existing project; otherwise creates a new one. When creating, `--name` and at least one team (via `--addTeams` or `--setTeams`) are required.

```bash
# Create basic
linear-mcp save_project --name "Q2 Roadmap" --addTeams "Engineering"

# Create with description (write to file first, see "Content Preparation Workflow" in SKILL.md)
linear-mcp save_project --name "Q2 Roadmap" --addTeams "Engineering" \
  --description "$(cat /tmp/project-desc-UNIQUE.md)" \
  --summary "Q2 engineering initiatives" \
  --lead "me" \
  --priority 2

# Create with dates
linear-mcp save_project --name "Q2 Roadmap" --addTeams "Engineering" \
  --startDate "2024-04-01" \
  --targetDate "2024-06-30"

# Create with multiple teams and labels
linear-mcp save_project --name "Mobile App" \
  --setTeams "Engineering" --setTeams "Mobile" \
  --icon ":iphone:" \
  --color "#FF5733" \
  --labels '["mobile", "priority"]'

# Update state
linear-mcp save_project --id "project-uuid" --state "completed"

# Update lead
linear-mcp save_project --id "project-uuid" --lead "jane@example.com"

# Update dates
linear-mcp save_project --id "project-uuid" \
  --targetDate "2024-07-15"

# Update description (write to file first, see "Content Preparation Workflow" in SKILL.md)
linear-mcp save_project --id "project-uuid" \
  --description "$(cat /tmp/project-desc-UNIQUE.md)"

# Add/remove a team on an existing project
linear-mcp save_project --id "project-uuid" --addTeams "Design"
linear-mcp save_project --id "project-uuid" --removeTeams "Design"

# Link/unlink initiatives
linear-mcp save_project --id "project-uuid" --addInitiatives "Q2 Goals"
linear-mcp save_project --id "project-uuid" --removeInitiatives "Q2 Goals"
```

| Option | Description |
|--------|-------------|
| `--id` | Project ID. If provided, updates; otherwise creates |
| `--name` | Project name (required when creating) |
| `--addTeams` | Team name or ID to add. At least one team via `--addTeams` or `--setTeams` is required when creating |
| `--removeTeams` | Team name or ID to remove |
| `--setTeams` | Replace all teams with these. Cannot combine with `--addTeams`/`--removeTeams` |
| `--description` | Full Markdown description |
| `--summary` | Plaintext summary (max 255 chars) |
| `--lead` | User ID, name, email, or `"me"`. Null to remove |
| `--priority` | 0-4 (see priority values) |
| `--state` | Project state |
| `--addInitiatives` | Initiative name or ID to add |
| `--removeInitiatives` | Initiative name or ID to remove |
| `--setInitiatives` | Replace all initiatives with these. Cannot combine with `--addInitiatives`/`--removeInitiatives` |
| `--startDate`, `--targetDate` | ISO date format |
| `--startDateResolution`, `--targetDateResolution` | Date precision (e.g., `month`, `quarter`) |
| `--icon` | Emoji (e.g., `:eagle:`) |
| `--color` | Hex color code |
| `--labels` | Label names or IDs |

## list_project_labels

List labels available for projects.

```bash
linear-mcp list_project_labels

# Filter by name
linear-mcp list_project_labels --name "priority"
```
