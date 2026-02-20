# CLAUDE.md — [PROJECT_NAME]

## Project Overview
[Brief description of what this project does]

## Tech Stack
- Language: Python >=3.11
- Testing: pytest
- Linting: ruff
- Formatting: black
- Type checking: mypy

## Quick Reference

### Commands
- `bash verify.sh` — Run all quality checks (MUST pass before committing)
- `bd ready` — Find next task to work on
- `bd close <id> --reason "message"` — Complete a task
- `pytest` — Run tests
- `ruff check .` — Lint
- `black .` — Format

### Quality Standards
- All code must have tests (target 80%+ coverage)
- All code must pass verify.sh
- Type hints on all function signatures
- Docstrings on public functions

## Documentation (Read When Relevant)

| Document | When to Read |
|----------|--------------|
| docs/prd.md | Requirements, acceptance criteria, technical approach |
| docs/guardrails.md | ALWAYS read at start of each task |
| docs/lessons-learned.md | When working on related areas |
| docs/architecture.md | When making structural changes |
| coding-standards.md | When refactoring or reviewing style |

## Git Workflow
- Work on branch: ralph/<feature-name>
- Commit message format: `[BD-XXX] Brief description`
- All commits must pass verify.sh
- NEVER commit directly to main/master

## Beads Workflow
1. `bd ready` — find next task
2. `bd update <id> in_progress` — claim it
3. Read the bead description — identify every acceptance criterion
4. Read the key files listed in the bead
5. Implement with TDD (test first, then code, then refactor)
6. `bash verify.sh` — must pass before closing
7. Self-audit: check every acceptance criterion is met
8. `bd close <id> --reason "criterion-by-criterion close reason"` — complete it
9. Commit immediately
