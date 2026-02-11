#!/bin/bash
# ralph-hitl.sh - Human-in-the-Loop Ralph (single iteration)
# Use this when starting a new feature, doing risky work, or learning how Ralph behaves
set -e

# Usage: ./ralph-hitl.sh /path/to/project [prompt-file]
PROJECT_DIR="${1:-.}"
PROMPT_FILE="${2:-$PROJECT_DIR/prompt.md}"

# --- Input Validation ---

# Validate PROJECT_DIR
if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Directory not found: $PROJECT_DIR"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "ERROR: Not a git repository: $PROJECT_DIR"
    exit 1
fi

# Convert relative paths to absolute
if [[ ! "$PROJECT_DIR" = /* && "$PROJECT_DIR" != "." ]]; then
    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
fi

# Validate PROMPT_FILE exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

# Convert prompt file to absolute path
if [[ ! "$PROMPT_FILE" = /* ]]; then
    PROMPT_FILE="$(cd "$(dirname "$PROMPT_FILE")" && pwd)/$(basename "$PROMPT_FILE")"
fi

# --- Credential Validation ---
# Supports both Max subscription (OAuth via .credentials.json) and API key auth

CLAUDE_CREDENTIALS="$HOME/.claude/.credentials.json"
CLAUDE_CONFIG="$HOME/.claude/config.json"
if [ ! -f "$CLAUDE_CREDENTIALS" ] && [ ! -f "$CLAUDE_CONFIG" ] && [ -z "$CLAUDE_API_KEY" ]; then
    echo "ERROR: Claude credentials not found."
    echo "  Expected one of:"
    echo "    - $CLAUDE_CREDENTIALS (Max/Pro subscription — run 'claude login')"
    echo "    - $CLAUDE_CONFIG (API key config)"
    echo "    - CLAUDE_API_KEY environment variable"
    exit 1
fi

echo "=== RALPH HITL — Single Iteration ==="
echo "Project: $PROJECT_DIR"
echo "Prompt:  $PROMPT_FILE"
echo ""

# --- Container Cleanup Trap ---

CONTAINER_ID=""
cleanup() {
    local exit_code=$?
    if [ -n "$CONTAINER_ID" ]; then
        echo "Cleaning up container: $CONTAINER_ID"
        docker kill "$CONTAINER_ID" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

# --- Sync from Remote ---

cd "$PROJECT_DIR"
echo "Syncing from remote..."
if ! git fetch origin 2>&1; then
    echo "ERROR: Failed to fetch from origin"
    echo "Check your network connection and Git credentials."
    exit 1
fi

if ! git pull --rebase origin main 2>&1; then
    echo "WARNING: Could not pull from origin/main"
    echo "You may be on a different branch or have unpushed commits."
    echo "Continuing anyway..."
fi

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

# --- Docker Run with Security Constraints ---

DOCKER_ARGS=(
    --rm -it
    --memory=4g
    --cpus=2
    --read-only
    --tmpfs /tmp:rw,nosuid,nodev,noexec,size=1g
    --tmpfs /run:rw,nosuid,nodev,noexec,size=256m
    -v "$(pwd)":/workspace
    -v "$PROMPT_FILE":/prompt.md:ro
    -w /workspace
)

# Mount credentials securely (read-only, specific file only)
# Max/Pro subscription: mount OAuth credentials
if [ -f "$CLAUDE_CREDENTIALS" ]; then
    DOCKER_ARGS+=(-v "$CLAUDE_CREDENTIALS:/home/claude/.claude/.credentials.json:ro")
fi
# API key config file
if [ -f "$CLAUDE_CONFIG" ]; then
    DOCKER_ARGS+=(-v "$CLAUDE_CONFIG:/home/claude/.claude/config.json:ro")
fi
# API key via environment variable
if [ -n "$CLAUDE_API_KEY" ]; then
    DOCKER_ARGS+=(-e CLAUDE_API_KEY="$CLAUDE_API_KEY")
fi

docker run "${DOCKER_ARGS[@]}" \
    ralph-claude:latest \
    -c "claude --dangerously-skip-permissions -p \"\$(cat /prompt.md)\""

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
