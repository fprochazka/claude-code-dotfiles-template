---
description: Connect to the user's running Chrome browser via CDP auto-discovery and interact with it.
argument-hint: [what to do with the browser]
allowed-tools: Bash(agent-browser skills get core)
---

Connect to the user's running Chrome browser via CDP auto-discovery and interact with it.

$ARGUMENTS

## Background

Chrome 144+ has built-in remote debugging enabled via `chrome://inspect/#remote-debugging`. This does NOT expose the traditional HTTP-based CDP endpoints, so `--cdp <port>` won't work. Use `--auto-connect` on every `agent-browser` command instead.

## Instructions

1. Read the agent-browser command reference at the end of this file.
2. Start by listing open tabs: `agent-browser --auto-connect tab`

## Reference: agent-browser core skill

!`agent-browser skills get core`
