#!/bin/bash
# verify.sh - Full quality verification script
# All checks must pass before closing a task or committing
set -e

# Use venv tools directly if present (avoids sourcing activate script)
if [ -d ".venv" ]; then
    PYTHON_PREFIX=".venv/bin/"
else
    PYTHON_PREFIX=""
fi

echo "=========================================="
echo "  QUALITY VERIFICATION"
echo "=========================================="
echo ""

echo "=== LINT (ruff) ==="
${PYTHON_PREFIX}ruff check .
echo "✓ Lint passed"
echo ""

echo "=== FORMAT (black) ==="
${PYTHON_PREFIX}black --check .
echo "✓ Format passed"
echo ""

echo "=== TYPE CHECK (mypy) ==="
${PYTHON_PREFIX}mypy . --ignore-missing-imports
echo "✓ Type check passed"
echo ""

echo "=== TESTS + COVERAGE (pytest) ==="
${PYTHON_PREFIX}pytest --tb=short -q --cov=src --cov-fail-under=80 --cov-report=term-missing
echo "✓ Tests passed, coverage >= 80%"
echo ""

echo "=========================================="
echo "  ALL CHECKS PASSED ✓"
echo "=========================================="
