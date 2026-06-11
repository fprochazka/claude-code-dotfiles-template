---
description: Write a handover doc capturing WHAT + WHY of this session so a future session can resume cleanly
argument-hint: [optional topic slug override]
allowed-tools: AskUserQuestion, Read, Bash, Write
---

# Handover Generate

Capture the current session into a single handover document so a future session can resume with full WHY-context, without you (the future agent) having to re-derive intent from scratch.

This is **lossy by design**. Anything reconstructable from code, tickets, or git is anchored — not copied. Capture the WHAT and the WHY. The HOW lives in the code.

## Phase 1 — Scope check

Look at the conversation. If it's empty or unclear what's being handed over, ask the user before proceeding.

If the session spans multiple unrelated threads: **do not split**. One document, one session. Group decisions per thread inside the doc.

## Phase 2 — Anchor gathering

Run these directly (no subagent):

- `pwd` — to resolve output path
- `git rev-parse --abbrev-ref HEAD` — current branch
- `git status --short` — uncommitted state
- `git log -10 --oneline` — recent commits

Detect any ticket refs mentioned in the conversation (Linear `ABC-1234`, GitHub `#789`, GitLab MRs, URLs). Capture **refs only**, not content.

## Phase 3 — Resolve output path

1. **Company detection** from `pwd`:
   - If under `~/devel/projects/<company>/...` → company = that segment.
   - Else → personal.
2. **Slug**:
   - Prefer `$ARGUMENTS` if given.
   - Else ticket ID if exactly one is in play (lowercase, e.g. `proj-1234`).
   - Else short kebab-case topic derived from what the session was about (e.g. `handover-command-design`).
3. **Final path**:
   - Personal: `~/devel/tmp/handover-<slug>.md`
   - Company: `~/devel/projects/<company>/tmp/handover-<slug>.md`
4. Ensure parent dir exists (`mkdir -p`).
5. If a file at that path already exists, append `-2` (then `-3`, etc.) — never overwrite silently.

## Phase 4 — Write the doc

Write directly with the Write tool. You (the orchestrator) have the conversation in context; a subagent does not.

Use this exact structure. Omit sections that genuinely have nothing to say. Do **not** add sections not listed here.

```markdown
# Handover: <topic>

## TL;DR
2-3 sentences. What we were working on, where we stopped.

## Ticket / source of truth
- <ticket-ref-or-URL>  ← next session will fetch this fresh; do NOT duplicate its content here
- **Point of the task:** 1-2 sentences in our own words — the "why now" that's
  often missing from the ticket itself.

(If there's no ticket, replace with a short "Origin" note: where the work came from — Slack thread, ad-hoc request, follow-up to MR !123, etc. Anchor, don't quote.)

## Decisions made this session
For each decision:
- **Decision:** <final position>
- **Why:** <the reasoning we landed on>
- **Considered & rejected:** <alternative + what triggered the pivot> (only if there was a real pivot)

Quote the user's framing **verbatim** where it carries a constraint
("user said: '...'"). Paraphrase everything else, but never paraphrase user intent.

## Open questions
Unresolved things the next session must decide with the user before implementing.
Each as a concrete question, not a vague topic.

## Code anchors
Branches, classes, modules, files. **Paths only — no line numbers, no snippets, no code.**
Grouped by subdomain.
- `branch: <name>` — current working branch, N uncommitted changes (from `git status`)
- `<path/to/Thing>` — one-line role in the change
- `<path/to/OtherThing>` — one-line role

## Out of scope
Things we explicitly decided NOT to do this session, and why. Prevents the next
session from re-litigating settled questions.

## Handover instructions for the next session
Literal text for future-Claude. Tell them: read the ticket fresh, read the code
fresh, this handover gives WHY and anchors, everything else re-derive.
Do not start implementing without discussing first.
```

## Phase 5 — Output

Print **only** the absolute path of the file written. No summary, no recap, no "I wrote X sections". The user will open the file and decide if it needs adjustments.

## Hard rules

- **No HOW.** No code snippets. No diffs. No function bodies. No step-by-step plans. If you catch yourself writing one, replace it with a path anchor.
- **No regurgitation.** Don't copy ticket descriptions, file contents, or prior agent outputs. Anchor them.
- **Quote user decisions verbatim.** Paraphrase drift across handovers is the #1 failure mode — guard against it.
- **Final state only**, but if a decision pivoted, capture the rejected alternative + the trigger — that pivot is itself WHY-context.
- **One file.** Even for multi-thread sessions.
- **Always write the file.** Don't ask for confirmation, don't preview, don't summarize the contents back to the user.
- **Write outside the repo.** Handovers cross sessions and must not pollute repo state.
- Do NOT enter plan mode. Do NOT suggest next steps in the chat. Do NOT start implementing anything.
