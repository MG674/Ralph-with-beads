#!/bin/bash
# verify.sh - Full quality verification script for JavaScript/React
# All checks must pass before closing a task or committing
set -e

echo "=========================================="
echo "  QUALITY VERIFICATION"
echo "=========================================="
echo ""

echo "=== LINT (eslint) ==="
npx eslint .
echo "✓ Lint passed"
echo ""

echo "=== FORMAT (prettier) ==="
npx prettier --check .
echo "✓ Format passed"
echo ""

echo "=== TYPE CHECK (typescript) ==="
npx tsc --noEmit
echo "✓ Type check passed"
echo ""

echo "=== TESTS (jest) ==="
npx jest --ci --coverage --coverageThreshold='{"global":{"branches":80,"functions":80,"lines":80}}'
echo "✓ Tests passed with coverage >= 80%"
echo ""

echo "=========================================="
echo "  ALL CHECKS PASSED ✓"
echo "=========================================="
