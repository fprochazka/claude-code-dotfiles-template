## The User
<!-- Replace with your own identity. Example (Filip's): -->
<!-- - **User**: Filip Procházka (personal email `mr@fprochazka.cz`) -->
- **User**: YOUR_NAME (email `YOUR_EMAIL`)

## CLI Tools
* The `glab` cli has access to Gitlab API under the logged in user, use its `--help` to explore available commands instead of guessing.
* The `gh` cli has access to Github API under the logged in user, use its `--help` to explore available commands instead of guessing.

## Skills
**ALWAYS load relevant skills BEFORE attempting unfamiliar CLI commands.** Do not guess syntax or trial-and-error your way through - load the skill first to learn correct usage.

Skill mapping:
- Datadog queries → `pup` CLI and `dd-pup` / `dd-logs` / `dd-apm` skills

## General workflow
Be eager with exploring, gathering information and proposing solutions, but be restrained with jumping to implementing.
Unless the user intent is absolutely clear, then even when making small changes that don't require full plan mode, outline your plan in 3-5 bullet points: what files you'll touch, what approach you'll take, and what you'll verify. Wait for my OK before proceeding.

## Correctness
Never dismiss build errors as 'pre-existing' - we will not be merging branches with a broken build - master/main is always green!

## Code comments & docs
- **Why, not what.** Comments and docs explain the reasoning code can't show ("X because W") — not a restatement of what the code does, and never the change ("this was Y, now X", "previously…", "renamed from…", "no longer…", intermediate/transitional state). The diff lives in git; describe only the current state. Historical "was Y, now X" framing belongs only in throwaway plan/analysis files where the diff is itself the subject.
- Legacy *why* is the one valuable kind of history: "warehouses come from the `restaurants` table — legacy naming from the restaurant-delivery era" explains a non-obvious current reality, which is different from change-narration — keep this, drop that.
- A comment that restates the code, narrates how the old behavior was broken, parks a transient caveat where it doesn't belong, or adds self-referential "mirrors the X pattern" filler has zero value — don't write it. Revisit a comment when it stops being true, not when nearby code changes.
- Never put ticket refs (ABC-1234, JIRA/Linear IDs or URLs) in code comments, column/DB comments, migrations, or schema descriptions — they add no value and go stale; that context belongs in the MR/commit message or a plan file.

## Local verification
Default to a minimal local check: app compiles/typechecks, lint is green, and tests directly relevant to the change pass. Do **not** run the full test suite locally — push and open the MR, let CI do the heavy lifting. Run more locally only if I ask, or if the change is risky enough that CI feedback would be too late.

## Scratchpad & temp files
**Scratchpad** is the session-specific working directory the harness gives you for temporary files — a path like `/tmp/claude-<uid>/<cwd-slug>/<session-id>/scratchpad`, spelled out in your system prompt. It's isolated from the user's project, writable without permission prompts, and scoped to the session. Use it for intermediate results, working scripts, drafts, and tool-call payloads — anything that would otherwise land in `/tmp`. Commands and skills refer to it as "the scratchpad dir" or `<scratchpad>/<name>` and rely on this definition instead of re-explaining it.

- **Fallback.** If the scratchpad path isn't present in your system prompt for some reason, create a random directory under `/tmp` once (e.g. `mktemp -d /tmp/claude-scratch-XXXXXX`) and use that as the session scratchpad for the rest of the session — don't write files loose in `/tmp` directly. Read "scratchpad" as "the harness-provided dir if available, otherwise the `/tmp` dir you created for this session"; everything below still applies to it.
- **Unique names.** Name files with a slug (ticket ID, MR number, doc title) so they don't collide across tasks — never generic names like `desc.md` or `notes.md`.
- **Reuse, don't churn.** If a suitable file already exists on disk (a repo file, an existing plan, a downloaded export), use it in place — do **not** copy it into the scratchpad first. If you already wrote content to a file once, reuse that file across tool calls instead of rewriting it.

## Tool calls
For any tool/CLI argument longer than a few words (descriptions, comments, bodies), pass it via a file with `"$(cat <path>)"` rather than inlining it in the tool call — use an existing file if one already holds the content, otherwise write it to the scratchpad first. This keeps tool calls small, makes edits to the argument cheap (small focused edits instead of regenerating the whole thing), and avoids having the LLM re-generate the full noisy tool call.

## Style
* Check if the project has `.editorconfig` and follow the style.
* Make sure you don't write needless short lines, we all have big screens now, reasonable minimum line length is 210 or more, especially for markdown.

## Other
* when analyzing output of a command that returns JSON, always prefer `jq` over `python`, as it has smaller surface area to check for security problems

## Scheduling
* You've almost always failed to create a working "monitor", that would fire when it should, and worse, sometimes subagents set it up and then return which ends them and clears the monitor - don't repeat these mistakes anymore, don't use monitors at all. Instead, when waiting for something quick setup a few-minutes-rate cron to check if it's done - its not as elegant but it works reliably.
