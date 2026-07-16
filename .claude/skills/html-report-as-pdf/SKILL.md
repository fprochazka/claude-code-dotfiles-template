---
name: html-report-as-pdf
description: Render a one-off local HTML report file to PDF using headless Chrome/Chromium. Use when asked to "export/print/convert an HTML report/page/dashboard/artifact to PDF" for a self-contained local .html file that uses modern CSS (flexbox/grid, custom properties, prefers-color-scheme) and JS-rendered content (inline SVG charts). Not for scraping remote URLs or CI pipelines.
trigger-keywords: html to pdf, print to pdf, print-to-pdf, render pdf, html report pdf, pdf report, export pdf, wkhtmltopdf
allowed-tools: Bash(google-chrome:*), Bash(google-chrome-stable:*), Bash(chromium:*), Bash(chromium-browser:*), Bash(command -v:*), Read
---

# HTML report → PDF (headless Chrome)

Render a **single self-contained local HTML file** to PDF with headless Chrome/Chromium. This is the right tool for a report/dashboard/artifact page that uses modern CSS (Grid, flexbox, CSS custom properties, `prefers-color-scheme`) and **JavaScript-rendered inline SVG charts** — Chrome uses the current Blink engine, so all of that renders faithfully. Do **not** reach for `wkhtmltopdf` (archived since 2023, frozen 2012 WebKit, no Grid / no CSS variables / no reliable JS — it will render a modern report as garbage).

## The command

Detect the binary, then print to PDF. `file://` needs an **absolute** path.

```bash
CHROME=$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser)
HTML="$PWD/report.html"

"$CHROME" --headless=new --no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage \
  --no-pdf-header-footer --run-all-compositor-stages-before-draw \
  --virtual-time-budget=10000 --window-size=1280,1024 \
  --print-to-pdf="$PWD/report.pdf" "file://$HTML"
```

Flag notes:
- `--headless=new` — the current unified headless mode (Chrome 112+). Old headless was **removed in Chrome 132**; if you ever truly need it, use the standalone `chrome-headless-shell` binary. In new headless you can usually **drop `--disable-gpu`** — it handles GPU absence via SwiftShader, and forcing it off can degrade rendering.
- `--no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage` — needed in container/sandboxed Linux (running as root, small `/dev/shm`); harmless elsewhere.
- `--window-size=1280,1024` — sets the layout viewport **before** print. Without it the default headless window can trip a page's responsive breakpoints and render a mobile/narrow layout.
- `--no-pdf-header-footer` — removes Chrome's default date/URL header and footer.
- `--print-to-pdf=<abs path>` — output file. The **emulated media is always `print`** for this flag (no way to force `screen` from the CLI — use Playwright's `emulateMedia({media:'screen'})` if a report only has `@media screen` styles), so your `@media print` CSS applies.
- `--virtual-time-budget=10000` + `--run-all-compositor-stages-before-draw` — give synchronous JS (chart drawing) time to run and fully composite before capture. Bump the budget (ms) for heavier pages. **It fast-forwards timers only — it does NOT wait for `fetch()`/network/promises**; for data-fetching pages use Playwright with `waitUntil:'networkidle'` (see bottom).
- There is **no `--paper-size`, `--margin`, or `--print-background` flag** — page geometry and background printing are controlled from **CSS only** (see below). This is the single biggest surprise coming from other tools.

## The #1 gotcha: backgrounds and fills silently disappear

Chrome's `--print-to-pdf` sets `printBackground: false` and there is no CLI flag to change it. Any `background-color`, gradient, tint, or SVG `fill` driven by CSS backgrounds gets **stripped** — you get a ghostly, half-blank report. The fix lives in the HTML: add a `@media print` block that forces color printing.

```css
@media print {
  html, body { background:#fff; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  *          { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  @page { size: A4; margin: 12mm; }          /* geometry is CSS, not a CLI flag */
}
```

`print-color-adjust: exact` tells Blink to honor backgrounds/fills even though "background graphics" is off — it is what actually makes the tints and chart fills appear.

## Print-layout gotchas I have actually hit

Verifying by eye (below) surfaces these every time. Put the fixes in the same `@media print` block:

1. **Half-empty pages with a lone heading.** `break-inside: avoid` on a container **taller than a page** (a big charts card) can't be honored, so the browser bumps the whole card to the next page and **orphans the heading** before it — wasting most of a page. Only avoid breaks on *small* units, and glue headings to what follows:
   ```css
   section, .card { break-inside: auto; }          /* let tall containers flow across pages */
   figure, .panel, .stat, table, .note { break-inside: avoid; }  /* keep small units intact */
   h1, h2, h3, .sec-head { break-after: avoid; }   /* never strand a heading */
   ```
   **Caveat:** Blink *ignores* `break-inside: avoid` on `display:flex` / `display:grid` containers entirely (long-standing Chromium bug). If a flex/grid block must stay together, give it `display:block` in `@media print` (float its children), or insert an explicit `<div style="break-before:page">` before it.
2. **Right edge / columns clipped (e.g. a wide table loses its last column).** A screen scroll container (`overflow-x: auto`) does **not** scroll on paper — it **clips**; anything past the fold is silently lost. Worse, **`overflow: hidden` on `<html>`/`<body>` disables page breaks for the whole document.** Force overflow visible for print:
   ```css
   html, body { overflow: visible !important; }     /* else NO page breaks anywhere */
   .tbl-scroll, [class*="scroll"] { overflow: visible !important; max-height: none; }
   table { min-width: 0; }                          /* let it shrink to page width */
   ```
   For wide tables, also consider `@page { size: A4 landscape; }`, or repeat the header on each page with `thead { display: table-header-group; }`.
3. **Wrong theme on paper.** A dark-mode page prints dark (heavy ink, poor contrast). For a printable document, re-declare the light palette tokens inside `@media print` so paper is always the light variant, regardless of the viewer's/emulated theme.
4. **Interactive-only chrome shows as dead elements.** Hover tooltips, "scroll for more" hints, and `position:fixed` bars — the latter get **stamped on every page** by Chrome. Hide them: `.tooltip, #tt, .fixed-nav { display:none !important; }`. (`position:sticky` doesn't repeat — it freezes wherever it last stuck, so don't rely on it for running headers; use `table-header-group` instead.)
5. **`transform` / `filter` can't be fragmented.** An element with a CSS `transform` or `filter` becomes an isolated context; if it's taller than a page it gets **clipped**, not split, and box-shadows are clipped at the page edge. Keep transformed/filtered/shadowed blocks away from page boundaries (or strip the transform in `@media print`).
6. **Blank charts = the wrong chart tech.** Inline **SVG** (CSS `fill`, `currentColor`, `var()` all resolve) prints reliably. A `<canvas>`/WebGL chart can come out **blank** headless (GPU/SwiftShader + `premultipliedAlpha` quirks); if a library uses canvas, switch it to an SVG/2D fallback for print, or raster crisper with `--force-device-scale-factor=2`.

If you own the HTML, prefer **adding this print stylesheet to the source** over fighting the CLI — it also means the user can just Ctrl/Cmd-P → *Save as PDF* and get the identical result.

## Always verify by LOOKING at the PDF

"183582 bytes written" tells you nothing about whether it looks right. **Read the PDF back and actually look at it** — the `Read` tool renders PDF pages as images via its `pages` parameter (e.g. `pages: "1-8"`). Check specifically:
- backgrounds/tints and chart **fills** are solid (not stripped → gotcha #1),
- no page is mostly blank with a stranded heading (→ gotcha #1 breaks),
- nothing is clipped at the right edge; wide tables show **every** column (→ gotcha #2),
- theme is the intended one, and interactive-only elements are gone.

Fix the print CSS and re-render until those pass.

## Dark variant (optional)

To emit a dark-on-paper PDF, don't fight the print stylesheet — drive the media emulation and skip the light-forcing `@media print` override, or use `--force-dark-mode`. This is unreliable across pages; if a dark PDF matters, control it explicitly in CSS rather than via the flag.

## When NOT to use this

- **Remote URLs, pages that fetch data over the network, or that need a readiness signal** — `--virtual-time-budget` accelerates timers but does **not** wait for fetches/promises. Use Playwright (`page.goto(url,{waitUntil:'networkidle'})` then `page.pdf({printBackground:true, preferCSSPageSize:true})`) which waits properly and takes `printBackground` as an option.
- **Repeatable / CI / language-agnostic generation** — use **Gotenberg** (`docker run --rm -p 3000:3000 gotenberg/gotenberg:8`, then `POST /forms/chromium/convert/html` with `printBackground=true`). Same Blink engine, so output is pixel-identical to this Chrome path — it is orchestration, not rendering, that differs.
- **Never `wkhtmltopdf`** — archived, unmaintained, no modern CSS/JS.
