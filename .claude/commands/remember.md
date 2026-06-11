---
description: Reflect on conversation and propose memory updates
disable-model-invocation: true
---

# Update Permanent Memory

Reflect on our conversation and identify any learnings worth preserving in your permanent memory files.

## Instructions

1. **Review the conversation** for:
   - New patterns or conventions discovered
   - Solutions to non-obvious problems
   - Important architectural decisions or rationale
   - Useful commands, workflows, or techniques
   - Corrections to previous assumptions
   - Project-specific knowledge that would help future sessions

2. **Determine the appropriate location** (consider scope and importance):

   **Always-loaded memory** (injected into every conversation, keep minimal):
   - **Project-specific `AGENTS.md`** - critical knowledge that must NEVER be forgotten for this codebase
   - **Parent project `AGENTS.md`** - critical knowledge shared across related projects
   - **`~/.claude/CLAUDE.md`** - only for truly global learnings applicable everywhere

   **Reference documentation** (looked up as needed, not always in context):
   - **Project's `docs/` directory** - important patterns, decisions, and knowledge that should be preserved but doesn't need to occupy context in every session

3. **Propose changes before making them**:
   - State which file you want to update
   - Show the exact additions or modifications
   - Explain why this is worth remembering
   - Wait for my approval before editing

4. **Keep entries concise** - future you should be able to scan quickly

If nothing from this conversation is worth preserving, say so.
