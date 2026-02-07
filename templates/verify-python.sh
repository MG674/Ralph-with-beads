#!/bin/bash
# verify.sh - Full quality verification script
# All checks must pass before closing a task or committing
set -e

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

echo "=== TESTS (pytest) ==="
pytest --tb=short -q
echo "✓ Tests passed"
echo ""

echo "=== COVERAGE ==="
pytest --cov=src --cov-fail-under=80 --cov-report=term-missing -q
echo "✓ Coverage >= 80%"
echo ""

echo "=========================================="
echo "  ALL CHECKS PASSED ✓"
echo "=========================================="
