# Filip's Claude Code setup — a template

This repo is a de-branded template built from the **non-installable parts** of `@fprochazka`'s
Claude Code setup: the harness config, hooks, scripts, custom commands, multi-account profiles, and a
couple of tool configs. Every company-specific skill and identity has been scrubbed to generic
placeholders so you can fork it and make it yours. The installable parts (plugins, CLIs) are **not**
copied here — they're listed with install instructions so you can pull them from source.

The directory tree mirrors your **home directory**, so every file is shown where it actually belongs:

```
.claude/                     → ~/.claude/
  settings.json              the harness config (hooks, permissions, plugins, model, …)
  CLAUDE.md                  global memory / rules (identity placeholdered)
  orchestrator-role.md       SessionStart-injected "main agent is a pure orchestrator" role
  icq-uh-oh.mp3              sound played by the Stop hook when a turn finishes
  scripts/                   status line, orchestrator-role injector, plugin install/update
  commands/                  custom slash commands (/pre-plan, /handover-generate, …)
  skills/                    bundled skills (see note — prune the ones you don't want)
.claude-profiles/            → ~/.claude-profiles/
  config.yaml                multi-account profile definitions
.local/bin/                  → ~/.local/bin/
  claude-personal            auth-switch wrapper (auto-generated; reference only)
  claude-work-team
  claude-work-vertex
  gws-personal               gws wrappers — each pins GOOGLE_WORKSPACE_CLI_CONFIG_DIR to one account
  gws-work
.config/                     → ~/.config/    (per-tool CLI configs; secrets placeholdered)
  linear-mcp/                slackcli/            metabasecli/
  outline-cli/               searxngcli/
.rabbitmqadmin.conf          → ~/.rabbitmqadmin.conf    (RabbitMQ nodes; passwords placeholdered)
```

> **How to use this:** hand the repo to Claude Code and tell it which parts you want. See
> [**For Claude: how to adopt this**](#for-claude-how-to-adopt-this) at the bottom — it's written
> as instructions an agent can follow to merge any subset into your own `~`.

---

## The mental model behind all of it

- The agent is a **junior engineer with infinite stamina and no taste**. Your job is **context
  curation + feedback loops**, not coding.
- **Add useful context, keep useless noise out of the window.** Most of this setup exists to do
  one of those two things.
- **CLI + SKILL >> MCP.** MCPs sit in context and bloat it; a CLI costs nothing but the agent can't
  see it; a *skill* teaches the agent to use the CLI and is lazy-loaded; a skill with
  `trigger-keywords` gets reliably loaded. So most integrations here are CLIs wrapped in skills.
- **Watch it work, like a psychopath.** Single agent, no fire-and-forget parallelism, steer mid-run.
  Every mistake → a new line in `CLAUDE.md` or `.claude/rules/`.
- **Build the boring plumbing before chasing the shiny.**

---

## Prerequisites (external tools — install these first)

Not all are required; install what the parts you adopt actually use.

- **Claude Code** itself.
- **jq** — used by the hooks and scripts. Required for the orchestrator hook + status line.
- **rtk** (Rust Token Killer) — https://github.com/rtk-ai/rtk — the `PreToolUse` Bash hook
  (`rtk hook claude`) rewrites noisy commands to cut tokens 60–90%. If you don't install it, the
  hook fails open (no harm), but remove the hook from `settings.json` to avoid the overhead.
- **uv** — most of my CLIs install via `uv tool install`.
- **bash-classify** — https://github.com/fprochazka/bash-classify — the **CLI** is required by the
  `noisy-tools-in-subagent` plugin (it parses commands to detect noisy build/test tools); install it
  per the repo's instructions. (Note: I do **not** ship the `bash-classify-hook` permission plugin
  here — Claude's auto mode covers that now.)
- **mpg123** (optional) — the `Stop` hook plays a sound when a turn finishes. Drop the hook if you
  don't want it.
- **claude-code-auth-switch** — https://github.com/fprochazka/claude-code-auth-switch — only if you
  want the multi-account profiles (`.claude-profiles/` + `.local/bin/claude-*`).
- **pup** (Datadog CLI) — https://github.com/DataDog/pup — for telemetry (logs/metrics/traces/
  monitors/incidents). Ships its own Claude Code skills — **install them from pup itself**, don't
  copy them here (see [Datadog telemetry](#datadog-telemetry--pup--its-skills) below).
- **glab** (GitLab CLI) — https://gitlab.com/gitlab-org/cli/#installation — the upstream CLI that
  backs the `glab`, `glab-mr`, `glab-discussion`, and `glab-pipeline` plugins; install per its
  instructions. Point it at your instance via `GITLAB_HOST` (the work profiles set
  `gitlab.example.com` as an example).
- Per-tool CLIs (only if you adopt their config/skill): `rabbitmqadmin`, `gh`, `gcloud`, etc.

---

## Plugins (installable — not duplicated here)

I do **not** re-explain the plugins in this repo. They're installed from marketplaces. The full,
authoritative list + a reproducible installer is in:

- **`.claude/scripts/claude-plugins-install-all.sh`** — adds every marketplace and installs every
  plugin in one go (idempotent). Run it on a fresh machine.
- **`.claude/scripts/claude-plugin-update-all.sh`** — updates all marketplaces + installed plugins.
- **`.claude/settings.json`** → `enabledPlugins` + `extraKnownMarketplaces` — the declarative source
  of truth for what's enabled and where it comes from.

Most are mine (`github.com/fprochazka/*`); a few are third-party (Vercel `agent-browser`, Anthropic
`plugin-dev`, Warp notifications). Each plugin documents itself once installed (`/help`, its skill,
or its repo README) — that's why they're not re-described here.

### The installed plugins

- **[noisy-tools-in-subagent](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/noisy-tools-in-subagent)** — forces builds/tests/linters into an isolated subagent so their noisy output never pollutes the main context.
- **[searxngcli](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/searxngcli)** — web research via a self-hosted SearXNG metasearch engine, run in a subagent.
- **[skill-keyword-reminder](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/skill-keyword-reminder)** — scans each prompt and nudges Claude to load the matching skill, so lazy-loaded skills actually load.
- **[rabbitmqadmin](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/rabbitmqadmin)** — read-only inspection of RabbitMQ vhosts/queues/exchanges/bindings.
- **[migrate-to-uv](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/migrate-to-uv)** — converts Python projects from Poetry/pipx/pip to uv.
- **[metabasecli](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/metabasecli)** — query Metabase cards, dashboards, and collections from the terminal.
- **[glab](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/glab)** — teaches Claude correct use of the GitLab `glab` CLI.
- **[glab-mr](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/glab-mr)** — slash commands that fetch full MR state and fix failing CI / unresolved comments.
- **[git](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/git)** — judgment rules for shaping atomic commits, branches, and review responses (not git mechanics).
- **[code-review](https://github.com/fprochazka/claude-code-plugins/tree/master/plugins/code-review)** — orchestrates parallel focused review subagents over the current branch and compiles a report.
- **[glab-discussion](https://github.com/fprochazka/glab-discussion)** — file-per-thread CLI for reading/writing GitLab MR discussion threads (which raw `glab` handles poorly).
- **[glab-pipeline](https://github.com/fprochazka/glab-pipeline)** — deep CI pipeline inspector that dumps full state + a problem-focused summary for agents.
- **[slackcli](https://github.com/fprochazka/slackcli)** — read/search/send Slack as your own user (xoxp) and resolve Slack links.
- **[agent-browser](https://github.com/vercel-labs/agent-browser)** *(Vercel)* — drives a real Chrome via CDP for browsing, testing, and automation.
- **[plugin-dev](https://github.com/anthropics/claude-code)** *(Anthropic)* — toolkit for building Claude Code plugins, skills, and hooks.
- **[warp](https://github.com/warpdotdev/claude-code-warp)** *(Warp)* — native Warp terminal notifications when a turn finishes or needs input.

---

## What's in `.claude/` and why

### `settings.json` — the harness config
Key choices worth understanding before you copy them:

- **`hooks`**
  - `PreToolUse` Bash → `rtk hook claude` — transparent token-cutting rewrite of noisy commands.
  - `SessionStart` → `scripts/inject-orchestrator-role.sh` — injects the orchestrator role (below)
    into the **top-level** session only.
  - `Stop` → plays `icq-uh-oh.mp3` via mpg123 when a turn ends (pure vanity; safe to drop).
- **`permissions.allow`** — a read-only allowlist (reads under `~/devel`, `~/.claude*`, `/tmp`;
  `* --help` / `* --version`; bare `Skill`). The philosophy: **read-only is auto-allowed, anything
  remote/destructive prompts.** Beyond this static allowlist, rely on Claude's **auto mode** to
  approve provably-safe commands. (I used to drive this with a custom `bash-classify-hook` plugin;
  it's intentionally **not** part of this package anymore.)
- **`model`** — pinned to a specific Opus build (`claude-opus-4-8[1m]`, 1M context). Change to your
  current model.
- **`autoCompactEnabled: false`** — I manage context **by hand** instead of letting auto-compaction
  fire. The status line shows headroom; when I need to shed, I run `/handover-generate` and start a
  fresh session rather than compact in place. This is deliberate — compaction mid-task costs quality.
- **`alwaysThinkingEnabled: true`**, **`effortLevel: "medium"`**, **`autoMemoryEnabled: true`**,
  **`plansDirectory: ".claude/plans/"`**, **`cleanupPeriodDays: 99999`** (never auto-delete
  sessions), **`spinnerVerbs`** replaced with "Hallucinating" (vanity).
- **`env`** — `DISABLE_AUTOUPDATER=1` (I pin the version manually),
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` (load `CLAUDE.md` from `--add-dir` dirs),
  `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1`, plus a couple of tool toggles.

> Paths inside this file use `~/...` / `$HOME/...` forms so they work for any user. If you add
> absolute paths of your own, swap them for your real home directory.

### `orchestrator-role.md` + `scripts/inject-orchestrator-role.sh`
The **main agent is a pure orchestrator**: it talks to you, decides, delegates, and synthesizes —
it does *not* do bulk work itself. Code exploration, writing, builds/tests, DB/infra/telemetry
queries, and bulk searches all get delegated to subagents (one at a time, watched — never
background/parallel unless asked). The injector script reads the SessionStart hook payload and
injects this role **only into the top-level session** (it detects subagents by the `agent_id` field
and stays silent for them, so subagents aren't told to delegate-the-delegation).

### `scripts/status-line.sh`
The instrument that makes manual context management possible. Shows: host letter, cwd (with a `⌥`
worktree indicator, stripping `/.worktrees/<name>`), git branch + dirty marker + `!<mr-id>`,
**color-coded context usage** shown compactly as `Ctx: 43k (4%)` (green <40% / orange 40–65% /
red ≥65%), model, active profile, and the time of the last transcript activity.
*Dependencies:* the `!<mr-id>` part calls `git get-branch-mr-id`, a custom alias from my gitconfig
(https://github.com/fprochazka/gitconfig). Without it the rest still works.

### `commands/` — custom slash commands
- **`/pre-plan`** — gather context (ticket + code) and frame the problem; does NOT plan or implement.
- **`/handover-generate`** — write a WHAT+WHY handover doc so a fresh session can resume cleanly
  (my alternative to auto-compaction).
- **`/ticket-new`** — draft + create a ticket from the conversation.
- **`/open-mr`** — open a draft MR and refine its title/description to match the real changes.
- **`/interview`** — long technical interview that produces a detailed project spec.
- **`/remember`** — reflect and propose updates to permanent memory files.
- **`/chrome-auto-connect`** — connect `agent-browser` to your already-running Chrome.

### `CLAUDE.md` — global memory
My global rules (skills-first, never dismiss build errors, minimal local verification + let CI do
the heavy lifting, `$(cat <file>)` for long tool args, jq-over-python). **Identity is placeholdered**
— set your own name/email at the top.

### `skills/` — bundled skills  ⚠️ prune what you don't use
The skills shipped here all wrap generic CLIs you'd install separately (`gh`, `gws`, `linear-mcp`,
`outline`, `readwise`). Each carries `trigger-keywords` so it auto-loads when relevant. **Keep only
the ones whose CLIs you actually install.**

> The **Datadog `dd-*` skills are intentionally NOT shipped here** — `pup` installs its own
> (always matching the installed version). See [Datadog telemetry](#datadog-telemetry--pup--its-skills).
>
> A **writing-style skill** isn't shipped either (it would only impersonate one person) — but the
> method to build your own is reusable. See [Building a writing-style skill](#building-a-writing-style-skill-from-your-slack-history).

---

## Multi-account profiles — `.claude-profiles/` + `.local/bin/`

The example config runs three accounts (personal / work team / work-via-Vertex) side by side with
isolated credentials but a **shared** `~/.claude/` config, using
[`claude-code-auth-switch`](https://github.com/fprochazka/claude-code-auth-switch).

- **`.claude-profiles/config.yaml`** is the source of truth (model, `--add-dir`s, attribution,
  per-profile env like `GITLAB_HOST` / `DD_SITE` / `SLACK_ORG` / Vertex).
- Running `install.py` generates the thin wrapper scripts in **`.local/bin/claude-*`**, each of which
  isolates `CLAUDE_CONFIG_DIR`, exports the profile env, and injects the default model + add-dirs.
  Those wrappers are **auto-generated** — included here only as reference; don't hand-edit them.
- It works by pointing `CLAUDE_CONFIG_DIR` at a per-profile dir; mutable files (settings, CLAUDE.md)
  are copied, the rest of `~/.claude/` (commands/skills/agents/plugins) is symlinked back so it's shared.

If you only have one account, you don't need any of this.

---

## Tool configs

Most of my integrations are **CLIs wrapped in skills** (see "CLI + SKILL >> MCP" above). Each CLI
keeps its own config file; example/sanitized copies are included here so you can see the shape.
**Every secret below is a placeholder — fill in your own, or run the tool's `init`/`auth` command.**

| Tool | Config file | Installed via | Secret to fill |
|------|-------------|---------------|----------------|
| `rabbitmqadmin` | `.rabbitmqadmin.conf` | cargo (`rabbitmqadmin-ng`) | every node `username`/`password` |
| `linear-mcp` | `.config/linear-mcp/config.yaml` | https://github.com/fprochazka/linear-mcp-cli | `linear.api_key` |
| `slack` | `.config/slackcli/config.toml` | `slackcli` plugin / repo | per-org `xoxp` token |
| `metabase` | `.config/metabasecli/config.toml` | `metabasecli` plugin | `session_id` / password (`metabase auth login`) |
| `outline` (`ol`) | `.config/outline-cli/config.json` | `outline-cli` | `api_token` |
| `searxng` | `.config/searxngcli/config.yml` | `searxngcli` plugin | none — just your instance URL |
| `gws` (Google Workspace) | `~/.config/gws/{personal,work}/` | `gws-cli` | OAuth `client_secret.json` (see below) |

### The `*-mcp-cli` pattern (why a CLI instead of an MCP)
`linear-mcp` is an **MCP client re-exposed as a CLI**: it connects to an MCP
server but surfaces each MCP tool as a shell subcommand. That way you get the MCP backend **without**
paying the context-window cost of registering an MCP in Claude — the skill teaches Claude the
commands on demand. This is the practical form of the CLI-over-MCP principle.

### Worked example — setting up `linear-mcp-cli`
1. **Install the CLI** per the repo's instructions: https://github.com/fprochazka/linear-mcp-cli
   (puts `linear-mcp` on your PATH).
2. **Configure it** — run `linear-mcp init`. It asks for your Linear API key (get one at
   https://linear.app/settings/api) and writes `~/.config/linear-mcp/config.yaml` (the file in this
   repo is the resulting shape, with the key placeholdered). Alternatively export `LINEAR_API_KEY`.
3. **The skill is already here** — `.claude/skills/linear-mcp-cli/` teaches Claude the commands and
   carries `trigger-keywords: linear, issue, ticket, …` so it auto-loads when relevant.
4. **Verify:** `linear-mcp list_teams` and `linear-mcp list_issues --assignee me`.

Every other CLI follows the same three beats: install the CLI → drop/`init` its `~/.config/<tool>/`
file with your credentials → its skill (already in `.claude/skills/`) teaches Claude to use it.

### `gws` (Google Workspace) — wrappers shipped, configs/secrets are not
Multi-account works by pointing `GOOGLE_WORKSPACE_CLI_CONFIG_DIR` at a per-account config dir. The
two one-line wrappers that do this **are included** (`.local/bin/gws-personal` → `~/.config/gws/personal`,
`.local/bin/gws-work` → `~/.config/gws/work`). What's **not** shipped is the per-account
config/credentials — you generate those yourself:

1. Create an **OAuth desktop client** in a GCP project and download its `client_secret.json` into
   `~/.config/gws/<account>/` (one per account: `personal`, `work`).
2. Run the wrapper once (`gws-personal …` / `gws-work …`) to do the **browser auth**; it caches an
   encrypted token alongside the client secret.

No `client_secret.json` or token is included here — the secret is yours to generate. (The `gws-cli`
skill in `.claude/skills/` teaches Claude the commands.)

---

## Datadog telemetry — `pup` (+ its skills)

For logs / metrics / traces / monitors / incidents I use Datadog's **`pup`** CLI
(https://github.com/DataDog/pup). It auto-detects Claude Code and switches to structured-JSON
"agent mode". **I deliberately do NOT vendor the `dd-*` skills into this repo** — `pup` ships them
itself and installs the set that matches the installed binary, so they never go stale.

**1. Install the CLI** per the repo's instructions: https://github.com/DataDog/pup

**2. Install its Claude Code skills** (skills + domain agents are embedded in the binary):
```bash
pup skills list                                   # see what's available
pup skills install --target-agent=claude-code     # install all (dd-pup, dd-logs, dd-monitors,
                                                  #  dd-apm, dd-docs, dd-debugger, dd-symdb, …)
```
> ⚠️ `pup skills install` writes to the **project-local** `./.claude/skills/` by default. To match
> my global setup, install into the user dir explicitly:
> `pup skills install --target-agent=claude-code --dir ~/.claude/skills`

(Alternative: add it as a plugin marketplace — `/plugin marketplace add DataDog/pup` → plugin `pup`.)

**3. Auth & config:** OAuth2 is preferred — `pup auth login` (browser, tokens in the system
keychain); falls back to `DD_API_KEY` + `DD_APP_KEY`. Set **`DD_SITE`** to your org's site
(the profiles export `DD_SITE=datadoghq.com` as an example). Verify with `pup auth status`.

---

## Building a writing-style skill from your Slack history

A personal writing-style skill isn't shipped here — such a skill only exists to impersonate one
specific person — but the way you build one is reusable, so here's the recipe to make your own. It's
a textbook fan-out → aggregate → synthesize orchestration, powered by the `slackcli` plugin:

1. **Fan out per month.** Launch a batch of subagents, one per month of history, each told to use
   the `slack` CLI (with your `xoxp` *user* token, so it queries as **you**) to pull every message
   *you* posted that month and extract recurring writing patterns — tone, sentence length,
   punctuation/emoji habits, language code-switching, opening/closing phrases, vocabulary tics.
   Per-month batching keeps each subagent's context small and the Slack queries scoped.
2. **Aggregate + author.** The main (orchestrator) agent collects the monthly extractions, dedups
   and reconciles them into one coherent style description, and writes the `SKILL.md` — a
   prompt-only style guide with no tool backing.
3. **Refine over time.** Whenever the output feels off, feed back real examples and have it tighten
   the rules; the tone improves as you correct it.

---

## ⚠️ Secrets — replace before use

Everything sensitive in this repo is a **placeholder**. Before you rely on any of it, fill in:

- `.rabbitmqadmin.conf` → every `username` / `password`.
- `.config/linear-mcp/config.yaml` → `linear.api_key`.
- `.config/slackcli/config.toml` → per-org `xoxp` token.
- `.config/metabasecli/config.toml` → `session_id` / `password`.
- `.config/outline-cli/config.json` → `api_token`.
- `.config/searxngcli/config.yml` → your own instance URL.
- `.claude/CLAUDE.md` → your name + email.

There are **no real credentials** committed. Keep it that way.

---

## For Claude: how to adopt this

You've been handed this template so the user can take over part or all of it as their Claude Code
setup. Treat the repo as a **home-directory overlay** (`.claude/` → `~/.claude/`, etc.).

**Workflow:**

1. **Ask the user the scope** unless they already said: *everything*, or a named subset
   (e.g. "just the orchestrator role + status line", "the permission setup", "the commands").
2. **Never blindly overwrite.** For each target file that already exists in the user's `~`, diff it
   and **merge** rather than clobber — especially `~/.claude/settings.json` and `~/.claude/CLAUDE.md`,
   which are usually personalized. Show the user the diff for these two before writing.
3. **Replace placeholders, don't copy them.** Anything matching `REPLACE_WITH_*`, `YOUR_*`,
   or the placeholdered identity must be filled with the user's real values (ask) or the surrounding
   block dropped. Do **not** write a placeholder into a live config.
4. **Check prerequisites per component** (see the Prerequisites section). If a hook references a tool
   the user doesn't have (`rtk`, `mpg123`, `jq`), either install it or drop that hook — don't leave a
   broken hook. `jq` is required for the orchestrator hook and status line.
5. **Fix paths.** Any absolute home paths must become the user's home. Prefer the `~/...` /
   `$HOME/...` forms already used throughout.
6. **Skills:** only copy the ones the user wants; most need their CLI installed. Confirm before
   copying `skills/` wholesale.
7. **Profiles/`.local/bin`:** only relevant if the user runs multiple accounts. If so, install
   `claude-code-auth-switch`, write `~/.claude-profiles/config.yaml` (rename the `work-team` /
   `work-vertex` example profiles to match their accounts), and let *its* `install.py` regenerate the
   `.local/bin/claude-*` wrappers — don't copy the wrapper files directly.
8. **Plugins:** don't copy plugin files. Run `.claude/scripts/claude-plugins-install-all.sh`
   (or install the subset the user wants from the marketplaces listed there / in `settings.json`).
9. After applying, **tell the user exactly what changed**, what still needs a real secret, and
   suggest restarting Claude Code to load new hooks/plugins/settings.

**Suggested order for a full adoption:** plugins (install script) → `settings.json` (merge) →
`orchestrator-role.md` + injector hook → `status-line.sh` → `commands/` → `CLAUDE.md` (merge,
re-identify) → chosen `skills/` → tool configs → (optional) profiles.
