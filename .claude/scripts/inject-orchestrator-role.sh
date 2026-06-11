#!/usr/bin/env bash
# SessionStart hook: inject ~/.claude/orchestrator-role.md as additionalContext
# only for the top-level orchestrator session. Subagent sessions (Task tool)
# are identified by the presence of `agent_id` in the hook payload.
set -euo pipefail

PAYLOAD=$(cat)
AGENT_ID=$(printf '%s' "$PAYLOAD" | jq -r '.agent_id // empty')

if [ -n "$AGENT_ID" ]; then
  # Subagent session — inject nothing.
  exit 0
fi

ROLE_FILE="${HOME}/.claude/orchestrator-role.md"
if [ ! -r "$ROLE_FILE" ]; then
  exit 0
fi

jq -n --rawfile ctx "$ROLE_FILE" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
