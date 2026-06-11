# Users Reference

## list_users

List users in the workspace.

```bash
# All users
linear-mcp list_users

# Filter by team
linear-mcp list_users --team "Engineering"

# Search by name or email
linear-mcp list_users --query "john"
```

| Option | Description |
|--------|-------------|
| `--team` | Team name or ID |
| `--query` | Search by name or email |

## get_user

Get user details.

```bash
# By name
linear-mcp get_user --query "John Doe"

# By email
linear-mcp get_user --query "john@example.com"

# Current user
linear-mcp get_user --query "me"
```

**Note:** `--query` accepts user ID, name, email, or `"me"`.
