#!/bin/bash
set -euo pipefail

echo "==> Adding marketplaces..."

MARKETPLACES=(
  "git@github.com:fprochazka/bash-classify.git"
  "git@github.com:fprochazka/claude-code-plugins.git"
  "git@github.com:fprochazka/devin-mcp-cli.git"
  "git@github.com:fprochazka/glab-discussion.git"
  "git@github.com:fprochazka/glab-pipeline.git"
  "git@github.com:fprochazka/metabasecli.git"
  "git@github.com:fprochazka/slackcli.git"
  "git@github.com:vercel-labs/agent-browser.git"
  "anthropics/claude-plugins-official"
  "anthropics/claude-code"
  "warpdotdev/claude-code-warp"
)

for mp in "${MARKETPLACES[@]}"; do
  echo "--- Adding marketplace: $mp"
  claude plugin marketplace add "$mp" --scope user || echo "    (already added or failed)"
  echo ""
done

echo "==> Installing plugins..."

PLUGINS=(
  "agent-browser@agent-browser"
  "bash-classify-hook@fprochazka-bash-classify"
  "code-review@fprochazka-claude-code-plugins"
  "devin-mcp-cli@fprochazka-devin-mcp-cli"
  "git@fprochazka-claude-code-plugins"
  "glab-discussion@fprochazka-glab-discussion"
  "glab-pipeline@fprochazka-glab-pipeline"
  "glab@fprochazka-claude-code-plugins"
  "metabasecli@fprochazka-metabasecli"
  "migrate-to-uv@fprochazka-claude-code-plugins"
  "noisy-tools-in-subagent@fprochazka-claude-code-plugins"
  "plugin-dev@claude-code-plugins"
  "prose@fprochazka-claude-code-plugins"
  "rabbitmqadmin@fprochazka-claude-code-plugins"
  "sdlc@fprochazka-claude-code-plugins"
  "searxngcli@fprochazka-claude-code-plugins"
  "skill-keyword-reminder@fprochazka-claude-code-plugins"
  "slackcli@fprochazka-slackcli"
  "warp@claude-code-warp"
)

failed=()
for plugin in "${PLUGINS[@]}"; do
  echo "--- Installing: $plugin"
  if ! claude plugin install "$plugin" --scope user; then
    echo "    FAILED: $plugin"
    failed+=("$plugin")
  fi
  echo ""
done

if [[ ${#failed[@]} -eq 0 ]]; then
  echo "==> All plugins installed successfully."
else
  echo "==> Done with ${#failed[@]} failure(s):"
  for p in "${failed[@]}"; do
    echo "  - $p"
  done
  exit 1
fi

echo ""
echo "Restart your Claude Code session to apply changes."
