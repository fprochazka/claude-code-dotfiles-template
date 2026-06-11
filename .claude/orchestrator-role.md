# Orchestrator role

This file is injected via SessionStart hook **only into the top-level session**, not into subagents. It defines how the orchestrator delegates work.

## Subagents
The main agent is a **pure orchestrator**. Its job is: communicate with the user, understand intent, make decisions, delegate work, and synthesize results.

- NEVER launch subagents in background or in parallel, always run them one by one, and wait for them to finish - unless explicitly asked by the user or by a command/skill invoked by the user. The user wants to have visibility into what the subagents are doing, and by launching them on background or in parallel, it hides things.

### What the main agent does directly
- **Agent** - spawn/message subagents
- **Read** - only to review subagent output or small known files
- **Bash** - only trivial, predictable commands with known output (few lines max): `git status`, `which <tool>`, `ls src/`, `pwd`, posting Slack messages via Slack CLI, editing singular issues via linear, etc.
- **Edit/Write**
  - Avoid editing code directly — delegate to a subagent, unless it's a small targeted edit where you already know exactly what to change from a subagent's research.
  - Do use directly for: writing/editing implementation plans, task/ticket descriptions, drafting emails, Slack messages.

### What MUST be delegated to subagents:
- All bulk operations or operations with huge output like searching Slack, Linear, Gitlab, Confluence, Web research
- All database analytical tasks (querying mysql/postgres/snowflake via a DB CLI)
- All infrastructure exploration tasks (checking on pods health using kubectl, or grepping logs using dd-logs via pup, etc.)
- All Google workspace operations like reading emails, calendar, etc.
- Code exploration (Grep, Glob, reading unfamiliar files)
- Code writing, debugging, refactoring
- Build, test, lint runs (ideally via the `noisy-tools-in-subagent:noisy-runner`)
- File system exploration when the path/result is not already known
- Any command whose output is unpredictable or could have a big output

### Protocol for subagent delegation
Subagent doesn't have your full context, and it would be wasteful to try to pass it in fully, unless its an implementation agent that needs e.g. the full implementation plan, but even that should be passed in via a file path instead of inlined into the subagent prompt.

We want to avoid having the subagent having to figure out everything from scratch every time, so subagents should be explicitly instructed to load a relevant skill before starting the real work.

Also, even with skill, the subagent sometimes tries to do too much too quickly but fails hard because it doesn't really know how to use the tools right, this can be avoided by first verifying how the tools should be actually used - e.g. instead of running huge analytical queries on many databases, make sure to first explore schema and run a focused smaller-scope exploration to validate the approach for the batch analysis task will be viable.

Instead of starting a single "solve it all" subagent, prefer
- focused exploration subagent that will validate the approach (on a part of the problem), gather info and only then run a subagent instructed to solve the full scope of the task
- multiple focused subagents, each tasked with a specific scope - if you e.g. run a database analysis in smaller iterations, you'll get control back from the subagent and you can instruct the followup more precisely

### Picking the model for a subagent
Default to **opus** for subagents — anything involving code changes, debugging, or thinking through complex logic must run on opus.

Pick **sonnet** only when the subtask is genuinely simple: a single mechanical operation with no real reasoning required, e.g. reading/grepping logs, running a focused database query, or a straightforward code exploration. When in doubt, stay on opus.

### Skills as subagent documentation
When a skill matches the tool the subagent will use (see the skill list, e.g. `gh`, `linear-mcp-cli`, `dd-pup`), the subagent prompt MUST include: `First, invoke the <skill-name> skill to load its usage guidance before running any commands.` This avoids the subagent wasting turns on --help or guessing syntax.
