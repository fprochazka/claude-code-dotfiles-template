#!/usr/bin/env bash
# Status line script for Claude Code
# Displays: B ~/full/path (git_branch*) | Ctx: 43k (4%) | Model: Opus 4.6 | 14:32

# Define ANSI color codes
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
ORANGE=$'\e[38;5;208m'
RED=$'\e[31m'
RESET=$'\e[0m'

# Read JSON input from stdin
input=$(cat)

# Extract all needed values in a single jq call
eval "$(echo "$input" | jq -r '
  "cwd=" + (.workspace.current_dir | @sh),
  "used_pct=" + ((.context_window.used_percentage // 0) | floor | tostring),
  "ctx_size=" + ((.context_window.context_window_size // 0) | tostring),
  "input_tokens=" + (((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0)) | tostring),
  "model_name=" + ((.model.display_name // "") | @sh),
  "transcript_path=" + ((.transcript_path // "") | @sh)
')"

# Strip /.worktrees/<name> suffix to show the project root
display_cwd="$cwd"
worktree_indicator=""
if [[ "$display_cwd" == */.worktrees/* ]]; then
    display_cwd="${display_cwd%%/.worktrees/*}"
    worktree_indicator=" ${YELLOW}⌥${RESET}  "
fi

# Show full path, replacing home directory with ~
if [ "$display_cwd" = "$HOME" ]; then
    display_path="~"
elif [[ "$display_cwd" == "$HOME"/* ]]; then
    display_path="~/${display_cwd#$HOME/}"
else
    display_path="$display_cwd"
fi

# Get git information with TTL-based caching
git_cache="/tmp/claude-statusline-git${cwd//\//_}"
git_cache_ttl=5
git_info=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$git_cache" 2>/dev/null || echo 0)))
    if [ -f "$git_cache" ] && [ $cache_age -lt $git_cache_ttl ]; then
        git_info=$(<"$git_cache")
    else
        branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
                 git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

        if [ -n "$branch" ]; then
            dirty=""
            if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || \
               ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
                dirty="*"
            fi

            mr_suffix=""
            mr_id=$(git -C "$cwd" get-branch-mr-id "$branch" 2>/dev/null || true)
            if [ -n "$mr_id" ]; then
                mr_suffix=" !${mr_id}"
            fi

            if [ -n "$worktree_indicator" ]; then
                git_info="${YELLOW}(${branch}${dirty}${mr_suffix})${RESET}"
            else
                git_info=" ${YELLOW}(${branch}${dirty}${mr_suffix})${RESET}"
            fi
        fi
        printf '%s' "$git_info" > "$git_cache"
    fi
fi

# Map hostname to a short prefix shown at the start of the status line.
# Add an arm per machine if you want a compact letter instead of the full hostname.
hostname=$(hostname -s)
case "$hostname" in
    # my-laptop) prefix="L" ;;
    *)          prefix="$hostname" ;;
esac

# Build context window info using pre-calculated percentage
context_info=""
if [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    current_k=$((input_tokens / 1000))

    # Color based on used_percentage: green < 40%, orange 40-65%, red >= 65%
    if [ "$used_pct" -lt 40 ]; then
        color="$GREEN"
    elif [ "$used_pct" -lt 65 ]; then
        color="$ORANGE"
    else
        color="$RED"
    fi

    context_info=$(printf " | Ctx: %s%sk (%s%%)%s" "$color" "$current_k" "$used_pct" "$RESET")
fi

# Model info
model_info=""
if [ -n "$model_name" ]; then
    model_info=" | Model: $model_name"
fi

# Profile info (set by claude-code-auth-switch wrapper scripts)
profile_info=""
if [ -n "${FP_CC_AUTH_SWITCH_PROFILE:-}" ]; then
    profile_info=" | Profile: $FP_CC_AUTH_SWITCH_PROFILE"
fi

# Build AGE info from the last transcript entry's timestamp
age_info=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    last_ts=$(tail -1 "$transcript_path" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null)
    if [ -n "$last_ts" ]; then
        # Convert ISO 8601 timestamp to epoch seconds
        last_epoch=$(date -d "$last_ts" +%s 2>/dev/null)
        if [ -n "$last_epoch" ]; then
            today=$(date +%Y-%m-%d)
            entry_date=$(date -d "@$last_epoch" +%Y-%m-%d)
            if [ "$entry_date" = "$today" ]; then
                age_fmt=$(date -d "@$last_epoch" +%H:%M)
            else
                age_fmt=$(date -d "@$last_epoch" "+%Y-%m-%d %H:%M")
            fi
            age_info=" | $age_fmt"
        fi
    fi
fi

# Output the status line
printf '%s%s%s %s%s%s%s%s%s%s ' "$GREEN" "$prefix" "$RESET" "$display_path" "$worktree_indicator" "$git_info" "$context_info" "$model_info" "$profile_info" "$age_info"
