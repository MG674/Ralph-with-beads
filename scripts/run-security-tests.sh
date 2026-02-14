#!/bin/bash
set -e

# =============================================================================
# run-security-tests.sh — Automated security test suite for Ralph-with-beads
#
# Validates security hardening: git wrapper, non-root user, input validation,
# timeouts, and branch protection.
#
# Usage: ./scripts/run-security-tests.sh
# Prerequisites: Docker must be installed and running
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_IMAGE="ralph-claude-test:latest"

bold()  { printf '\033[1m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }
red()   { printf '\033[31m%s\033[0m' "$1"; }

# Run a command inside the Docker container (entrypoint is /bin/bash)
run_in_container() {
    docker run --rm "$DOCKER_IMAGE" -c "$1"
}

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local name="$1"
    local expected="$2"
    shift 2

    echo -n "  Testing: $name ... "

    output=$("$@" 2>&1) || true

    if [[ "$output" == *"$expected"* ]]; then
        echo "$(green 'PASS')"
        ((++TESTS_PASSED))
    else
        echo "$(red 'FAIL')"
        echo "    Expected to contain: $expected"
        echo "    Got: $(echo "$output" | head -3)"
        ((++TESTS_FAILED))
    fi
}

run_test_exit_code() {
    local name="$1"
    local expected_code="$2"
    shift 2

    echo -n "  Testing: $name ... "

    "$@" > /dev/null 2>&1
    actual_code=$?

    if [ "$actual_code" -eq "$expected_code" ]; then
        echo "$(green 'PASS')"
        ((++TESTS_PASSED))
    else
        echo "$(red 'FAIL')"
        echo "    Expected exit code: $expected_code, got: $actual_code"
        ((++TESTS_FAILED))
    fi
}

echo ""
echo "$(bold '=== Ralph-with-beads Security Test Suite ===')"
echo ""

# --- Build Docker Image ---

echo "$(bold '1. Building Docker image...')"
if ! docker build -t "$DOCKER_IMAGE" "$RALPH_DIR/docker/" > /dev/null 2>&1; then
    echo "  $(red 'FAIL') Docker build failed. Fix Dockerfile first."
    exit 1
fi
echo "  $(green 'OK') Image built"
echo ""

# --- Docker Container Security Tests ---

echo "$(bold '2. Container Security Tests')"

run_test "Non-root user" "node" \
    run_in_container "whoami"

run_test "Git wrapper at /usr/local/bin/git" "/usr/local/bin/git" \
    run_in_container "which git"

run_test "Git wrapper blocks force-push" "Force push is not allowed" \
    run_in_container "/usr/local/bin/git push -f origin HEAD"

run_test "Git wrapper blocks main push" "Cannot push directly to main" \
    run_in_container "/usr/local/bin/git push origin main"

run_test "Git wrapper blocks branch deletion" "Branch deletion is not allowed" \
    run_in_container "/usr/local/bin/git branch -D some-branch"

run_test "Git wrapper blocks hard reset" "Hard reset is not allowed" \
    run_in_container "/usr/local/bin/git reset --hard HEAD"

echo ""
echo "$(bold '2b. Git Command Interception Tests (PATH-based)')"

run_test "git push -f intercepted via PATH" "Force push is not allowed" \
    run_in_container "git push -f origin HEAD"

run_test "git push main intercepted via PATH" "Cannot push directly to main" \
    run_in_container "git push origin main"

run_test "git branch -D intercepted via PATH" "Branch deletion is not allowed" \
    run_in_container "git branch -D some-branch"

run_test "git reset --hard intercepted via PATH" "Hard reset is not allowed" \
    run_in_container "git reset --hard HEAD"

run_test "Safe git command passes through" "git version" \
    run_in_container "git --version"

echo ""

# --- Timeout Test ---

echo "$(bold '3. Timeout Test')"

run_test_exit_code "Timeout kills hung process (5s)" 124 \
    timeout 5 run_in_container "sleep 60"

echo ""

# --- Script Input Validation Tests ---

echo "$(bold '4. Script Input Validation Tests')"

# Create temp dir for testing (not a git repo)
TEMP_DIR=$(mktemp -d)

run_test "ralph-hitl.sh rejects non-existent directory" "Directory not found" \
    bash "$RALPH_DIR/scripts/ralph-hitl.sh" "/nonexistent/path/12345"

run_test "ralph-hitl.sh rejects non-git directory" "Not a git repository" \
    bash "$RALPH_DIR/scripts/ralph-hitl.sh" "$TEMP_DIR"

run_test "ralph-afk.sh rejects non-existent directory" "Directory not found" \
    bash "$RALPH_DIR/scripts/ralph-afk.sh" "/nonexistent/path/12345" 5

run_test "ralph-afk.sh rejects non-git directory" "Not a git repository" \
    bash "$RALPH_DIR/scripts/ralph-afk.sh" "$TEMP_DIR" 5

run_test "ralph-hitl.sh rejects missing prompt file" "Prompt file not found" \
    bash "$RALPH_DIR/scripts/ralph-hitl.sh" "$RALPH_DIR" "/nonexistent/prompt.md"

run_test "ralph-afk.sh rejects invalid max-iterations" "must be a positive integer" \
    bash "$RALPH_DIR/scripts/ralph-afk.sh" "$RALPH_DIR" "abc"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""

# --- Results ---

echo "$(bold '=== Test Results ===')"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "$(green 'All security tests passed!')"
    exit 0
else
    echo "$(red 'Some tests failed — review output above.')"
    exit 1
fi
