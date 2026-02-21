#!/bin/bash
# ralph-hitl.sh - Human-in-the-Loop Ralph (single iteration)
# Use this when starting a new feature, doing risky work, or learning how Ralph behaves
set -e

# --- Load OAuth token from file if not in environment ---
# Survives SSH disconnects without needing to re-source .bashrc
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] && [ -f "$HOME/.claude-oauth-token" ]; then
    CLAUDE_CODE_OAUTH_TOKEN=$(cat "$HOME/.claude-oauth-token")
    export CLAUDE_CODE_OAUTH_TOKEN
fi

# Usage: ./ralph-hitl.sh /path/to/project <prompt-file> --label <label>
PROJECT_DIR="${1:-.}"
if [ -z "$2" ]; then
    echo "Usage: ./ralph-hitl.sh <project-dir> <prompt-file> --label <label>"
    echo "  prompt-file is required (path to prompt .md file)"
    echo "  --label <label>: bead label filter (e.g. omarchy, windows-mcp, all)"
    exit 1
fi
PROMPT_FILE="$2"

# Parse flags
MACHINE_LABEL=""
shift 2
while [ $# -gt 0 ]; do
    case "$1" in
        --label)
            MACHINE_LABEL="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Validate --label is provided
if [ -z "$MACHINE_LABEL" ]; then
    echo "ERROR: --label is required (e.g. --label omarchy, --label windows-mcp, --label all)"
    exit 1
fi

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
# Supports OAuth token (preferred), Max subscription, and API key auth

CLAUDE_CREDENTIALS="$HOME/.claude/.credentials.json"
CLAUDE_CONFIG="$HOME/.claude/config.json"
if [ ! -f "$CLAUDE_CREDENTIALS" ] && [ ! -f "$CLAUDE_CONFIG" ] && [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "ERROR: Claude credentials not found."
    echo "  Expected one of:"
    echo "    - CLAUDE_CODE_OAUTH_TOKEN environment variable (run 'claude setup-token')"
    echo "    - $CLAUDE_CREDENTIALS (Max/Pro subscription — run 'claude login')"
    echo "    - $CLAUDE_CONFIG (API key config)"
    echo "    - ANTHROPIC_API_KEY environment variable"
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

# Persist git audit log on host (survives container --rm)
mkdir -p "$PROJECT_DIR/ralph-runs"
chmod 700 "$PROJECT_DIR/ralph-runs"
touch "$PROJECT_DIR/ralph-runs/git-audit.log"

DOCKER_ARGS=(
    --rm -it
    --memory=4g
    --cpus=2
    --tmpfs "/tmp:rw,nosuid,nodev,size=1g"
    --tmpfs "/run:rw,nosuid,nodev,size=256m"
    -v "$(pwd)":/workspace
    -v "$PROMPT_FILE":/prompt.md:ro
    -v "$PROJECT_DIR/ralph-runs/git-audit.log":/var/log/git-commands.log
    -w /workspace
)

# Auth: OAuth token (preferred for Docker)
if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    DOCKER_ARGS+=(-e CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN")
fi
# Mount credentials securely (read-only, fallback)
# Max/Pro subscription: mount OAuth credentials
if [ -f "$CLAUDE_CREDENTIALS" ]; then
    DOCKER_ARGS+=(-v "$CLAUDE_CREDENTIALS:/home/node/.claude/.credentials.json:ro")
fi
# API key config file
if [ -f "$CLAUDE_CONFIG" ]; then
    DOCKER_ARGS+=(-v "$CLAUDE_CONFIG:/home/node/.claude/config.json:ro")
fi
# API key via environment variable
if [ -n "$ANTHROPIC_API_KEY" ]; then
    DOCKER_ARGS+=(-e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY")
fi

# --- Label Filter Preamble ---

LABEL_PREAMBLE=""
if [ "$MACHINE_LABEL" != "all" ]; then
    LABEL_PREAMBLE="IMPORTANT: You are running on a machine assigned label '$MACHINE_LABEL'. Only work on beads with this label. When running bd list commands, always add '-l $MACHINE_LABEL' (e.g. 'bd list --ready -l $MACHINE_LABEL --json'). If no beads with this label are available or ready, output <promise>BLOCKED</promise> and stop."
fi

if [ -n "$LABEL_PREAMBLE" ]; then
    DOCKER_ARGS+=(-e LABEL_PREAMBLE="$LABEL_PREAMBLE")
fi

docker run "${DOCKER_ARGS[@]}" \
    ralph-claude:latest \
    -c "claude --dangerously-skip-permissions --model sonnet -p \"\${LABEL_PREAMBLE:+\$LABEL_PREAMBLE\$'\\n\\n'}IMPORTANT: Read docs/guardrails.md FIRST. Guardrails ALWAYS take precedence over docs/lessons-learned.md. If a fix requires violating a guardrail, STOP and document the conflict.\$(echo && cat /prompt.md)\""

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
