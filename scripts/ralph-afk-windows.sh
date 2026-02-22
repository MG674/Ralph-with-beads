#!/bin/bash
# ralph-afk-windows.sh - AFK Ralph for Windows (Git Bash)
# Runs claude -p natively instead of Docker. MCP servers available.
# Use for visual phases requiring windows-mcp GUI validation.
set -eo pipefail

# Usage: ./ralph-afk-windows.sh /path/to/project <max-iterations> <prompt-file> --label <label> [--branch <name>]
PROJECT_DIR="${1:-.}"
if [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: ./ralph-afk-windows.sh <project-dir> <max-iterations> <prompt-file> --label <label> [--branch <name>]"
    echo "  max-iterations is required (e.g. 10, 15, 30)"
    echo "  prompt-file is required (path to prompt .md file)"
    echo "  --label <label>: bead label filter (e.g. omarchy, windows-mcp, all)"
    echo "  --branch <name>: continue on existing branch instead of creating new one"
    exit 1
fi
MAX_ITERATIONS="$2"
PROMPT_FILE="$3"

# Parse flags
CONTINUE_BRANCH=""
MACHINE_LABEL=""
shift 3
while [ $# -gt 0 ]; do
    case "$1" in
        --branch)
            CONTINUE_BRANCH="$2"
            shift 2
            ;;
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
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --- Input Validation ---

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Directory not found: $PROJECT_DIR"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "ERROR: Not a git repository: $PROJECT_DIR"
    exit 1
fi

# Convert relative paths to absolute (Git Bash style)
if [[ ! "$PROJECT_DIR" = /* && "$PROJECT_DIR" != "." ]]; then
    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
fi

if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || [ "$MAX_ITERATIONS" -lt 1 ]; then
    echo "ERROR: max-iterations must be a positive integer, got: $MAX_ITERATIONS"
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

if [[ ! "$PROMPT_FILE" = /* ]]; then
    PROMPT_FILE="$(cd "$(dirname "$PROMPT_FILE")" && pwd)/$(basename "$PROMPT_FILE")"
fi

# --- Credential Validation ---
# Windows: credentials come from ~/.claude/ (Max subscription) or env vars

CLAUDE_CREDENTIALS="$HOME/.claude/.credentials.json"
CLAUDE_CONFIG="$HOME/.claude/config.json"
if [ ! -f "$CLAUDE_CREDENTIALS" ] && [ ! -f "$CLAUDE_CONFIG" ] && [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "ERROR: Claude credentials not found."
    echo "  Expected one of:"
    echo "    - $CLAUDE_CREDENTIALS (Max/Pro subscription — run 'claude login')"
    echo "    - $CLAUDE_CONFIG (API key config)"
    echo "    - ANTHROPIC_API_KEY environment variable"
    echo "    - CLAUDE_CODE_OAUTH_TOKEN environment variable"
    exit 1
fi

LOG_FILE="$PROJECT_DIR/ralph-runs/ralph-$TIMESTAMP.log"
mkdir -p "$PROJECT_DIR/ralph-runs"
touch "$PROJECT_DIR/ralph-runs/git-audit.log"

echo "=== RALPH AFK (Windows) — $MAX_ITERATIONS iterations ===" | tee "$LOG_FILE"
echo "Project: $PROJECT_DIR" | tee -a "$LOG_FILE"
echo "Prompt: $PROMPT_FILE" | tee -a "$LOG_FILE"
echo "Label filter: $MACHINE_LABEL" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# --- Helper: Safe push (refuses main/master) ---

_safe_push() {
    if [[ "$BRANCH_NAME" == "main" || "$BRANCH_NAME" == "master" ]]; then
        echo "ERROR: Cannot push directly to main/master" | tee -a "$LOG_FILE"
        return 1
    fi
    git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"
}

# --- Helper: Kill stale python windows ---

_kill_stale_python_windows() {
    powershell -Command 'Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -ne ""} | Stop-Process -Force' 2>/dev/null || true
}

# --- Cleanup Trap ---

cleanup() {
    local exit_code=$?
    echo "Cleaning up stale app instances..." | tee -a "$LOG_FILE"
    _kill_stale_python_windows
    exit $exit_code
}
trap cleanup EXIT INT TERM

cd "$PROJECT_DIR"

# --- Sync from Remote ---

echo "Syncing from remote..." | tee -a "$LOG_FILE"
if ! git fetch origin 2>&1 | tee -a "$LOG_FILE"; then
    echo "ERROR: Failed to fetch from origin" | tee -a "$LOG_FILE"
    exit 1
fi

if [ -n "$CONTINUE_BRANCH" ]; then
    BRANCH_NAME="$CONTINUE_BRANCH"
    if ! git checkout "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
        echo "ERROR: Could not checkout branch: $BRANCH_NAME" | tee -a "$LOG_FILE"
        exit 1
    fi
    if ! git pull --rebase origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"; then
        echo "WARNING: Could not pull from origin/$BRANCH_NAME" | tee -a "$LOG_FILE"
        echo "Continuing with local state..." | tee -a "$LOG_FILE"
    fi
    echo "Continuing on branch: $BRANCH_NAME" | tee -a "$LOG_FILE"
else
    if ! git pull --rebase origin main 2>&1 | tee -a "$LOG_FILE"; then
        echo "WARNING: Could not pull from origin/main" | tee -a "$LOG_FILE"
        echo "Continuing anyway..." | tee -a "$LOG_FILE"
    fi
    BRANCH_NAME="ralph/afk-$TIMESTAMP"
    git checkout -b "$BRANCH_NAME"
    echo "Created branch: $BRANCH_NAME" | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# --- Advanced Thrashing Detection ---

declare -a FAIL_HISTORY=()
declare -a COMMIT_HISTORY=()

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

detect_stuck() {
    local -a history=("$@")
    if (( ${#history[@]} < 3 )); then return 1; fi

    if [[ "${history[-1]}" == "${history[-2]}" ]] && \
       [[ "${history[-2]}" == "${history[-3]}" ]]; then
        echo "identical repo state in 3 iterations"
        return 0
    fi

    return 1
}

# --- Stale Window Cleanup ---

kill_stale_app() {
    echo "Killing stale app instances..." | tee -a "$LOG_FILE"
    _kill_stale_python_windows
    sleep 2
}

# --- Main Loop ---

TIMEOUT_SECONDS=600

for ((i=1; i<=MAX_ITERATIONS; i++)); do
    echo "--- Iteration $i of $MAX_ITERATIONS ---" | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"

    # Kill any stale app windows from previous iteration
    kill_stale_app

    # Read prompt file content (prompt files are ~2-5KB; claude -p requires inline text)
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")

    # Inject machine label filter into prompt
    if [ "$MACHINE_LABEL" != "all" ]; then
        LABEL_PREAMBLE="IMPORTANT: You are running on a machine assigned label '$MACHINE_LABEL'. Only work on beads with this label. When running bd list commands, always add '-l $MACHINE_LABEL' (e.g. 'bd list --ready -l $MACHINE_LABEL --json'). If no beads with this label are available or ready, output <promise>BLOCKED</promise> and stop."
        PROMPT_CONTENT="$LABEL_PREAMBLE

$PROMPT_CONTENT"
    fi

    # Run Claude Code natively (no Docker) with timeout
    # --dangerously-skip-permissions: non-interactive
    # --model sonnet: use Sonnet for speed
    # MCP servers (windows-mcp) are available via ~/.claude.json
    ITER_LOG="$PROJECT_DIR/ralph-runs/.iter-output"
    timeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions --model sonnet -p "$PROMPT_CONTENT" \
        2>&1 | tee -a "$LOG_FILE" > "$ITER_LOG" || true

    RESULT=$(cat "$ITER_LOG")
    rm -f "$ITER_LOG"

    # Check for completion signal
    if echo "$RESULT" | grep -q "<promise>COMPLETE</promise>"; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH COMPLETE after $i iterations ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"

        echo "Pushing branch for PR..." | tee -a "$LOG_FILE"
        _safe_push

        echo "" | tee -a "$LOG_FILE"
        echo "Branch pushed. Create PR to review progress." | tee -a "$LOG_FILE"
        exit 0
    fi

    # Check for blocked signal
    if echo "$RESULT" | grep -q "<promise>BLOCKED</promise>"; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH BLOCKED at iteration $i ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"

        _safe_push || true
        exit 1
    fi

    # Extract current failure for thrashing detection
    CURRENT_FAIL=$(echo "$RESULT" | sed -n 's/.*<verify-fail>\(.*\)<\/verify-fail>.*/\1/p' | tail -1)

    if [ -n "$CURRENT_FAIL" ]; then
        FAIL_HISTORY+=("$CURRENT_FAIL")
        if (( ${#FAIL_HISTORY[@]} > 5 )); then
            FAIL_HISTORY=("${FAIL_HISTORY[@]:(-5)}")
        fi

        THRASH_MSG=$(detect_thrashing "${FAIL_HISTORY[@]}") || true
        if [ -n "$THRASH_MSG" ]; then
            echo "" | tee -a "$LOG_FILE"
            echo "=== RALPH THRASHING — $THRASH_MSG ===" | tee -a "$LOG_FILE"
            echo "Failure history: ${FAIL_HISTORY[*]}" | tee -a "$LOG_FILE"
            echo "Finished: $(date)" | tee -a "$LOG_FILE"

            _safe_push || true
            exit 1
        fi
    fi

    # Detect stuck iterations: same repo state (commit + working tree) 3 times
    # Hash both HEAD and uncommitted diff so we catch Ralph re-doing identical
    # uncommitted work without ever committing (the ergo-537 pattern).
    COMMIT_SHA=$(cd "$PROJECT_DIR" && git rev-parse HEAD 2>/dev/null || echo "unknown")
    DIFF_HASH=$(cd "$PROJECT_DIR" && git diff HEAD 2>/dev/null | md5sum | cut -d' ' -f1)
    CURRENT_STATE="${COMMIT_SHA}:${DIFF_HASH}"
    COMMIT_HISTORY+=("$CURRENT_STATE")
    if (( ${#COMMIT_HISTORY[@]} > 5 )); then
        COMMIT_HISTORY=("${COMMIT_HISTORY[@]:(-5)}")
    fi

    STUCK_MSG=$(detect_stuck "${COMMIT_HISTORY[@]}") || true
    if [ -n "$STUCK_MSG" ]; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH STUCK — $STUCK_MSG ===" | tee -a "$LOG_FILE"
        echo "State: ${COMMIT_HISTORY[-1]}" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"
        _safe_push || true
        exit 1
    fi

    # Show what changed this iteration
    CHANGED=$(git diff --stat HEAD 2>/dev/null || true)
    LAST_COMMIT=$(git log --oneline -1 2>/dev/null || true)
    if [ -n "$CHANGED" ]; then
        echo "Uncommitted changes:" | tee -a "$LOG_FILE"
        echo "$CHANGED" | tee -a "$LOG_FILE"
    fi
    echo "Last commit: $LAST_COMMIT" | tee -a "$LOG_FILE"

    echo "Iteration $i complete." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    # Brief pause between iterations
    sleep 5
done

echo "=== RALPH FINISHED — max iterations ($MAX_ITERATIONS) reached ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"

_safe_push || true
echo "Branch pushed. Create PR to review progress." | tee -a "$LOG_FILE"
