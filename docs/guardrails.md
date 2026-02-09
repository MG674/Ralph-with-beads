# Guardrails

Rules learned from failures. Read this at the start of EVERY task.

> "Ralph is very good at making playgrounds, but he comes home bruised because he fell off the slide, so one then tunes Ralph by adding a sign next to the slide." — Geoffrey Huntley

---

## CRITICAL (Always Follow)

- NEVER skip running verify.sh before committing
- NEVER commit with failing tests
- NEVER skip type checking even if tests pass
- ALWAYS validate input data before processing
- ALWAYS handle errors explicitly (no silent failures)

## Git

- ALWAYS commit after completing a task (before starting the next)
- ALWAYS use the format `[BD-XXX] Brief description` for commit messages
- NEVER commit directly to main/master

## Testing

- ALWAYS write the test BEFORE the implementation (TDD)
- ALWAYS run the test and confirm it FAILS before implementing
- NEVER mock what you don't own (mock boundaries, not internals)

## Code Quality

- ALWAYS run `black .` before committing (Python)
- ALWAYS run `prettier --write .` before committing (JavaScript)
- NEVER ignore linter warnings without documenting why

---

## Project-Specific Guardrails

<!-- Add guardrails specific to your project below -->
<!-- Format: Brief rule + context/reason -->

<!-- Example:
## CSV Processing
- CSV parser silently drops rows with missing timestamps — always validate row count after parsing
- Column headers may have trailing spaces — always strip() before matching
-->
