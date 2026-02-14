#!/bin/bash
# git-wrapper.sh — Pre-tool-use hook for git safety
#
# Prevents dangerous git operations inside the Ralph Docker container:
# - Force-push (git push -f / --force / --force-with-lease)
# - Direct pushes to main/master
# - Branch deletion (git branch -D / --delete)
#
# All git commands are logged to /var/log/git-commands.log

CMD="$1"
shift

# Prevent force-push
if [[ "$CMD" == "push" ]]; then
    for arg in "$@"; do
        if [[ "$arg" == "-f" ]] || [[ "$arg" == "--force" ]] || [[ "$arg" == "--force-with-lease" ]]; then
            echo "ERROR: Force push is not allowed by security policy"
            exit 1
        fi
    done
    # Prevent pushes to main/master
    for arg in "$@"; do
        if [[ "$arg" == "main" ]] || [[ "$arg" == "master" ]] || [[ "$arg" == "origin/main" ]] || [[ "$arg" == "origin/master" ]]; then
            echo "ERROR: Cannot push directly to main/master — create PR instead"
            exit 1
        fi
    done
fi

# Prevent branch deletion
if [[ "$CMD" == "branch" ]]; then
    for arg in "$@"; do
        if [[ "$arg" == "-D" ]] || [[ "$arg" == "--delete" ]]; then
            echo "ERROR: Branch deletion is not allowed by security policy"
            exit 1
        fi
    done
fi

# Prevent dangerous reset
if [[ "$CMD" == "reset" ]]; then
    for arg in "$@"; do
        if [[ "$arg" == "--hard" ]]; then
            echo "ERROR: Hard reset is not allowed by security policy"
            exit 1
        fi
    done
fi

# Audit log (file + stderr for persistence beyond container lifecycle)
LOG_MSG="$(date '+%Y-%m-%d %H:%M:%S'): $USER executed: git $CMD $*"
echo "$LOG_MSG" >> /var/log/git-commands.log 2>/dev/null
echo "$LOG_MSG" >&2

# Execute the real git command
exec /usr/bin/git "$CMD" "$@"
