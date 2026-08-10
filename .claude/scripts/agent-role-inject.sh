#!/usr/bin/env bash
# Injects the per-role instruction file as additionalContext:
#   SessionStart  -> agent-role-orchestrator.md (fires only for the top-level session, never for subagents)
#   SubagentStart -> agent-role-worker.md (fires for every subagent, at any nesting depth)
# Depth is not detectable from hook payloads (no depth/parent fields), so all subagents share one worker role.
set -euo pipefail

EVENT=$(jq -r '.hook_event_name // empty')

case "$EVENT" in
  SessionStart)  ROLE_FILE="${HOME}/.claude/agent-role-orchestrator.md" ;;
  SubagentStart) ROLE_FILE="${HOME}/.claude/agent-role-worker.md" ;;
  *) exit 0 ;;
esac

if [ ! -r "$ROLE_FILE" ]; then
  exit 0
fi

jq -n --arg event "$EVENT" --rawfile ctx "$ROLE_FILE" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: $ctx
  }
}'
