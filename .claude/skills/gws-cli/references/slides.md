# Google Slides via gws

Everything below uses the `gws-personal` / `gws-work` wrapper scripts. Substitute the one that owns the target deck.

## Command shape

| Command | Purpose |
|---|---|
| `gws-personal slides presentations get --params '{"presentationId":"..."}'` | Fetch full deck JSON (slides, layouts, masters, all page elements) |
| `gws-personal slides presentations batchUpdate --params '{"presentationId":"..."}' --json '{"requests":[...]}'` | Apply any edit — the only write endpoint you need |
| `gws-personal slides presentations create --json '{"title":"..."}'` | Create a new blank deck |
| `gws-personal slides presentations pages getThumbnail --params '{...}'` | Render a single slide as a PNG thumbnail (see "Visual inspection") |

**All edits go through `batchUpdate`.** The `requests` array holds typed request objects (`createSlide`, `insertText`, `updateTextStyle`, etc.), all applied atomically. Failure in any one request rolls back the whole batch.

## Output handling

- `gws` writes a `Using keyring backend: keyring` log line to **stderr**, not stdout. Stdout is clean JSON — pipe straight to `jq` without stripping anything.
- Save responses to files before running `jq` on them if you expect large output: `gws-personal slides presentations get --params '{...}' > /tmp/deck.json`.
- Use `--dry-run` on `batchUpdate` to validate JSON structure locally. Note it does **not** validate API semantics — an invalid `objectId` will pass dry-run and fail at execution.

## Batch size limit

**~100 requests per `batchUpdate` call.** One slide creation with title + body + bullets is ~4 requests, so ~25 slides per batch. For larger builds, chunk into multiple batches and re-validate between them.

---

## Creating a new text-based slide

The canonical "create a slide with a title, body bullets, and speaker notes" flow is **two phases** because `speakerNotesObjectId` is not returned by `createSlide` — you have to `GET` the deck after creation to find it.

### Phase 1 — create slide + body

```json
{
  "requests": [
    {
      "createSlide": {
        "objectId": "my_slide_01",
        "insertionIndex": 3,
        "slideLayoutReference": { "predefinedLayout": "TITLE_AND_BODY" },
        "placeholderIdMappings": [
          {
            "layoutPlaceholder": { "type": "TITLE", "index": 0 },
            "objectId": "my_slide_01_title"
          },
          {
            "layoutPlaceholder": { "type": "BODY", "index": 0 },
            "objectId": "my_slide_01_body"
          }
        ]
      }
    },
    {
      "insertText": {
        "objectId": "my_slide_01_title",
        "insertionIndex": 0,
        "text": "My slide title"
      }
    },
    {
      "insertText": {
        "objectId": "my_slide_01_body",
        "insertionIndex": 0,
        "text": "First bullet\nSecond bullet\nThird bullet"
      }
    },
    {
      "createParagraphBullets": {
        "objectId": "my_slide_01_body",
        "textRange": { "type": "ALL" },
        "bulletPreset": "BULLET_DISC_CIRCLE_SQUARE"
      }
    }
  ]
}
```

Key points:

- `insertionIndex` is **zero-based** and puts the new slide at that position. Existing slides at that index and after shift down by one. Omit to append to the end.
- **Stable `objectId`s are mandatory** if you want to target the new placeholders with `insertText` in the same batch. Without them, the placeholders get auto-generated IDs you can't reference until a subsequent `GET`.
- `placeholderIdMappings` lets you rename the layout's placeholders to your own IDs. Use one mapping per placeholder you want to write to.
- `BULLET_DISC_CIRCLE_SQUARE` is the standard nested-bullet preset (`●` level 0, `○` level 1, `■` level 2). Other presets exist (`BULLET_ARROW_DIAMOND_DISC`, `NUMBERED_DIGIT_ALPHA_ROMAN`, etc.) — see the Slides API reference for the full list.
- Use `\n` in `insertText` for line breaks. Use `\t` for nested bullet levels (one tab per level). The tabs are consumed by `createParagraphBullets` and removed from rendered text.

### Nested bullet lists

Nesting is controlled by **leading `\t` characters** in each paragraph, set BEFORE calling `createParagraphBullets`. Example — two top-level items with nested sub-items:

```json
{
  "requests": [
    {
      "insertText": {
        "objectId": "my_slide_01_body",
        "insertionIndex": 0,
        "text": "Top item one\n\tSub item A\n\tSub item B\nTop item two\n\tSub item C\n\tSub item D"
      }
    },
    {
      "createParagraphBullets": {
        "objectId": "my_slide_01_body",
        "textRange": { "type": "ALL" },
        "bulletPreset": "BULLET_DISC_CIRCLE_SQUARE"
      }
    }
  ]
}
```

Produces: `● Top item one / ○ Sub item A / ○ Sub item B / ● Top item two / ○ Sub item C / ○ Sub item D`

Up to 9 nesting levels (0–8) are supported. Use `\t\t` for level 2, etc.

**Critical gotcha — residual list membership:** If you `deleteText` ALL from a body placeholder that previously had bullets, the shape retains an invisible list object. A subsequent `createParagraphBullets` call on new text will **ignore tab-based nesting** and put everything at level 0 (all `●`). The fix:

```json
{
  "requests": [
    {"deleteText": {"objectId": "SHAPE", "textRange": {"type": "ALL"}}},
    {"insertText": {"objectId": "SHAPE", "insertionIndex": 0, "text": "Parent\n\tChild"}},
    {"deleteParagraphBullets": {"objectId": "SHAPE", "textRange": {"type": "ALL"}}},
    {"createParagraphBullets": {"objectId": "SHAPE", "textRange": {"type": "ALL"}, "bulletPreset": "BULLET_DISC_CIRCLE_SQUARE"}}
  ]
}
```

The `deleteParagraphBullets` call between insert and create clears the residual list membership so `createParagraphBullets` processes the tabs fresh.

### Phase 2 — set speaker notes

After Phase 1 executes, you need the new slide's `speakerNotesObjectId`:

```bash
gws-personal slides presentations get --params '{"presentationId":"..."}' > /tmp/deck.json
jq '.slides[] | select(.objectId=="my_slide_01") | .slideProperties.notesPage.notesProperties.speakerNotesObjectId' /tmp/deck.json
```

Then insert the notes text targeting that object ID:

```json
{
  "requests": [
    {
      "insertText": {
        "objectId": "<speakerNotesObjectId>",
        "insertionIndex": 0,
        "text": "Full speaker notes here.\n\nParagraph two.\n\nParagraph three."
      }
    }
  ]
}
```

For a deck with many new slides: create them all first, then `GET` the deck once, harvest every new slide's `speakerNotesObjectId`, then issue one (or more, chunked) batchUpdate(s) to insert all notes.

---

## Predefined layouts

`slideLayoutReference.predefinedLayout` accepts these (most useful first):

| Layout | Use for |
|---|---|
| `TITLE_AND_BODY` | Standard title + bullet body — the workhorse |
| `TITLE_ONLY` | Big-title slides where the title is the whole message |
| `MAIN_POINT` | Large centered statement with no body |
| `TITLE_AND_TWO_COLUMNS` | Two-column comparisons (theme-dependent — inspect first) |
| `BLANK` | No placeholders; you position everything manually via `createShape` |
| `SECTION_HEADER` | Section-divider slide |
| `SECTION_TITLE_AND_DESCRIPTION` | Section divider with subtitle |
| `CAPTION_ONLY` | Caption for an image-forward slide |

The specific theme (master) controls positioning and fonts within each layout. Inspect an existing slide with `gws-personal slides presentations get` to see what your master/layout looks like before committing to one.

---

## Editing existing slides

### Replace text in a placeholder

Atomic replace = `deleteText` + `insertText` in one batch:

```json
{
  "requests": [
    { "deleteText": { "objectId": "my_slide_01_title", "textRange": { "type": "ALL" } } },
    { "insertText": { "objectId": "my_slide_01_title", "insertionIndex": 0, "text": "New title" } }
  ]
}
```

### Update speaker notes in place

Same pattern — `deleteText` all, then `insertText` — targeted at the `speakerNotesObjectId`.

### Change font size of an existing element

```json
{
  "requests": [
    {
      "updateTextStyle": {
        "objectId": "my_slide_01_title",
        "textRange": { "type": "ALL" },
        "style": { "fontSize": { "magnitude": 24, "unit": "PT" } },
        "fields": "fontSize"
      }
    }
  ]
}
```

### Revert to inherited style

To clear an explicit override and fall back to the theme default, send the same request with an empty `style` object and the `fields` mask pointing at the property to clear:

```json
{
  "updateTextStyle": {
    "objectId": "my_slide_01_title",
    "textRange": { "type": "ALL" },
    "style": {},
    "fields": "fontSize"
  }
}
```

### Change text color

```json
{
  "updateTextStyle": {
    "objectId": "my_shape_id",
    "textRange": { "type": "ALL" },
    "style": {
      "foregroundColor": {
        "opaqueColor": {
          "rgbColor": { "red": 0.4, "green": 0.4, "blue": 0.4 }
        }
      }
    },
    "fields": "foregroundColor"
  }
}
```

RGB values are 0.0–1.0 floats, not 0–255.

### Delete a slide

```json
{ "requests": [ { "deleteObject": { "objectId": "my_slide_01" } } ] }
```

Deleting a slide deletes all its page elements as a side effect. You don't need to delete shapes individually first.

---

## Adding custom text shapes

For things that don't fit placeholders — breadcrumb labels, footers, captions, callouts — create a `TEXT_BOX` shape and position it explicitly.

```json
{
  "requests": [
    {
      "createShape": {
        "objectId": "my_slide_01_label",
        "shapeType": "TEXT_BOX",
        "elementProperties": {
          "pageObjectId": "my_slide_01",
          "size": {
            "width":  { "magnitude": 7000000, "unit": "EMU" },
            "height": { "magnitude": 250000,  "unit": "EMU" }
          },
          "transform": {
            "scaleX": 1, "scaleY": 1,
            "translateX": 457200, "translateY": 180000,
            "unit": "EMU"
          }
        }
      }
    },
    { "insertText": { "objectId": "my_slide_01_label", "text": "§ 1 · Section breadcrumb" } },
    {
      "updateTextStyle": {
        "objectId": "my_slide_01_label",
        "textRange": { "type": "ALL" },
        "style": {
          "fontSize": { "magnitude": 12, "unit": "PT" },
          "foregroundColor": { "opaqueColor": { "rgbColor": { "red": 0.4, "green": 0.4, "blue": 0.4 } } }
        },
        "fields": "fontSize,foregroundColor"
      }
    }
  ]
}
```

### Coordinate system — EMU

Google Slides uses **English Metric Units**. Conversions:

| Unit | EMU |
|---|---|
| 1 inch | 914400 |
| 1 pt | 12700 |
| 1 cm | 360000 |

Standard 16:9 slide dimensions:

- **Width:** 9144000 EMU (10 in)
- **Height:** 5143500 EMU (5.625 in)

Default title position in the "Simple Light" master: approximately `translateX=457200, translateY=445025`. Inspect your deck's layout with `gws-personal slides presentations get` to see exact coordinates for your theme.

### transform vs size

- `size` sets the shape's internal box dimensions
- `transform` sets where that box is placed on the page (`translateX`, `translateY`) and any scaling/rotation
- Always include `scaleX: 1, scaleY: 1` in `transform` — omitting them causes weird sizing

---

## Custom slide layouts with manual text boxes

When predefined layouts don't fit — two-column comparisons, punchline + body combos, side-by-side diagrams — use `TITLE_ONLY` or `BLANK` layout and position text boxes manually.

### Why not just use TITLE_AND_TWO_COLUMNS?

- The predefined two-column layout's column widths, gaps, and font sizes are theme-controlled — you can't adjust them
- The columns have mandatory padding/gaps between them that waste space
- You can't add a separate punchline text block below the columns
- You can't change the layout of an existing slide — you have to delete and recreate

### The pattern: TITLE_ONLY + manual TEXT_BOXes

Use `TITLE_ONLY` to get a theme-styled title placeholder (inherits font, size, position from the master). Then add your own text boxes for the body content.

**To rebuild a slide with a custom layout:**

1. Save the current slide's speaker notes text and position
2. `deleteObject` the current slide
3. `createSlide` with `TITLE_ONLY` at the same insertionIndex
4. `insertText` in the title placeholder
5. `createShape` (TEXT_BOX) for each content block — position with `transform`
6. Populate text, apply bullets/styling
7. Recreate breadcrumb label if you have one
8. `GET` the deck, find the new slide's `speakerNotesObjectId`, insert notes

### Worked example: two-column comparison + punchline

A slide with two lists side by side (no gap between them — bullet margins provide separation) and a centered punchline below.

**Slide dimensions:** 9144000 × 5143500 EMU (standard 16:9)
**Title area:** Y = 0 to ~1000000 (handled by TITLE_ONLY placeholder)

```json
{
  "requests": [
    {
      "createSlide": {
        "objectId": "my_comparison",
        "insertionIndex": 5,
        "slideLayoutReference": {"predefinedLayout": "TITLE_ONLY"},
        "placeholderIdMappings": [
          {"layoutPlaceholder": {"type": "TITLE", "index": 0}, "objectId": "my_comparison_title"}
        ]
      }
    },
    {"insertText": {"objectId": "my_comparison_title", "insertionIndex": 0, "text": "Slide title"}},

    {
      "createShape": {
        "objectId": "my_comparison_left",
        "shapeType": "TEXT_BOX",
        "elementProperties": {
          "pageObjectId": "my_comparison",
          "size":      {"width": {"magnitude": 4114800, "unit": "EMU"}, "height": {"magnitude": 3000000, "unit": "EMU"}},
          "transform": {"scaleX": 1, "scaleY": 1, "translateX": 457200, "translateY": 1100000, "unit": "EMU"}
        }
      }
    },
    {
      "createShape": {
        "objectId": "my_comparison_right",
        "shapeType": "TEXT_BOX",
        "elementProperties": {
          "pageObjectId": "my_comparison",
          "size":      {"width": {"magnitude": 4114800, "unit": "EMU"}, "height": {"magnitude": 3000000, "unit": "EMU"}},
          "transform": {"scaleX": 1, "scaleY": 1, "translateX": 4572000, "translateY": 1100000, "unit": "EMU"}
        }
      }
    },
    {
      "createShape": {
        "objectId": "my_comparison_punchline",
        "shapeType": "TEXT_BOX",
        "elementProperties": {
          "pageObjectId": "my_comparison",
          "size":      {"width": {"magnitude": 8229600, "unit": "EMU"}, "height": {"magnitude": 600000, "unit": "EMU"}},
          "transform": {"scaleX": 1, "scaleY": 1, "translateX": 457200, "translateY": 4300000, "unit": "EMU"}
        }
      }
    }
  ]
}
```

**Column layout math:**
- Left X = 457200 (0.5 in margin)
- Left width = 4114800 (~4.5 in)
- Right X = 4572000 (immediately after left — packed, no gap)
- Right width = 4114800
- Total = 457200 + 4114800 + 4114800 = 9143800 ≈ slide width minus right margin
- Both Y = 1100000 (just below title)

Then populate each column with heading + flat bullets:

```json
{
  "requests": [
    {"insertText": {"objectId": "my_comparison_left", "insertionIndex": 0, "text": "Column A heading\nBullet one\nBullet two\nBullet three"}},
    {"createParagraphBullets": {"objectId": "my_comparison_left", "textRange": {"type": "ALL"}, "bulletPreset": "BULLET_DISC_CIRCLE_SQUARE"}},
    {"deleteParagraphBullets": {"objectId": "my_comparison_left", "textRange": {"type": "FIXED_RANGE", "startIndex": 0, "endIndex": 16}}},
    {
      "updateTextStyle": {
        "objectId": "my_comparison_left",
        "textRange": {"type": "FIXED_RANGE", "startIndex": 0, "endIndex": 16},
        "style": {"bold": true, "fontSize": {"magnitude": 18, "unit": "PT"}},
        "fields": "bold,fontSize"
      }
    }
  ]
}
```

This gives a bold 18pt heading (no bullet glyph) followed by regular-sized bulleted items.

**Punchline styling:**

```json
{
  "requests": [
    {"insertText": {"objectId": "my_comparison_punchline", "insertionIndex": 0, "text": "The punchline goes here."}},
    {
      "updateParagraphStyle": {
        "objectId": "my_comparison_punchline",
        "textRange": {"type": "ALL"},
        "style": {"alignment": "CENTER"},
        "fields": "alignment"
      }
    },
    {
      "updateTextStyle": {
        "objectId": "my_comparison_punchline",
        "textRange": {"type": "ALL"},
        "style": {"bold": true, "fontSize": {"magnitude": 24, "unit": "PT"}},
        "fields": "bold,fontSize"
      }
    },
    {
      "updateShapeProperties": {
        "objectId": "my_comparison_punchline",
        "shapeProperties": {"contentAlignment": "MIDDLE"},
        "fields": "contentAlignment"
      }
    }
  ]
}
```

### Repositioning / resizing shapes after creation

If the layout doesn't look right in the thumbnail, adjust with `updatePageElementTransform`:

```json
{
  "updatePageElementTransform": {
    "objectId": "my_comparison_left",
    "applyMode": "ABSOLUTE",
    "transform": {
      "scaleX": 1, "scaleY": 1,
      "translateX": 300000, "translateY": 1200000,
      "unit": "EMU"
    }
  }
}
```

Use `applyMode: "ABSOLUTE"` to replace the entire transform (safest for repositioning). To resize after creation, adjust `scaleX`/`scaleY` (rendered size = declared size × scale).

### Deleting unwanted placeholder content

If using `TITLE_ONLY` but you don't want the default subtitle/date placeholders that some themes include, `deleteObject` them by objectId after creating the slide. Check what the layout actually provides by inspecting `.layouts[]` in the deck JSON.

### When to use BLANK vs TITLE_ONLY

- **TITLE_ONLY** — when you want the slide to inherit the theme's title font/size/position. Your custom text boxes go below the title. Most common choice.
- **BLANK** — when you want full control over everything, including the title. You create ALL text boxes yourself. Use this for diagram-heavy slides or unusual layouts where even the title position needs to change.

---

## Visual inspection via thumbnails

The fastest way to *see* a slide rendered:

```bash
gws-personal slides presentations pages getThumbnail --params '{
  "presentationId": "<id>",
  "pageObjectId":   "<slide_objectId>",
  "thumbnailProperties.mimeType":      "PNG",
  "thumbnailProperties.thumbnailSize": "LARGE"
}'
```

This returns a JSON response with a `contentUrl` — a short-lived signed Google URL. `curl` it to a local file:

```bash
gws-personal slides presentations pages getThumbnail --params '...' \
  | jq -r '.contentUrl' \
  | xargs curl -s -o /tmp/slide.png
```

Then read the PNG with the Read tool (Claude supports inline PNG rendering).

Thumbnail sizes: `SMALL`, `MEDIUM`, `LARGE`. Use `LARGE` for readable text.

---

## Useful batchUpdate request types

| Request | Purpose |
|---|---|
| `createSlide` | Create a new slide at a given position |
| `deleteObject` | Delete a slide or any element by ID |
| `duplicateObject` | Clone a slide or element within the same deck |
| `updateSlidesPosition` | Move existing slide(s) to a new index |
| `insertText` / `deleteText` | Text editing |
| `createParagraphBullets` / `deleteParagraphBullets` | Toggle bullets on paragraphs |
| `updateTextStyle` | Font, size, color, bold, italic |
| `updateParagraphStyle` | Alignment, line spacing, indentation |
| `createShape` | Custom text box, rectangle, ellipse, line, etc. |
| `updateShapeProperties` | Background fill, outline, shadow |
| `updatePageElementTransform` | Resize or move an existing element |
| `replaceAllText` | Find-and-replace across the whole deck |
| `createImage` / `updateImageProperties` | Image handling |

Full reference: https://developers.google.com/workspace/slides/api/reference/rest/v1/presentations/request

---

## Gotchas

### Residual list membership breaks nested bullets

When you `deleteText` ALL from a body placeholder that previously had bullets, the shape retains an invisible list object. A subsequent `createParagraphBullets` on new text **ignores tab nesting** and puts everything at level 0. Fix: call `deleteParagraphBullets` (ALL) between `insertText` and `createParagraphBullets` to clear the residual list. See the "Nested bullet lists" section above for the full pattern.

### `TEXT_AUTOFIT` is not supported on placeholder shapes

Applying `updateShapeProperties` with `autofit.autofitType: "TEXT_AUTOFIT"` to a title or body placeholder fails with *"Autofit types other than NONE are not supported."* There is no way to make placeholder text auto-shrink via the API.

**Workarounds when title text overflows:**

1. **Shorten the title text** — cleanest, and keeps the deck visually consistent.
2. **Explicit `updateTextStyle` fontSize** — set the title to a smaller size (e.g., 24pt instead of the theme default). This works but makes the slide look visually different from its neighbors.
3. **Resize the title shape** via `updatePageElementTransform` — makes the title box taller so wrapped text doesn't overlap the body. Also makes the slide visually inconsistent with neighbors.

Prefer option 1 unless the title absolutely cannot be shortened.

### `speakerNotesObjectId` is not in the `createSlide` response

`createSlide` returns only the new slide's `objectId`. To set speaker notes, you must `GET` the deck after creation and read `slideProperties.notesPage.notesProperties.speakerNotesObjectId` from the slide JSON. This forces a two-phase flow for any build that creates new slides with notes.

### The auto-generated slide objectId pattern

When `createSlide` is called without an explicit `objectId`, Google assigns one like `SLIDES_API<timestamp>_<index>`. You can predict the notes shape ID as `<slide_id>_offset` but don't rely on the offset being consistent — always `GET` to confirm.

### `insertionIndex` semantics

`insertionIndex` on `createSlide` is the position where the new slide will land **after** insertion. So to insert a slide at the top of a 5-slide deck, use `insertionIndex: 0` — the result is a 6-slide deck with the new slide first. To append, omit the field or use the current slide count.

### Placeholder types have an `index`

`placeholderIdMappings.layoutPlaceholder.index` is usually `0` for the first (and typically only) placeholder of a given type on a layout. Layouts with multiple body placeholders (e.g., `TITLE_AND_TWO_COLUMNS`) use `index: 0` and `index: 1` for the two body columns.

### `--dry-run` only validates local JSON

It catches structural JSON errors (missing required fields, wrong types) but not API-level issues: invalid `objectId`, index out of range, missing placeholder type on the chosen layout, etc. Always run the actual batch after a successful dry-run and verify the response.

### Two-column / multi-column layouts

The `TITLE_AND_TWO_COLUMNS` predefined layout works but its availability and rendering depend on the deck's master/theme. If your theme doesn't ship that layout, the API falls back silently to a single-column layout. Inspect the deck's `layouts[]` in a `GET` response to confirm availability before committing to it.

### There is no cross-presentation copy in the REST API

`duplicateObject` only works within a single deck. To copy a slide from one deck to another, you have to read its full object graph and reconstruct it via `batchUpdate` in the target. For complex slides this is tedious; Apps Script's `SlidesApp.copyTo()` is the only clean alternative.

---

## Minimal end-to-end example — insert one titled slide

```bash
DECK=1abcDEF...

# Phase 1: create slide
gws-personal slides presentations batchUpdate \
  --params "{\"presentationId\":\"$DECK\"}" \
  --json '{
    "requests": [
      {
        "createSlide": {
          "objectId": "demo_01",
          "insertionIndex": 0,
          "slideLayoutReference": { "predefinedLayout": "TITLE_AND_BODY" },
          "placeholderIdMappings": [
            { "layoutPlaceholder": { "type": "TITLE", "index": 0 }, "objectId": "demo_01_title" },
            { "layoutPlaceholder": { "type": "BODY",  "index": 0 }, "objectId": "demo_01_body"  }
          ]
        }
      },
      { "insertText": { "objectId": "demo_01_title", "text": "Demo" } },
      { "insertText": { "objectId": "demo_01_body",  "text": "One\nTwo\nThree" } },
      {
        "createParagraphBullets": {
          "objectId": "demo_01_body",
          "textRange": { "type": "ALL" },
          "bulletPreset": "BULLET_DISC_CIRCLE_SQUARE"
        }
      }
    ]
  }'

# Phase 2: harvest speaker notes ID, then insert notes
gws-personal slides presentations get --params "{\"presentationId\":\"$DECK\"}" > /tmp/deck.json
NOTES_ID=$(jq -r '.slides[] | select(.objectId=="demo_01") | .slideProperties.notesPage.notesProperties.speakerNotesObjectId' /tmp/deck.json)

gws-personal slides presentations batchUpdate \
  --params "{\"presentationId\":\"$DECK\"}" \
  --json "{
    \"requests\": [
      { \"insertText\": { \"objectId\": \"$NOTES_ID\", \"insertionIndex\": 0, \"text\": \"These are the speaker notes for the demo slide.\" } }
    ]
  }"

# Verify visually
gws-personal slides presentations pages getThumbnail --params "{
  \"presentationId\": \"$DECK\",
  \"pageObjectId\": \"demo_01\",
  \"thumbnailProperties.mimeType\": \"PNG\",
  \"thumbnailProperties.thumbnailSize\": \"LARGE\"
}" | jq -r '.contentUrl' | xargs curl -s -o /tmp/demo.png
```

---

## API reference

For request types not covered here, consult the official Slides REST API reference:

- **Request types:** https://developers.google.com/workspace/slides/api/reference/rest/v1/presentations/request
- **Samples:** https://developers.google.com/workspace/slides/api/samples
- **Speaker notes guide:** https://developers.google.com/workspace/slides/api/guides/notes
- **Styling guide:** https://developers.google.com/workspace/slides/api/guides/styling
