#!/bin/bash
# ralph-helpers.sh - Shared helper functions for Ralph AFK scripts
# Source this file from ralph-afk.sh and ralph-afk-windows.sh
#
# Required variables (must be set before sourcing):
#   BRANCH_NAME - current git branch
#   LOG_FILE    - path to log file

# --- Safe push (refuses main/master) ---

_safe_push() {
    if [[ "$BRANCH_NAME" == "main" || "$BRANCH_NAME" == "master" ]]; then
        echo "ERROR: Cannot push directly to main/master" | tee -a "$LOG_FILE" >&2
        return 1
    fi
    git push -u origin "$BRANCH_NAME" 2>&1 | tee -a "$LOG_FILE"
}

# --- Advanced Thrashing Detection ---
# Detects repeating failure patterns in a sliding window of results.
# Usage: THRASH_MSG=$(detect_thrashing "${FAIL_HISTORY[@]}") || true

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
