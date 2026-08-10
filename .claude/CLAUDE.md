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

## Local verification
Default to a minimal local check: app compiles/typechecks, lint is green, and tests directly relevant to the change pass. Do **not** run the full test suite locally — push and open the MR, let CI do the heavy lifting. Run more locally only if I ask, or if the change is risky enough that CI feedback would be too late.

## Scratchpad & temp files
**Scratchpad** is the session-specific working directory the harness gives you for temporary files — a path like `/tmp/claude-<uid>/<cwd-slug>/<session-id>/scratchpad`, spelled out in your system prompt. It's isolated from the user's project, writable without permission prompts, and scoped to the session. Use it for intermediate results, working scripts, drafts, and tool-call payloads — anything that would otherwise land in `/tmp`. Commands and skills refer to it as "the scratchpad dir" or `<scratchpad>/<name>` and rely on this definition instead of re-explaining it.

- **Fallback.** If the scratchpad path isn't present in your system prompt for some reason, create a random directory under `/tmp` once (e.g. `mktemp -d /tmp/claude-scratch-XXXXXX`) and use that as the session scratchpad for the rest of the session — don't write files loose in `/tmp` directly. Read "scratchpad" as "the harness-provided dir if available, otherwise the `/tmp` dir you created for this session"; everything below still applies to it.
- **Unique names.** Name files with a slug (ticket ID, MR number, doc title) so they don't collide across tasks — never generic names like `desc.md` or `notes.md`.
- **Reuse, don't churn.** If a suitable file already exists on disk (a repo file, an existing plan, a downloaded export), use it in place — do **not** copy it into the scratchpad first. If you already wrote content to a file once, reuse that file across tool calls instead of rewriting it.

## Tool calls
For any tool/CLI argument longer than a few words (descriptions, comments, bodies), pass it via a file with `"$(cat <path>)"` rather than inlining it in the tool call — use an existing file if one already holds the content, otherwise write it to the scratchpad first. This keeps tool calls small, makes edits to the argument cheap (small focused edits instead of regenerating the whole thing), and avoids having the LLM re-generate the full noisy tool call.

* when analyzing output of a command that returns JSON, always prefer `jq` over `python`, as it has smaller surface area to check for security problems

## Project Style
* Check if the project has `.editorconfig` and follow the style.
* Make sure you don't write needless short lines, we all have big screens now, reasonable minimum line length is 210 or more, especially for markdown.

## Communicating with other people
**NEVER PROMISE ANYONE ANYTHING.** In any draft addressed to someone other than me — Slack messages, MR/ticket comments, emails, incident write-ups — do not commit to future work, fixes, timelines, follow-ups, or "we will do X". Only I decide what gets promised, and only I get to make the promise. If I explicitly ask for a commitment in the draft, write exactly the one I asked for and nothing more.

* State findings, facts, and causes. Stop there. A defect being real is not permission to announce that it will be fixed.
* Never write "we will fix", "I'll look into it", "this will be improved", "a ticket is coming", "next release", or any softer paraphrase of the same thing.
* If a fix genuinely belongs in the picture, describe it as an option and hand it to me separately — put it in your reply to me, not in the draft.
* Same rule for implied promises: don't ask the other person to wait for us, don't say something is "already being worked on" unless I told you it is.

## Code comments & docs
- **Why, not what.** Comments and docs explain the reasoning code can't show ("X because W") — not a restatement of what the code does, and never the change ("this was Y, now X", "previously…", "renamed from…", "no longer…", intermediate/transitional state). The diff lives in git; describe only the current state. Historical "was Y, now X" framing belongs only in throwaway plan/analysis files where the diff is itself the subject.
- Legacy *why* is the one valuable kind of history: "warehouses come from the `restaurants` table — legacy naming from the restaurant-delivery era" explains a non-obvious current reality, which is different from change-narration — keep this, drop that.
- A comment that restates the code, narrates how the old behavior was broken, parks a transient caveat where it doesn't belong, or adds self-referential "mirrors the X pattern" filler has zero value — don't write it. Revisit a comment when it stops being true, not when nearby code changes.
- Never put ticket refs (ABC-1234, JIRA/Linear IDs or URLs) in code comments, column/DB comments, migrations, or schema descriptions — they add no value and go stale; that context belongs in the MR/commit message or a plan file.

### Prose style
The rules imported below apply to **written prose artifacts** — docs, READMEs, MR/PR descriptions, commit bodies, error messages, release notes, code comments — **and to your conversational replies to me**. Replies use **STE-flavored** mode, never strict: keep the sentence-length cap, the active voice, the plain verbs and the one-topic paragraphs, but keep enough range to answer naturally. They do **not** apply to code, identifiers, or command syntax. The "write only the requested text, no preamble" instruction in them is scoped to a prose-rewriting request, not to normal answers.

@~/.claude/skills/ste-writing/SKILL.md
