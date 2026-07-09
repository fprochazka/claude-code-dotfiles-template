---
name: linear-mcp-cli
description: CLI for querying Linear (issues, projects, teams, documents, comments). Use when managing issues, creating/updating tasks, exploring projects, or integrating Linear with workflows. Triggered by requests involving Linear data, issue tracking, or project management.
trigger-keywords: linear, issue, issues, tasks, task, ticket, tickets
allowed-tools: Bash(linear-mcp --help), Bash(linear-mcp config:*), Bash(linear-mcp get_document:*), Bash(linear-mcp get_issue:*), Bash(linear-mcp get_issue_status:*), Bash(linear-mcp get_project:*), Bash(linear-mcp get_team:*), Bash(linear-mcp get_user:*), Bash(linear-mcp list_comments:*), Bash(linear-mcp list_cycles:*), Bash(linear-mcp list_documents:*), Bash(linear-mcp list_issue_labels:*), Bash(linear-mcp list_issue_statuses:*), Bash(linear-mcp list_issues:*), Bash(linear-mcp list_project_labels:*), Bash(linear-mcp list_projects:*), Bash(linear-mcp list_teams:*), Bash(linear-mcp list_users:*), Bash(linear-mcp search_documentation:*), Bash(linear-mcp save_comment --help), Bash(linear-mcp save_document --help), Bash(linear-mcp save_issue --help), Bash(linear-mcp create_issue_label --help), Bash(linear-mcp save_project --help)
---

# Linear MCP CLI

CLI tool providing direct access to Linear data. Each Linear MCP tool is exposed as a command.

## ⚠️ Mutating commands are NOT idempotent — never re-run a create to inspect its output

`save_issue` (without `--id`), `save_project`, `save_comment` (without `--id`), `save_document` (without `--id`/slug), and `create_issue_label` **create a brand-new record on every invocation**. Running one twice makes a duplicate.

**The exact trap that has caused duplicate tickets more than once:** you run a create, pipe it through `grep`/`jq`/`tail`/`head` to pull the identifier or URL, the filter matches nothing (a field you expected is named differently, or the shape differs), you read the empty output as *"it didn't return what I wanted / it didn't work"* and re-run the same command — but the **first create already succeeded**. Now there are two tickets.

**Hard rules — follow all of them:**

1. **Run a create with NO output filter.** Never pipe a `save_*`-create through `grep`/`jq`/`tail`/`head`. Print the whole response and read the `id`/`identifier`/`url` straight from it — the response always contains them. Filtering is what hides success and triggers the fatal retry.
2. **Never re-run a create to reformat, re-extract, or "just get the URL" of something you just made.** If you missed a field, DO NOT re-create — look it up with a **read-only** `get_issue`/`list_issues` instead.
3. **If a create's result looks empty, errored inside a pipe, or is ambiguous, assume it MAY have succeeded.** Verify with `list_issues`/`get_issue` **before** retrying. Only retry a create after you've confirmed nothing was created.
4. **After a create, every further change uses `--id`** (that UPDATES and is safe to repeat). A `save_*` *with* `--id` = update; *without* `--id` = create. When in doubt, check for the `--id`.

## Quick Reference

| Entity | Commands | Reference |
|--------|----------|-----------|
| **Issues** | `list_issues`, `get_issue`, `save_issue` | *(below)* |
| **Projects** | `list_projects`, `get_project`, `save_project`, `list_project_labels` | [projects.md](references/projects.md) |
| **Teams** | `list_teams`, `get_team`, `list_issue_statuses`, `get_issue_status`, `list_cycles` | [teams.md](references/teams.md) |
| **Users** | `list_users`, `get_user` | [users.md](references/users.md) |
| **Labels** | `list_issue_labels`, `create_issue_label` | [labels.md](references/labels.md) |
| **Documents** | `list_documents`, `get_document`, `save_document` | [documents.md](references/documents.md) |
| **Comments** | `list_comments`, `save_comment` | [comments.md](references/comments.md) |
| **Docs** | `search_documentation` | [docs.md](references/docs.md) |

## Parameter Resolution

Most parameters accept human-readable names. The MCP server resolves them to internal IDs.

| Parameter | Accepts | Example |
|-----------|---------|---------|
| `--team`, `--project`, `--state`, `--cycle`, `--milestone`, `--label`, `--initiative` | **Exact full name** (case-insensitive) or ID | `--team "Engineering"` |
| `--assignee`, `--member`, `--lead` | User ID, name, email, or `"me"` | `--assignee "me"` |
| `--labels` (array) | Names or IDs | `'["bug", "critical"]'` |

**Important: Use exact full names, not abbreviations or partial matches.**

| Filter | Works | Doesn't work |
|--------|-------|--------------|
| `--team` | `"Frontend Engineering"` (full name) | `"FE"` (issue prefix) |
| `--project` | `"API Redesign (Q1 2025)"` (full name) | `"API Redesign"` (partial) |
| `--state` | `"In Progress"` (status name) | `"started"` (status type) |

To find correct names, first run `list_teams`, `list_projects`, or `list_issue_statuses --team "Team Name"`.

**Issue ID or identifier** (e.g., `ABC-123`) — accepted in:

| Parameter | Context |
|-----------|---------|
| `--id` | `get_issue`, `save_issue` |
| `--issueId` | `list_comments`, `save_comment` |
| `--parentId` | `save_issue` (sub-issues) |
| `--blocks`, `--blockedBy`, `--relatedTo`, `--duplicateOf` | `save_issue` relations (e.g., `'["ABC-123"]'`) |
| `--removeBlocks`, `--removeBlockedBy`, `--removeRelatedTo` | `save_issue` relation removal |

**Internal UUID required** (from prior `list_*` or `get_*` calls):

| Parameter | Context |
|-----------|---------|
| `--id` | `save_project`, `save_comment` (update) |
| `--id` (or slug) | `get_document`, `save_document` (update) |
| `--teamId` | `list_cycles`, `create_issue_label` |
| `--parentId` | `save_comment` (replies), `create_issue_label` (child labels) |
| `--projectId`, `--initiativeId`, `--creatorId` | `list_documents` filters |

## Array Syntax

Pass arrays as JSON strings:

```bash
--labels '["bug", "critical"]'
--links '[{"url": "https://github.com/...", "title": "PR"}]'
```

## Priority Values

| Value | Issue | Project |
|-------|-------|---------|
| `0` | No priority | No priority |
| `1` | Urgent | Urgent |
| `2` | High | High |
| `3` | Normal | Medium |
| `4` | Low | Low |

## Content Preparation Workflow (REQUIRED for long content)

**For any argument longer than a few words (descriptions, comments, document bodies), you MUST pass it via a file using `"$(cat <path>)"` rather than inlining.** This prevents shell escaping issues, preserves formatting, lets the user review before submission, and keeps edits cheap.

- If the content already exists as a file on disk, use it directly — do **not** copy it to `/tmp` first.
- When generating new content, write it to a `/tmp/` file named uniquely for the ticket/document (e.g., `/tmp/desc-ENG-123.md`, `/tmp/comment-ENG-456.md`). **Never** use generic names like `/tmp/desc.md` — they collide across tickets.
- Reuse the same file for the same ticket/document across edits — the Write tool diff shows the user exactly what changed.

| Parameter | Example |
|-----------|---------|
| `--description` | `--description "$(cat /tmp/desc-ENG-123.md)"` |
| `--body` | `--body "$(cat /tmp/comment-ENG-123.md)"` |
| `--content` | `--content "$(cat /tmp/doc-roadmap-q2.md)"` |

**Short, single-line values** (titles, names, summaries) can be passed directly as strings.

## Getting Command Help

```bash
linear-mcp <command> --help
```

---

# Issues Reference

## list_issues

List issues in the workspace with filters.

```bash
# My issues
linear-mcp list_issues --assignee "me"

# Filter by state and team
linear-mcp list_issues --state "In Progress" --team "Engineering"

# By project
linear-mcp list_issues --project "Q1 Roadmap"

# Recently updated
linear-mcp list_issues --updatedAt "-P1D"

# Combine filters
linear-mcp list_issues --team "Engineering" --state "In Progress" --assignee "me" --limit 25
```

| Option | Description |
|--------|-------------|
| `--assignee` | User ID, name, email, or `"me"` |
| `--delegate` | Agent name or ID |
| `--team` | **Exact** team name or ID (not issue prefix abbreviations) |
| `--state` | **Exact** status name or ID (not types like "started") |
| `--project` | **Exact** project name or ID (partial names don't work) |
| `--cycle` | Cycle name or ID |
| `--label` | Label name or ID |
| `--query` | Search in title/description |
| `--parentId` | Parent issue UUID (for sub-issues) |
| `--createdAt`, `--updatedAt` | ISO-8601 or duration (e.g., `-P1D`) |
| `--limit` | Max results (default 50, max 250) |
| `--includeArchived` | Include archived issues (default true) |

## get_issue

Get detailed issue info including attachments and git branch name.

```bash
linear-mcp get_issue --id "ABC-123"

# Include relations (blocking, related, duplicate)
linear-mcp get_issue --id "ABC-123" --includeRelations true
```

**Note:** `--id` accepts either the internal UUID or the issue identifier (e.g., `ABC-123`).

## save_issue

Create or update an issue. If `--id` is provided, updates the existing issue; otherwise creates a new one. When creating, `--title` and `--team` are required.

> **Creating (no `--id`) is a non-idempotent mutation — see the ⚠️ section at the top.** Run the create unpiped, read the `identifier`/`url` from the full response, and never re-run it to fetch a field you missed (use `get_issue`/`list_issues` for that). A second run = a duplicate ticket.

```bash
# Create basic (no description)
linear-mcp save_issue --team "Engineering" --title "Fix login bug"

# Create with description (write to file first, see "Content Preparation Workflow" above)
linear-mcp save_issue --team "Engineering" --title "Fix login bug" \
  --description "$(cat /tmp/issue-desc-UNIQUE.md)" \
  --assignee "me" \
  --priority 2 \
  --state "To Do" \
  --labels '["bug", "auth"]'

# Create with project and due date
linear-mcp save_issue --team "Engineering" --title "Implement feature" \
  --project "Q1 Roadmap" \
  --dueDate "2024-03-15"

# Create sub-issue
linear-mcp save_issue --team "Engineering" --title "Subtask" \
  --parentId "parent-issue-uuid"

# Create with links
linear-mcp save_issue --team "Engineering" --title "Fix bug" \
  --links '[{"url": "https://github.com/org/repo/pull/123", "title": "Fix PR"}]'

# Update state
linear-mcp save_issue --id "ABC-123" --state "Done"

# Reassign
linear-mcp save_issue --id "ABC-123" --assignee "jane@example.com"

# Update multiple fields
linear-mcp save_issue --id "ABC-123" \
  --state "In Progress" \
  --priority 1 \
  --labels '["urgent", "bug"]'

# Update description (write to file first, see "Content Preparation Workflow" above)
linear-mcp save_issue --id "ABC-123" \
  --description "$(cat /tmp/issue-desc-UNIQUE.md)"
```

| Option | Description |
|--------|-------------|
| `--id` | Issue ID or identifier (e.g., `ABC-123`). If provided, updates; otherwise creates |
| `--team` | Team name or ID (required when creating) |
| `--title` | Issue title (required when creating) |
| `--description` | Markdown description |
| `--assignee` | User ID, name, email, or `"me"` |
| `--delegate` | Agent name or ID |
| `--state` | State type, name, or ID |
| `--priority` | 0-4 (see priority values) |
| `--estimate` | Issue estimate value |
| `--project` | Project name or ID |
| `--cycle` | Cycle name, number, or ID |
| `--milestone` | Milestone name or ID |
| `--labels` | JSON array of label names or IDs |
| `--dueDate` | ISO date format |
| `--parentId` | Parent issue ID or identifier (e.g., `ABC-123`). Null to remove |
| `--links` | JSON array of `{url, title}` objects. **Append-only** — existing links are never removed |

## Issue Relations

Create relationships between issues using identifiers (e.g., `ABC-123`) or UUIDs.

```bash
# Block other issues
linear-mcp save_issue --team "Eng" --title "Blocker" \
  --blocks '["ABC-123", "ABC-124"]'

# Blocked by other issues
linear-mcp save_issue --team "Eng" --title "Waiting" \
  --blockedBy '["ABC-100"]'

# Related issues
linear-mcp save_issue --team "Eng" --title "Related work" \
  --relatedTo '["ABC-50", "ABC-51"]'

# Mark as duplicate
linear-mcp save_issue --id "ABC-456" --duplicateOf "ABC-123"
```

**Append-only semantics:** `--blocks`, `--blockedBy`, `--relatedTo` (and `--links`) only ADD relations — they never remove existing ones. To remove relations, use the corresponding `--removeBlocks`, `--removeBlockedBy`, `--removeRelatedTo` parameters.

```bash
# Add a new blocker (existing blockers are preserved)
linear-mcp save_issue --id "ABC-123" --blocks '["DEF-456"]'

# Stop blocking a specific issue
linear-mcp save_issue --id "ABC-123" --removeBlocks '["DEF-456"]'

# Swap a blocker in one call
linear-mcp save_issue --id "ABC-123" \
  --removeBlocks '["DEF-123"]' \
  --blocks '["DEF-456"]'
```

**Note:** `--duplicateOf` is single-valued — pass `null` to remove the duplicate relation.
