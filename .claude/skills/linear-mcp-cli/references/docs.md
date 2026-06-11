# Documentation Reference

## search_documentation

Search Linear's official documentation.

```bash
# Search for workflow info
linear-mcp search_documentation --query "workflow states"

# Search for integration docs
linear-mcp search_documentation --query "github integration"

# Search for API info
linear-mcp search_documentation --query "webhooks"
```

| Option | Description |
|--------|-------------|
| `--query` | Search query (required) |
| `--page` | Page number for pagination (default 0) |

Returns documentation snippets with title, URL, and relevant content.
