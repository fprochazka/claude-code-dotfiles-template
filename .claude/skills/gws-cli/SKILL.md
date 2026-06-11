---
name: gws-cli
description: Google Workspace CLI (gws) for accessing Google Drive, Docs, Sheets, Slides, Gmail, Calendar, Tasks and more. Multi-account setup with wrapper scripts for work and personal Google accounts.
trigger-keywords: gws, google workspace, google drive, google docs, google sheets, google slides, google calendar, google tasks, gmail
---

# gws - Google Workspace CLI

Multi-account setup via wrapper scripts in `~/.local/bin/`:

| Command | Account | Config dir |
|---|---|---|
| `gws-work` | `you@example.com` | `~/.config/gws/work/` |
| `gws-personal` | `you@gmail.com` | `~/.config/gws/personal/` |

Each wrapper sets `GOOGLE_WORKSPACE_CLI_CONFIG_DIR` to the appropriate directory.

## Usage

```bash
# List Drive files
gws-work drive files list --format json
gws-personal drive files list --format json

# Search files
gws-work drive files list --params '{"q":"name contains \"report\""}' --format json

# List unread emails
gws-work gmail users messages list --params '{"userId":"me","q":"is:unread","maxResults":10}' --format json

# Calendar events
gws-work calendar events list --params '{"calendarId":"primary","singleEvents":true,"orderBy":"startTime"}' --format json

# Get help for any service
gws-work drive --help
gws-work gmail --help
```

All API parameters go in `--params` as JSON. Use `gws-work <service> --help` for the full command reference.

## Auth management

```bash
gws-work auth status
gws-work auth login          # interactive scope picker
gws-work auth login --readonly  # read-only scopes
gws-work auth logout
```

## References

Load these when working with a specific service — they cover the `batchUpdate` patterns, gotchas, and end-to-end examples that `--help` alone doesn't give you.

- **[references/slides.md](references/slides.md)** — Google Slides: creating text-based slides, speaker notes (two-phase flow), `batchUpdate` request types, EMU coordinate system, thumbnails for visual inspection, custom layouts with manual text boxes, nested bullets, gotchas
- **[references/docs.md](references/docs.md)** — Google Docs: index-based `batchUpdate`, document tabs (`tabId`), text insertion/deletion/replacement, formatting (text style, paragraph style, headings, bullets), tables, headers/footers/footnotes, gotchas (index shifting, trailing newline, fields mask)
- **[references/drive-comments.md](references/drive-comments.md)** — Drive Comments: listing/reading comments on any file (Docs, Sheets, Slides), filtering unresolved vs resolved (client-side jq), filtering by slide, replies, anchor structure
