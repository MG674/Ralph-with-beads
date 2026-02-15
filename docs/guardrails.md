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
