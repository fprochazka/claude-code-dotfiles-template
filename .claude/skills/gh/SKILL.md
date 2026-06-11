---
name: gh
description: GitHub CLI for interacting with GitHub API - pull requests, issues, gists, repositories, actions, and more. Use when working with GitHub to list/view PRs, check CI status, browse issues, or any GitHub API operation. Triggered by requests involving GitHub data, pull requests, issues, or GitHub project management.
trigger-keywords: github, gh, pull request, PR
allowed-tools: Bash(gh gist --help), Bash(gh issue --help), Bash(gh issue close --help), Bash(gh issue comment --help), Bash(gh issue create --help), Bash(gh issue delete --help), Bash(gh issue develop --help), Bash(gh issue edit --help), Bash(gh issue list --help), Bash(gh issue lock --help), Bash(gh issue pin --help), Bash(gh issue reopen --help), Bash(gh issue status --help), Bash(gh issue transfer --help), Bash(gh issue unlock --help), Bash(gh issue unpin --help), Bash(gh issue view --help), Bash(gh org --help), Bash(gh pr --help), Bash(gh pr checkout --help), Bash(gh pr checks --help), Bash(gh pr close --help), Bash(gh pr comment --help), Bash(gh pr create --help), Bash(gh pr diff --help), Bash(gh pr edit --help), Bash(gh pr list --help), Bash(gh pr lock --help), Bash(gh pr merge --help), Bash(gh pr ready --help), Bash(gh pr reopen --help), Bash(gh pr revert --help), Bash(gh pr review --help), Bash(gh pr status --help), Bash(gh pr unlock --help), Bash(gh pr update-branch --help), Bash(gh pr view --help), Bash(gh project --help), Bash(gh release --help), Bash(gh repo --help), Bash(gh cache --help), Bash(gh run --help), Bash(gh workflow --help), Bash(gh api --help), Bash(gh gpg-key --help), Bash(gh label --help), Bash(gh ruleset --help), Bash(gh search --help), Bash(gh secret --help), Bash(gh ssh-key --help), Bash(gh status --help), Bash(gh variable --help), Bash(gh gist list:*), Bash(gh gist view:*), Bash(gh issue list:*), Bash(gh issue status:*), Bash(gh issue view:*), Bash(gh pr list:*), Bash(gh pr status:*), Bash(gh pr checks:*), Bash(gh pr diff:*), Bash(gh pr view:*)
---

# gh - GitHub CLI

Use `gh <command> --help` to discover available commands and flags.

## Common Read Operations

```bash
# Pull requests
gh pr list
gh pr view <number>
gh pr diff <number>
gh pr checks <number>
gh pr status

# Issues
gh issue list
gh issue view <number>
gh issue status

# Gists
gh gist list
gh gist view <id>
```
