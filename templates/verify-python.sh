#!/bin/bash
# verify.sh - Full quality verification script
# All checks must pass before closing a task or committing
set -e

# Activate venv if present
if [ -d ".venv" ]; then
    set +e; source .venv/bin/activate
    rc=$?
    set -e
    if [ $rc -ne 0 ] && [ $rc -ne 1 ]; then
        echo "ERROR: venv activation failed with exit code $rc"
        exit 1
    fi
fi

echo "=========================================="
echo "  QUALITY VERIFICATION"
echo "=========================================="
echo ""

echo "=== LINT (ruff) ==="
ruff check .
echo "✓ Lint passed"
echo ""

echo "=== FORMAT (black) ==="
black --check .
echo "✓ Format passed"
echo ""

echo "=== TYPE CHECK (mypy) ==="
mypy . --ignore-missing-imports
echo "✓ Type check passed"
echo ""

echo "=== TESTS + COVERAGE (pytest) ==="
pytest --tb=short -q --cov=src --cov-fail-under=80 --cov-report=term-missing
echo "✓ Tests passed, coverage >= 80%"
echo ""

echo "=========================================="
echo "  ALL CHECKS PASSED ✓"
echo "=========================================="
