#!/bin/bash
set -euo pipefail

PLUGINS_CONFIG="${HOME}/.claude/plugins/installed_plugins.json"

echo "==> Updating all marketplaces..."
claude plugin marketplace update
echo ""

if [[ ! -f "$PLUGINS_CONFIG" ]]; then
  echo "Error: $PLUGINS_CONFIG not found"
  exit 1
fi

mapfile -t plugins < <(jq -r '.plugins | keys[]' "$PLUGINS_CONFIG")

if [[ ${#plugins[@]} -eq 0 ]]; then
  echo "No plugins found to update."
  exit 0
fi

echo "==> Updating ${#plugins[@]} plugins..."
echo ""

failed=()
for plugin in "${plugins[@]}"; do
  echo "--- Updating: $plugin"
  if ! claude plugin update "$plugin"; then
    echo "    FAILED: $plugin"
    failed+=("$plugin")
  fi
  echo ""
done

if [[ ${#failed[@]} -eq 0 ]]; then
  echo "==> All plugins updated successfully."
else
  echo "==> Done with ${#failed[@]} failure(s):"
  for p in "${failed[@]}"; do
    echo "  - $p"
  done
  exit 1
fi

echo ""
echo "Restart your Claude Code session to apply changes."
