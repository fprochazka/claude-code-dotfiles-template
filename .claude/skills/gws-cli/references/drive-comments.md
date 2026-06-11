# Drive Comments via gws

Comments on Google Docs, Sheets, and Slides are managed through the **Drive API**, not the service-specific APIs. Everything below uses the `gws-personal` / `gws-work` wrapper scripts. Substitute the one that owns the target file.

## Command shape

| Command | Purpose |
|---|---|
| `gws-personal drive comments list --params '{"fileId":"...","fields":"*"}' --format json` | List all comments on a file |
| `gws-personal drive comments get --params '{"fileId":"...","commentId":"...","fields":"*"}' --format json` | Get a single comment by ID |
| `gws-personal drive comments create --params '{"fileId":"..."}' --json '{"content":"..."}' --format json` | Create a new comment |
| `gws-personal drive comments update --params '{"fileId":"...","commentId":"..."}' --json '{"content":"..."}' --format json` | Update a comment |
| `gws-personal drive comments delete --params '{"fileId":"...","commentId":"..."}' --format json` | Delete a comment |
| `gws-personal drive replies list --params '{"fileId":"...","commentId":"...","fields":"*"}' --format json` | List replies on a comment |

**Always pass `"fields":"*"`** — the API requires the `fields` parameter and returns minimal data without it.

## Listing comments

```bash
gws-personal drive comments list \
  --params '{"fileId":"FILE_ID","fields":"*"}' \
  --format json --page-all
```

Use `--page-all` for files with many comments (paginates automatically).

## Response structure

Each comment object contains:

```
.id              → comment ID (e.g. "AAAB3Kinocg")
.content         → plain text of the comment
.htmlContent     → HTML version
.author          → { displayName, me, photoLink }
.createdTime     → ISO 8601 timestamp
.modifiedTime    → ISO 8601 timestamp
.resolved        → true if resolved, absent/null if unresolved
.deleted         → true if deleted
.quotedFileContent.value → the text/element the comment is anchored to
.anchor          → JSON string with location info (page, shape, etc.)
.replies[]       → array of reply objects
```

For Slides, the `.anchor` field contains a JSON string identifying the slide and shape:

```json
{"type":"shape","subtype":"text","uid":...,"page":"sec2_slide07","targets":["sec2_slide07_title"]}
```

## Filtering unresolved comments

There is **no server-side filter** for resolved/unresolved. Filter client-side with jq:

```bash
# Unresolved comments only
gws-personal drive comments list \
  --params '{"fileId":"FILE_ID","fields":"*"}' \
  --format json --page-all \
  | jq '[.comments[] | select(.resolved != true)]'

# Resolved comments only
gws-personal drive comments list \
  --params '{"fileId":"FILE_ID","fields":"*"}' \
  --format json --page-all \
  | jq '[.comments[] | select(.resolved == true)]'
```

## Filtering by slide (Slides-specific)

The `.anchor` field is a JSON string. Parse it with jq to filter by slide:

```bash
# Comments on a specific slide
gws-personal drive comments list \
  --params '{"fileId":"FILE_ID","fields":"*"}' \
  --format json --page-all \
  | jq '[.comments[] | select(.anchor | fromjson | .page == "sec2_slide07")]'
```

## Resolving / reopening comments

Comments are resolved and reopened via **replies with an `action` field**, not by updating the comment directly. The `action` goes on a reply object, not the comment.

### Resolve a comment

```bash
DECK="FILE_ID"
gws-personal drive replies create \
  --params "{\"fileId\":\"$DECK\",\"commentId\":\"COMMENT_ID\",\"fields\":\"*\"}" \
  --json '{"action":"resolve","content":"Resolved."}' \
  --format json 2>/dev/null | jq '{id,action}'
```

The `content` field is optional but recommended — it shows up as the resolution message in the UI. The `action` field must be exactly `"resolve"`.

### Reopen a resolved comment

```bash
gws-personal drive replies create \
  --params "{\"fileId\":\"$DECK\",\"commentId\":\"COMMENT_ID\",\"fields\":\"*\"}" \
  --json '{"action":"reopen","content":"Reopening — needs another look."}' \
  --format json 2>/dev/null | jq '{id,action}'
```

### Common mistake

Do NOT try to resolve via `comments update` with `{"resolved":true}` — the `resolved` field is read-only on the comment object. Resolution is always done by creating a reply with `action:"resolve"`.

---

## Including deleted comments

By default, deleted comments are excluded. To include them:

```bash
gws-personal drive comments list \
  --params '{"fileId":"FILE_ID","fields":"*","includeDeleted":true}' \
  --format json
```
