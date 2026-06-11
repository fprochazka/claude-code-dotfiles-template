# Comments Reference

## list_comments

List comments for an issue.

```bash
# By issue identifier
linear-mcp list_comments --issueId "ABC-123"

# Or by issue UUID
linear-mcp list_comments --issueId "issue-uuid"
```

**Note:** `--issueId` accepts the issue identifier (e.g., `ABC-123`) or the internal UUID.

## save_comment

Create or update a comment on an issue. If `--id` is provided, updates the existing comment; otherwise creates a new one.

```bash
# Create a new top-level comment (write to file first, see "Content Preparation Workflow" in SKILL.md)
linear-mcp save_comment --issueId "ABC-123" \
  --body "$(cat /tmp/comment-ABC-123.md)"

# Reply to an existing comment (thread)
linear-mcp save_comment --issueId "ABC-123" \
  --parentId "comment-uuid" \
  --body "$(cat /tmp/comment-reply-ABC-123.md)"

# Update an existing comment
linear-mcp save_comment --id "comment-uuid" \
  --body "$(cat /tmp/comment-edit-ABC-123.md)"
```

| Option | Description |
|--------|-------------|
| `--id` | Comment ID. If provided, updates the existing comment |
| `--issueId` | Issue ID or identifier (e.g., `ABC-123`). Required when creating a new top-level comment |
| `--parentId` | Parent comment UUID (for replies, only when creating) |
| `--body` | Comment content as Markdown (required) |

**Note:** `save_comment` can also target projects, initiatives, documents, and project milestones (via `--projectId`, `--initiativeId`, `--documentId`, `--milestoneId`) — see `linear-mcp save_comment --help`.
