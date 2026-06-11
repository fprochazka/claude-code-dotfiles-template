# Documents Reference

## list_documents

List documents in the workspace.

```bash
# All documents
linear-mcp list_documents

# Search by content
linear-mcp list_documents --query "roadmap"

# By project
linear-mcp list_documents --projectId "project-uuid"

# Recently updated
linear-mcp list_documents --updatedAt "-P7D"
```

| Option | Description |
|--------|-------------|
| `--query` | Search query |
| `--projectId` | Project UUID |
| `--initiativeId` | Initiative UUID |
| `--creatorId` | Creator UUID |
| `--createdAt`, `--updatedAt` | ISO-8601 or duration |
| `--limit` | Max results (default 50, max 250) |
| `--includeArchived` | Include archived documents |

**Note:** Filter IDs (`--projectId`, `--initiativeId`, `--creatorId`) require internal UUIDs.

## get_document

Get document content by ID or slug.

```bash
# By ID
linear-mcp get_document --id "document-uuid"

# By slug
linear-mcp get_document --id "my-document-slug"
```

## save_document

Create or update a document. If `--id` is provided, updates the existing document; otherwise creates a new one. When creating, `--title` and exactly one parent (`--project`, `--issue`, `--initiative`, or `--cycle`) are required. On update, passing a parent reparents the document.

```bash
# Create basic (no content)
linear-mcp save_document --title "Meeting Notes" --project "Engineering"

# Create with content (write to file first, see "Content Preparation Workflow" in SKILL.md)
linear-mcp save_document --title "Architecture Decision" \
  --project "Backend Refactor" \
  --content "$(cat /tmp/doc-arch-decision-UNIQUE.md)"

# Attached to an issue
linear-mcp save_document --title "Investigation Notes" \
  --issue "ABC-123" \
  --content "$(cat /tmp/doc-investigation-UNIQUE.md)"

# With icon and color
linear-mcp save_document --title "Team Handbook" \
  --project "Engineering" \
  --icon ":book:" \
  --color "#10B981"

# Update content (write to file first)
linear-mcp save_document --id "document-uuid" \
  --content "$(cat /tmp/doc-update-UNIQUE.md)"

# Update title
linear-mcp save_document --id "document-uuid" --title "New Title"

# Reparent to a different project
linear-mcp save_document --id "document-uuid" --project "New Project"
```

| Option | Description |
|--------|-------------|
| `--id` | Document ID or slug. If provided, updates; otherwise creates |
| `--title` | Document title (required when creating) |
| `--project` | Project name, ID, or slug (parent) |
| `--issue` | Issue ID or identifier, e.g., `ABC-123` (parent) |
| `--initiative` | Initiative name or ID (parent) |
| `--cycle` | Cycle name, number, or ID (parent). Pair with `--team` to disambiguate names/numbers |
| `--team` | Team name or ID. Only used to resolve `--cycle` |
| `--content` | Markdown content |
| `--icon` | Emoji (e.g., `:page_facing_up:`) |
| `--color` | Icon hex color |

**Note:** Exactly one parent (`--project`, `--issue`, `--initiative`, or `--cycle`) is required when creating.
