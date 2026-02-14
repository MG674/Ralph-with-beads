#!/bin/bash
# ralph-afk.sh - AFK Ralph (autonomous loop, N iterations)
# Use this once the foundation is solid and tasks are well-defined
set -e

# --- Load OAuth token from file if not in environment ---
# Survives SSH disconnects without needing to re-source .bashrc
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] && [ -f "$HOME/.claude-oauth-token" ]; then
    CLAUDE_CODE_OAUTH_TOKEN=$(cat "$HOME/.claude-oauth-token")
    export CLAUDE_CODE_OAUTH_TOKEN
fi

# Usage: ./ralph-afk.sh /path/to/project <max-iterations> [prompt-file]
PROJECT_DIR="${1:-.}"
if [ -z "$2" ]; then
    echo "Usage: ./ralph-afk.sh <project-dir> <max-iterations> [prompt-file]"
    echo "  max-iterations is required (e.g. 10, 15, 30)"
    exit 1
fi
MAX_ITERATIONS="$2"
PROMPT_FILE="${3:-$PROJECT_DIR/prompt.md}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

# Validate max-iterations is a positive integer
if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || [ "$MAX_ITERATIONS" -lt 1 ]; then
    echo "ERROR: max-iterations must be a positive integer, got: $MAX_ITERATIONS"
    exit 1
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

LOG_FILE="$PROJECT_DIR/ralph-runs/ralph-$TIMESTAMP.log"
mkdir -p "$PROJECT_DIR/ralph-runs"
chmod 700 "$PROJECT_DIR/ralph-runs"

echo "=== RALPH AFK — $MAX_ITERATIONS iterations ===" | tee "$LOG_FILE"
echo "Project: $PROJECT_DIR" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# --- Container Cleanup Trap ---

CONTAINER_ID=""
cleanup() {
    local exit_code=$?
    if [ -n "$CONTAINER_ID" ]; then
        echo "Cleaning up container: $CONTAINER_ID" | tee -a "$LOG_FILE"
        docker kill "$CONTAINER_ID" 2>/dev/null || true
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

cd "$PROJECT_DIR"

# --- Sync from Remote ---

echo "Syncing from remote..." | tee -a "$LOG_FILE"
if ! git fetch origin 2>&1 | tee -a "$LOG_FILE"; then
    echo "ERROR: Failed to fetch from origin" | tee -a "$LOG_FILE"
    echo "Check your network connection and Git credentials." | tee -a "$LOG_FILE"
    exit 1
fi

if ! git pull --rebase origin main 2>&1 | tee -a "$LOG_FILE"; then
    echo "WARNING: Could not pull from origin/main" | tee -a "$LOG_FILE"
    echo "You may be on a different branch or have unpushed commits." | tee -a "$LOG_FILE"
    echo "Continuing anyway..." | tee -a "$LOG_FILE"
fi

# Create feature branch
BRANCH_NAME="ralph/afk-$TIMESTAMP"
git checkout -b "$BRANCH_NAME"
echo "Created branch: $BRANCH_NAME" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# --- Advanced Thrashing Detection ---

declare -a FAIL_HISTORY=()

detect_thrashing() {
    local -a history=("$@")
    local len=${#history[@]}

    if (( len < 3 )); then return 1; fi

    # Pattern A: Same failure 3 consecutive times
    if [[ "${history[-1]}" == "${history[-2]}" ]] && \
       [[ "${history[-2]}" == "${history[-3]}" ]]; then
        echo "Same failure in 3 consecutive iterations"
        return 0
    fi

    # Pattern B: Alternating failures (A->B->A->B)
    if (( len >= 4 )); then
        if [[ "${history[-1]}" == "${history[-3]}" ]] && \
           [[ "${history[-2]}" == "${history[-4]}" ]] && \
           [[ "${history[-1]}" != "${history[-2]}" ]]; then
            echo "Alternating failure pattern detected"
            return 0
        fi
    fi

    return 1
}

# --- Docker Args ---

DOCKER_ARGS=(
    --rm
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

# --- Main Loop ---

for ((i=1; i<=MAX_ITERATIONS; i++)); do
    echo "--- Iteration $i of $MAX_ITERATIONS ---" | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"

    # Run Claude Code in Docker with timeout
    RESULT=$(timeout 600 docker run "${DOCKER_ARGS[@]}" \
        ralph-claude:latest \
        -c "claude --dangerously-skip-permissions --model sonnet -p \"\$(cat /prompt.md)\"" \
        2>&1) || true

    echo "$RESULT" >> "$LOG_FILE"

    # Check for completion signal
    if echo "$RESULT" | grep -q "<promise>COMPLETE</promise>"; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH COMPLETE after $i iterations ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"

        # Push branch for PR
        echo "Pushing branch for PR..." | tee -a "$LOG_FILE"
        git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"

        echo "" | tee -a "$LOG_FILE"
        echo "Create PR at: https://github.com/[org]/[repo]/pull/new/$BRANCH_NAME" | tee -a "$LOG_FILE"

        # Send notification if script exists
        if [ -f "$(dirname "$0")/notify.sh" ]; then
            bash "$(dirname "$0")/notify.sh" "Ralph COMPLETE on $(basename "$PROJECT_DIR") after $i iterations"
        fi
        exit 0
    fi

    # Check for blocked signal
    if echo "$RESULT" | grep -q "<promise>BLOCKED</promise>"; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH BLOCKED at iteration $i ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"

        # Push whatever progress was made
        git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE" || true

        if [ -f "$(dirname "$0")/notify.sh" ]; then
            bash "$(dirname "$0")/notify.sh" "Ralph BLOCKED on $(basename "$PROJECT_DIR") at iteration $i"
        fi
        exit 1
    fi

    # Extract current failure for thrashing detection
    CURRENT_FAIL=$(echo "$RESULT" | grep -oP '(?<=<verify-fail>).*(?=</verify-fail>)' | tail -1)

    # Track failure history (5-iteration sliding window)
    if [ -n "$CURRENT_FAIL" ]; then
        FAIL_HISTORY+=("$CURRENT_FAIL")
        if (( ${#FAIL_HISTORY[@]} > 5 )); then
            FAIL_HISTORY=("${FAIL_HISTORY[@]:(-5)}")
        fi

        # Check for repeating patterns
        THRASH_MSG=$(detect_thrashing "${FAIL_HISTORY[@]}")
        if [ $? -eq 0 ]; then
            echo "" | tee -a "$LOG_FILE"
            echo "=== RALPH THRASHING — $THRASH_MSG ===" | tee -a "$LOG_FILE"
            echo "Failure history: ${FAIL_HISTORY[*]}" | tee -a "$LOG_FILE"
            echo "Finished: $(date)" | tee -a "$LOG_FILE"

            # Push whatever progress was made
            git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE" || true

            if [ -f "$(dirname "$0")/notify.sh" ]; then
                bash "$(dirname "$0")/notify.sh" "Ralph THRASHING on $(basename "$PROJECT_DIR") at iteration $i: $THRASH_MSG"
            fi
            exit 1
        fi
    fi

    echo "Iteration $i complete." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    # Brief pause between iterations
    sleep 5
done

echo "=== RALPH FINISHED — max iterations ($MAX_ITERATIONS) reached ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"

# Push whatever progress was made
git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE" || true
echo "Branch pushed. Create PR to review progress." | tee -a "$LOG_FILE"

if [ -f "$(dirname "$0")/notify.sh" ]; then
    bash "$(dirname "$0")/notify.sh" "Ralph finished on $(basename "$PROJECT_DIR") — max iterations reached"
fi
