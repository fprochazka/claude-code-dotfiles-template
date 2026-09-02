#!/usr/bin/env bash
# Injects the shared instructions plus the per-role instruction file as additionalContext:
#   agent-all.md  -> both events, first, so the role file can build on it
#   SessionStart  -> agent-role-orchestrator.md (fires only for the top-level session, never for subagents)
#   SubagentStart -> agent-role-worker.md (fires for every subagent, at any nesting depth)
# Depth is not detectable from hook payloads (no depth/parent fields), so all subagents share one worker role.
#
# Hook output is literal text, so the memory-file "@path" import is never expanded for us. The script
# expands it here instead, one level deep, to keep a single source of truth for imported rule files.
set -euo pipefail

EVENT=$(jq -r '.hook_event_name // empty')

case "$EVENT" in
  SessionStart)  ROLE_FILE="${HOME}/.claude/agent-role-orchestrator.md" ;;
  SubagentStart) ROLE_FILE="${HOME}/.claude/agent-role-worker.md" ;;
  *) exit 0 ;;
esac

ALL_FILE="${HOME}/.claude/agent-all.md"

# Prints a file, replacing every line that is only an "@path" import with the contents of that file.
# An unreadable target is left as the literal line, so a broken path stays visible instead of vanishing.
emit_expanded() {
  local line path
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '@'?*)
        path="${line#@}"
        path="${path%"${path##*[![:space:]]}"}"
        case "$path" in
          '~/'*)      path="${HOME}/${path#\~/}" ;;
          '$HOME/'*)  path="${HOME}/${path#\$HOME/}" ;;
        esac
        case "$path" in
          /*) if [ -r "$path" ]; then cat -- "$path"; printf '\n'; continue; fi ;;
        esac
        printf '%s\n' "$line"
        ;;
      *) printf '%s\n' "$line" ;;
    esac
  done < "$1"
}

CTX=""
if [ -r "$ALL_FILE" ]; then
  CTX="$(emit_expanded "$ALL_FILE")"$'\n\n'
fi
if [ -r "$ROLE_FILE" ]; then
  CTX="${CTX}$(emit_expanded "$ROLE_FILE")"
fi

if [ -z "$CTX" ]; then
  exit 0
fi

jq -n --arg event "$EVENT" --arg ctx "$CTX" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: $ctx
  }
}'
