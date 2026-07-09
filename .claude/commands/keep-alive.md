---
description: Keep this session warm with a periodic no-op cron ping until dismissed
disable-model-invocation: true
---

# Keep Session Alive

Set up a cron that keeps this session warm so it's ready for follow-up tasks later, without wasting tokens in the meantime.

## Instructions

1. Create a cron (via `CronCreate`) that fires **every 30 minutes** and prompts this session with a single word: `ping`.
2. When that cron fires, do **nothing** else — no tool calls, no exploration, no work. Just reply with `pong` and end the turn immediately.
3. Tell the user the cron is set up, note its schedule and how to stop it (`/keep-alive stop`, or delete the cron), then end the turn.

## Rules

- **The whole point is to burn as few tokens as possible.** A `ping` firing means exactly one word back: `pong`. Never interpret `ping` as a request to check on anything, resume prior work, or take initiative.
- Keep the session warm until the user explicitly asks for real work. Their next real request is the signal to stop treating firings as no-ops.
- If invoked with `stop` (i.e. `/keep-alive stop`), delete the keep-alive cron via `CronDelete` (list with `CronList` if you need the id) and confirm it's gone.

$ARGUMENTS
