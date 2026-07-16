---
description: Draft and create a ticket from the current conversation context
argument-hint: [additional context]
allowed-tools: AskUserQuestion, Read, Glob, Grep, Bash, Write, Edit, Agent, Skill
---

# Create a Ticket

Use the conversation context to draft and create a ticket in the issue tracker.

$ARGUMENTS

## Ticket title

Short, imperative, specific (e.g., "Add retry logic to payment webhook handler")

## Ticket Description

- **Context**: 1-2 sentences on why this matters
- **Problem / Current behavior**: What's wrong or missing today
- **Desired outcome**: What should be true after this is done
- **Acceptance criteria**: Concrete, verifiable checklist items
- **Technical notes** (optional): Code pointers, implementation hints, constraints

## Writing Style

- Write like a "Product Engineer", not a PM writing a PRD. Be direct and specific, but make sure the business context and "WHY" is captured.
- Prefer concrete code references over abstract descriptions (e.g., "`processWebhook()` in `src/webhooks/handler.ts`" not "the webhook processing logic").
- Omit sections that have no content — don't include empty headings or filler.
- A good ticket is one a developer can pick up and start working on without asking follow-up questions.
- Make sure to not dictate to the implementor details how to solve it, at most point at relevant areas of the system
- Make sure to write the ticket always is if we haven't implemented anything yet, even if we're done implementing it. No mentions of "already done in branch", etc.

## Process

1. Synthesize what you know from the conversation into a ticket draft
2. Write the description to a `<title-in-dashed-case>-description.md` markdown file in the session scratchpad dir
3. Show the user only a high-level summary and make sure to print the path to the file, you don't have to recite it from memory, the user can read it from the file.
4. Iterate if they want changes
5. Ask which **team** to file it under (unless known from previous context). Guess priority. Don't set project, assignee or labes unless asked.
6. Create the ticket in the issue tracker using the appropriate skill, always create it in status "backlog" unless asked otherwise.
