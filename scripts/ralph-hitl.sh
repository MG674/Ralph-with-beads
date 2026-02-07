#!/bin/bash
# ralph-hitl.sh - Human-in-the-Loop Ralph (single iteration)
# Use this when starting a new feature, doing risky work, or learning how Ralph behaves
set -e

# Usage: ./ralph-hitl.sh /path/to/project [prompt-file]
PROJECT_DIR="${1:-.}"
PROMPT_FILE="${2:-$PROJECT_DIR/prompt.md}"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: prompt.md not found at $PROMPT_FILE"
    exit 1
fi

echo "=== RALPH HITL — Single Iteration ==="
echo "Project: $PROJECT_DIR"
echo "Prompt:  $PROMPT_FILE"
echo ""

# Sync from remote before starting
cd "$PROJECT_DIR"
echo "Syncing from remote..."
git fetch origin 2>/dev/null || echo "Note: Could not fetch from origin"
git pull --rebase origin main 2>/dev/null || echo "Note: Could not pull from origin/main"

# Create feature branch if not already on one
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    BRANCH_NAME="ralph/$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BRANCH_NAME"
    echo "Created branch: $BRANCH_NAME"
else
    echo "On branch: $CURRENT_BRANCH"
fi

echo ""
echo "Press Enter to run, Ctrl+C to cancel..."
read

# Run Claude Code in Docker
docker run --rm -it \
    -v "$(pwd)":/workspace \
    -v "$HOME/.claude:/root/.claude" \
    -w /workspace \
    ralph-claude:latest \
    -c "claude --dangerously-skip-permissions -p \"\$(cat $PROMPT_FILE)\""

echo ""
echo "=== Iteration complete ==="
echo ""
echo "Review the changes:"
echo "  git log --oneline -5"
echo "  git diff HEAD~1"
echo "  bd ready"
echo ""
echo "Run again? Execute this script again when ready."
echo ""
echo "When done, push and create PR:"
CURRENT_BRANCH=$(git branch --show-current)
echo "  git push -u origin $CURRENT_BRANCH"
echo "  Then create PR on GitHub"
