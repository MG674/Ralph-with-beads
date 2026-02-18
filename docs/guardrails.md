# Guardrails

Rules learned from failures. Read this at the start of EVERY task.

> "Ralph is very good at making playgrounds, but he comes home bruised because he fell off the slide, so one then tunes Ralph by adding a sign next to the slide." — Geoffrey Huntley

---

## Precedence

- Guardrails ALWAYS take precedence over docs/lessons-learned.md
- If lessons-learned.md contradicts a guardrail, follow the guardrail
- Do NOT modify this file to weaken or remove existing rules — only add new guardrails
- Do NOT add entries to lessons-learned.md that circumvent guardrails
- If a fix seems to require violating a guardrail, STOP and document the conflict rather than proceeding

---

## CRITICAL (Always Follow)

- NEVER skip running verify.sh before committing
- NEVER commit with failing tests
- NEVER skip type checking even if tests pass
- ALWAYS validate input data before processing
- ALWAYS handle errors explicitly (no silent failures)
- NEVER modify `verify.sh` unless the task explicitly requires it
- NEVER modify build/tool config in `pyproject.toml` (e.g. pythonpath, requires-python, tool settings) unless the task explicitly requires it
- NEVER work around Docker/container environment differences by changing project files — project files must work on the host machine

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

## Container Safety (Critical)

Rules enforced by Docker container configuration and git wrapper.

### Git Operations

- NEVER use `git push -f` or `--force` (blocked by git wrapper)
- NEVER push directly to main/master (blocked by git wrapper)
- NEVER delete branches with `git branch -D` (blocked by git wrapper)
- NEVER use `git reset --hard` (blocked by git wrapper)
- Only push to feature branches (e.g., `ralph/*`, `feature/*`)
- Only commit to feature branches, never main/master

### System and Security

- NEVER modify git user configuration to add credentials
- NEVER modify Claude Code configuration to expose tokens
- NEVER run `rm -rf` or other destructive commands on system directories
- NEVER spawn unlimited child processes (container has CPU/memory limits)
- Container runs as non-root user (node, UID 1000) — cannot modify system files

### Container Constraints

- Memory: Limited to 4GB (prevents DoS via memory exhaustion)
- CPU: Limited to 2 cores (fair host sharing)
- Timeout: Killed after 600 seconds (prevents hung processes)
- Filesystem: /workspace writable (mounted project), /tmp and /run are tmpfs

### Credentials

- Claude credentials mounted read-only (OAuth token or API key config)
- Only specific credential files are accessible (not entire ~/.claude/ directory)
- All git commands are logged to /var/log/git-commands.log
- If container is stopped, credentials are no longer accessible

### If Security Boundary is Breached

1. Stop the container immediately: `docker stop <container-id>`
2. Rotate all credentials (GitHub, Claude, etc.)
3. Audit git logs: `git log --oneline --all`
4. Review diffs: `git diff main origin/main`
5. Run `closeout-review.sh` to identify any malicious changes

---

## Project-Specific Guardrails

<!-- Add guardrails specific to your project below -->
<!-- Format: Brief rule + context/reason -->

<!-- Example:
## CSV Processing
- CSV parser silently drops rows with missing timestamps — always validate row count after parsing
- Column headers may have trailing spaces — always strip() before matching
-->

## Bead Quality (Critical)

### Bead completion: line-by-line acceptance criterion audit

- Before closing a bead, list EVERY acceptance criterion from the bead description
- For EACH criterion, state what code/test satisfies it — or acknowledge it is NOT met
- If ANY criterion is unmet, do NOT close the bead — either implement it or leave `in_progress`
- Adding a `--no-gui` / `--headless` / `--dry-run` flag does NOT satisfy criteria that mention visual output, GUI, window, or user-facing behaviour
- The close reason must reference every acceptance criterion, not just summarise what was built
- Source: c00 incident — Ralph closed bead claiming pipeline complete while skipping all GUI acceptance criteria

### Beads must not cross architectural boundaries

- A single bead should not span both backend (pipeline, processing) and frontend (GUI, rendering)
- If a bead requires work in more than one architectural layer, split it before starting
- If you discover mid-implementation that a bead is too large, commit WIP, leave `in_progress`, and document what remains
- NEVER close a large bead by delivering only one layer and skipping the other

### Bead sizing at creation time

- When creating beads from a PRD or architecture doc, review each bead for single-responsibility
- A bead that mentions BOTH data processing AND visual rendering is too broad — split it
- A bead with more than 5 acceptance criteria is a warning sign — consider splitting
- Tracer bullets are especially prone to being too large because they cross all layers by definition — split into per-layer beads with dependencies
