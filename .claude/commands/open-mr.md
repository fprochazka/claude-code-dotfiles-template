---
description: Open a draft MR for the current branch and refine its title and description
argument-hint: [ticket-id]
allowed-tools: Bash, Read, Edit, Write, Skill, Agent
---

# Open MR

Open a draft merge/pull request for the current branch, then refine the title and description so they accurately describe the actual changes.

$ARGUMENTS

## Process

1. **Load skills** — invoke the `git-workflow` skill for commit/MR shaping judgment. Also load `glab` or `gh` depending on the remote host.
2. **Open the draft MR** — run `git issue-mr <ticket> --draft` (the `<ticket>` arg is optional if the branch already has an issue ID stored; omit it in that case). This pushes the branch, creates the MR/PR as draft, and auto-assigns it to the user. If an MR/PR already exists, the script just prints the URL — that's fine, proceed to step 3.
3. **Inspect what actually changed** — review the diff against the base branch and the commit history. Don't trust the original ticket title/description verbatim; the implementation may have diverged.
4. **Write an accurate title** — short, imperative, specific. Keep the `<ticket-id>:` prefix that `git issue-mr` set. Update the rest to describe what the MR actually does.
5. **Write a description for the reviewer** — the goal is to set the reviewer up with the right optics for reading the diff, not to recap *what* changed (the diff already shows that). Cover, as applicable:
   - **Why** — the motivation / problem being solved, the constraint or decision that shaped the approach. If the ticket already captures this well, a one-line pointer is enough.
   - **Gotchas** — non-obvious tradeoffs, things that look wrong but aren't, assumptions that depend on external state, anything a reviewer might flag as a bug without context.
   - **Where to focus** — call out the 1-3 most complex / load-bearing parts of the diff (with file:line pointers) that deserve the most careful review. Trivial parts (renames, formatting, mechanical refactors) can be explicitly de-prioritized.
   - Keep it tight. No empty sections, no filler, no "already done in branch X" meta-commentary.
6. **Update the MR** — write the new description to `/tmp/<ticket-or-branch>-mr-description.md` and update the MR via `glab mr update` / `gh pr edit` using `--description "$(cat <path>)"`. Update the title the same way if it changed.
7. **Report** — print the MR URL and a one-line summary of what you set.

## Notes

- Keep the MR in **draft** state — do not mark it ready.
- Do not push `--no-verify` or skip hooks if `git issue-mr` fails on a hook; fix the underlying issue.
- If the branch has no upstream-tracked issue and no `<ticket>` arg was passed, ask the user for the ticket ID before running `git issue-mr`.
