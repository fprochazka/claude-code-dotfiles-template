# Google Docs via gws

Everything below uses the `gws-personal` / `gws-work` wrapper scripts. Substitute the one that owns the target document.

## Command shape

| Command | Purpose |
|---|---|
| `gws-personal docs documents get --params '{"documentId":"...", "includeTabsContent":true}'` | Fetch full document JSON (all tabs, body, headers, footers) |
| `gws-personal docs documents batchUpdate --params '{"documentId":"..."}' --json '{"requests":[...]}'` | Apply any edit — the only write endpoint you need |
| `gws-personal docs documents create --json '{"title":"..."}'` | Create a new blank document |

**All edits go through `batchUpdate`.** The `requests` array holds typed request objects, all applied atomically. Failure in any one request rolls back the whole batch.

## Key difference from Slides

Docs operations are **cursor/index-based**, not object-ID-based. You target positions by character `index` within a document (or tab). Every character, paragraph mark, table cell boundary, etc. has a zero-based index. The first content position is index `1` (index `0` is before the document body start marker).

## Reading document content

```bash
gws-personal docs documents get --params '{"documentId":"DOC_ID", "includeTabsContent":true}' > /tmp/doc.json
```

**Always pass `includeTabsContent: true`** — without it, the response uses the legacy flat `document.body` which ignores tabs and may return incomplete content.

The response structure with tabs:

```
document.tabs[0].tabProperties.tabId → "t.0"
document.tabs[0].body.content[] → structural elements (paragraphs, tables, etc.)
document.tabs[1].tabProperties.tabId → "t.abc123"
document.tabs[1].body.content[] → ...
```

### Finding text and its index

Each structural element has a `startIndex` and `endIndex`. To find a specific string:

```bash
jq -r '.tabs[0].body.content[] | select(.paragraph?) | .paragraph.elements[] | select(.textRun?) | "\(.startIndex)-\(.endIndex): \(.textRun.content)"' /tmp/doc.json
```

This gives you `startIndex-endIndex: text` for every text run in the first tab.

---

## Document tabs

Google Docs supports multiple tabs (like spreadsheet sheets). Each tab has its own body content, headers, and footers.

### Getting tab IDs

```bash
jq '[.tabs[] | {tabId: .tabProperties.tabId, title: .tabProperties.title}]' /tmp/doc.json
```

### Targeting a specific tab in batchUpdate

Put `tabId` inside each request's `Location` or `Range` object:

```json
{
  "insertText": {
    "location": {
      "index": 25,
      "tabId": "t.0"
    },
    "text": "Hello world"
  }
}
```

### Default behavior when tabId is omitted

- Most requests default to the **first tab** — no error is thrown
- `replaceAllText`, `deleteNamedRange`, and `replaceNamedRangeContent` apply **across all tabs** when tabId is omitted

### Tab limitations

- **Cannot create or delete tabs** via the API — only edit content within existing tabs
- Tabs can only be created/deleted through the Docs UI
- This is a confirmed API gap (Google Issue Tracker #375867285)

---

## Inserting text

```json
{
  "requests": [
    {
      "insertText": {
        "location": {"index": 1, "tabId": "t.0"},
        "text": "New paragraph at the top\n"
      }
    }
  ]
}
```

**Key points:**
- `index: 1` = the very beginning of the document body (index 0 is the body start marker)
- `\n` creates a new paragraph
- Inserting text shifts all indices after the insertion point — if you need multiple inserts, work **backwards** (highest index first) to avoid index shifting

### Insert at the end of a document

Read the document first to find the last index:

```bash
jq '.tabs[0].body.content | last | .endIndex' /tmp/doc.json
```

Then insert at `endIndex - 1` (the position before the final newline).

---

## Deleting content

```json
{
  "requests": [
    {
      "deleteContentRange": {
        "range": {
          "startIndex": 10,
          "endIndex": 50,
          "tabId": "t.0"
        }
      }
    }
  ]
}
```

Deletes everything from index 10 to 50 (exclusive). To delete an entire paragraph, include its trailing `\n` in the range.

---

## Replacing text

### Find-and-replace (across the whole document or tab)

```json
{
  "requests": [
    {
      "replaceAllText": {
        "containsText": {
          "text": "old text",
          "matchCase": true
        },
        "replaceText": "new text",
        "tabsCriteria": {
          "tabIds": ["t.0"]
        }
      }
    }
  ]
}
```

Omit `tabsCriteria` to replace across all tabs. This is the safest way to do simple text replacements — no index math needed.

### Surgical replace (delete range + insert)

For precise replacements where you need to control formatting:

```json
{
  "requests": [
    {"deleteContentRange": {"range": {"startIndex": 10, "endIndex": 50, "tabId": "t.0"}}},
    {"insertText": {"location": {"index": 10, "tabId": "t.0"}, "text": "replacement text"}}
  ]
}
```

**Important:** after `deleteContentRange`, the insertion index is the `startIndex` of the deleted range (content collapsed).

---

## Formatting text

### Bold, italic, font size, color

```json
{
  "requests": [
    {
      "updateTextStyle": {
        "range": {
          "startIndex": 1,
          "endIndex": 20,
          "tabId": "t.0"
        },
        "textStyle": {
          "bold": true,
          "fontSize": {"magnitude": 14, "unit": "PT"}
        },
        "fields": "bold,fontSize"
      }
    }
  ]
}
```

The `fields` mask controls which properties are updated — unmentioned properties are left unchanged. Common fields: `bold`, `italic`, `underline`, `fontSize`, `foregroundColor`, `link`, `fontFamily`.

### Paragraph style (alignment, headings, spacing)

```json
{
  "requests": [
    {
      "updateParagraphStyle": {
        "range": {
          "startIndex": 1,
          "endIndex": 20,
          "tabId": "t.0"
        },
        "paragraphStyle": {
          "namedStyleType": "HEADING_1"
        },
        "fields": "namedStyleType"
      }
    }
  ]
}
```

Named style types: `NORMAL_TEXT`, `HEADING_1` through `HEADING_6`, `TITLE`, `SUBTITLE`.

### Creating bullet lists

```json
{
  "requests": [
    {
      "createParagraphBullets": {
        "range": {
          "startIndex": 10,
          "endIndex": 100,
          "tabId": "t.0"
        },
        "bulletPreset": "BULLET_DISC_CIRCLE_SQUARE"
      }
    }
  ]
}
```

Nesting: same as Slides — use leading `\t` characters in the text before calling `createParagraphBullets`. One tab = one nesting level.

---

## Working with tables

### Insert a table

```json
{
  "requests": [
    {
      "insertTable": {
        "rows": 3,
        "columns": 2,
        "location": {"index": 1, "tabId": "t.0"}
      }
    }
  ]
}
```

After insertion, the table and its cells have indices. Read the document to find cell boundaries, then use `insertText` to populate cells.

### Finding table cell indices

```bash
jq '.tabs[0].body.content[] | select(.table?) | {startIndex, endIndex, rows: (.table.tableRows | length), cols: (.table.columns)}' /tmp/doc.json
```

Each table cell's content is a nested `content[]` array with its own paragraph elements and indices.

---

## Headers, footers, footnotes

### Create a header

```json
{
  "requests": [
    {
      "createHeader": {
        "type": "DEFAULT",
        "sectionBreakLocation": {"index": 0, "tabId": "t.0"}
      }
    }
  ]
}
```

The response returns the new header's `headerId`. Use it with `insertText` targeting `segmentId: "<headerId>"` to populate it.

### Create a footer

Same pattern with `createFooter`.

### Footnotes

```json
{
  "requests": [
    {
      "createFootnote": {
        "location": {"index": 25, "tabId": "t.0"}
      }
    }
  ]
}
```

---

## Useful batchUpdate request types

| Request | Purpose |
|---|---|
| `insertText` | Insert text at a position |
| `deleteContentRange` | Delete a range of content |
| `replaceAllText` | Find-and-replace (optionally scoped to tabs) |
| `updateTextStyle` | Font, size, color, bold, italic, links |
| `updateParagraphStyle` | Alignment, headings, spacing, indentation |
| `createParagraphBullets` / `deleteParagraphBullets` | Toggle bullets on paragraphs |
| `insertTable` / `insertTableRow` / `insertTableColumn` | Table creation and modification |
| `deleteTableRow` / `deleteTableColumn` | Table modification |
| `mergeTableCells` / `unmergeTableCells` | Table cell merging |
| `insertInlineImage` | Insert an image at a position |
| `createNamedRange` / `deleteNamedRange` | Bookmark-like named ranges |
| `createHeader` / `createFooter` / `createFootnote` | Document structure |
| `insertSectionBreak` / `deletePositionedObject` | Section and layout control |
| `updateDocumentStyle` | Page size, margins, background |
| `insertPageBreak` | Force a page break |

Full reference: https://developers.google.com/workspace/docs/api/reference/rest/v1/documents/request

---

## Gotchas

### Index shifting on multiple inserts

When you insert text, all indices after the insertion point shift by the length of the inserted text. If you need to make multiple inserts in one batch:
- **Work backwards** — start with the highest index and work down. Earlier indices won't be affected by later inserts.
- Or: do multiple sequential batchUpdate calls, re-reading indices between each.

### Index 0 vs index 1

Index `0` is the document body start marker. The first usable content position is index `1`. Inserting at index `0` will fail.

### The trailing newline

Every document body ends with a mandatory `\n` that cannot be deleted. The last usable index is `endIndex - 1` of the final structural element.

### `includeTabsContent` is required for multi-tab docs

Without `includeTabsContent: true`, `documents.get` returns the legacy flat `document.body` which only contains the first tab's content. Always pass it.

### `replaceAllText` crosses tab boundaries by default

If you omit `tabsCriteria`, `replaceAllText` replaces across ALL tabs. Scope it with `tabsCriteria.tabIds` if you want to target a specific tab.

### Fields mask is mandatory on update requests

`updateTextStyle` and `updateParagraphStyle` require a `fields` string listing which properties to update. Omitting it or setting it to `"*"` resets ALL properties to defaults — which is almost never what you want. Always list specific fields: `"bold,fontSize"`, `"namedStyleType"`, etc.

### Paragraph boundaries matter for style changes

`updateParagraphStyle` applies to every paragraph that overlaps the range. Even if your range only covers one character of a paragraph, the entire paragraph gets the style change. Be precise with ranges.

### Cannot create or delete tabs

The API can read and edit content within tabs, but cannot create new tabs or delete existing ones. This is a known gap (Google Issue Tracker #375867285).

---

## Minimal end-to-end example — insert text with formatting

```bash
DOC=1abc...

# Read the document
gws-personal docs documents get --params "{\"documentId\":\"$DOC\", \"includeTabsContent\":true}" > /tmp/doc.json

# Find the end of the first tab's content
END=$(jq '.tabs[0].body.content | last | .endIndex' /tmp/doc.json)
INSERT_AT=$((END - 1))

# Insert a new heading + paragraph at the end
gws-personal docs documents batchUpdate \
  --params "{\"documentId\":\"$DOC\"}" \
  --json "{
    \"requests\": [
      {\"insertText\": {\"location\": {\"index\": $INSERT_AT, \"tabId\": \"t.0\"}, \"text\": \"New Section\\nSome body text here.\\n\"}},
      {\"updateParagraphStyle\": {\"range\": {\"startIndex\": $INSERT_AT, \"endIndex\": $((INSERT_AT + 12)), \"tabId\": \"t.0\"}, \"paragraphStyle\": {\"namedStyleType\": \"HEADING_2\"}, \"fields\": \"namedStyleType\"}}
    ]
  }"
```

---

## API reference

- **Request types:** https://developers.google.com/workspace/docs/api/reference/rest/v1/documents/request
- **Concepts:** https://developers.google.com/workspace/docs/api/concepts/structure
- **Tab support:** https://developers.google.com/workspace/docs/api/how-tos/tabs
- **Text styling:** https://developers.google.com/workspace/docs/api/how-tos/format-text
- **Tables:** https://developers.google.com/workspace/docs/api/how-tos/tables
