#!/bin/bash
# ralph-afk.sh - AFK Ralph (autonomous loop, N iterations)
# Use this once the foundation is solid and tasks are well-defined
set -e

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
LOG_FILE="$PROJECT_DIR/ralph-runs/ralph-$TIMESTAMP.log"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: prompt.md not found at $PROMPT_FILE"
    exit 1
fi

mkdir -p "$PROJECT_DIR/ralph-runs"

echo "=== RALPH AFK — $MAX_ITERATIONS iterations ===" | tee "$LOG_FILE"
echo "Project: $PROJECT_DIR" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

cd "$PROJECT_DIR"

# Sync from remote before starting
echo "Syncing from remote..." | tee -a "$LOG_FILE"
git fetch origin 2>/dev/null || echo "Note: Could not fetch from origin" | tee -a "$LOG_FILE"
git pull --rebase origin main 2>/dev/null || echo "Note: Could not pull from origin/main" | tee -a "$LOG_FILE"

# Create feature branch
BRANCH_NAME="ralph/afk-$TIMESTAMP"
git checkout -b "$BRANCH_NAME"
echo "Created branch: $BRANCH_NAME" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

PREV_FAIL=""

for ((i=1; i<=$MAX_ITERATIONS; i++)); do
    echo "--- Iteration $i of $MAX_ITERATIONS ---" | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"

    # Run Claude Code in Docker
    RESULT=$(docker run --rm \
        -v "$(pwd)":/workspace \
        -v "$HOME/.claude:/root/.claude" \
        -w /workspace \
        ralph-claude:latest \
        -c "claude --dangerously-skip-permissions -p '\$(cat $PROMPT_FILE)'" \
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
        if [ -f "$(dirname $0)/notify.sh" ]; then
            bash "$(dirname $0)/notify.sh" "Ralph COMPLETE on $(basename $PROJECT_DIR) after $i iterations"
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

        if [ -f "$(dirname $0)/notify.sh" ]; then
            bash "$(dirname $0)/notify.sh" "Ralph BLOCKED on $(basename $PROJECT_DIR) at iteration $i"
        fi
        exit 1
    fi

    # Check for thrashing (same verify failure in consecutive iterations)
    CURRENT_FAIL=$(echo "$RESULT" | grep -oP '(?<=<verify-fail>).*(?=</verify-fail>)' | tail -1)

    if [ -n "$CURRENT_FAIL" ] && [ "$CURRENT_FAIL" = "$PREV_FAIL" ]; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH THRASHING — same failure in 2 consecutive iterations ===" | tee -a "$LOG_FILE"
        echo "Failure: $CURRENT_FAIL" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"

        # Push whatever progress was made
        git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE" || true

        if [ -f "$(dirname $0)/notify.sh" ]; then
            bash "$(dirname $0)/notify.sh" "Ralph THRASHING on $(basename $PROJECT_DIR) at iteration $i: $CURRENT_FAIL"
        fi
        exit 1
    fi
    PREV_FAIL="${CURRENT_FAIL:-}"

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

if [ -f "$(dirname $0)/notify.sh" ]; then
    bash "$(dirname $0)/notify.sh" "Ralph finished on $(basename $PROJECT_DIR) — max iterations reached"
fi
