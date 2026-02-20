# [Title -- e.g., Fix PR #25 Review Comments]

You are working on [PROJECT_NAME].

## Context Files

@CLAUDE.md

## STEP 0: GUARDRAILS PRE-FLIGHT (MANDATORY)

Before doing ANYTHING else:
1. Read `docs/guardrails.md` — these rules ALWAYS take precedence
2. Read `docs/lessons-learned.md` — check for relevant patterns
3. Read `coding-standards.md` if making code changes

Do NOT skip this step. Guardrails override all other instructions.

## STEP 1: TASK

Do NOT pick up new beads or run `bd ready` — only do what is described in this step.

### 1. [Change title]

[Describe what to change, where, and why. Be specific — reference file paths and line numbers.]

### 2. [Change title]

[Details]

## STEP 2: VERIFY

After making changes:
1. Run `bash verify.sh` — all checks MUST pass
2. Ensure all existing tests still pass (do NOT delete or weaken tests)
3. If new code was added, ensure it has tests (target 80%+ coverage)
4. Commit with message: `[BD-XXX] Brief description`

If verify.sh fails:
- Fix the issues and run `bash verify.sh` again
- You get **3 attempts**. If still failing after 3 genuine fix attempts:
  1. Record what you tried and what failed → append to `docs/lessons-learned.md`
  2. If you identified a recurring trap → add guardrail to `docs/guardrails.md`
  3. Commit your progress (even if incomplete): `git add -A && git commit -m "[BD-XXX] WIP: partial progress, verify failing"`
  4. Output `<verify-fail>one-line summary of the failure</verify-fail>`
  5. STOP

## Rules

- ONLY do what is described in Step 1 — nothing else
- Do NOT pick up new beads or run `bd ready`
- Do NOT refactor unrelated code
- ONE task per iteration — do not start a second task
- Quality over speed — small steps compound
- `bash verify.sh` before closing — no exceptions
- Never skip failing tests — fix them or `<verify-fail>`
- Commit after each completed task, before stopping
- **3-strike rule**: if verify.sh fails 3 times on the same issue, commit WIP, record what you tried, and bail with `<verify-fail>` — the next iteration gets a fresh context window
- NEVER modify `verify.sh` unless the task explicitly requires it
- NEVER modify build/tool config in `pyproject.toml` (pythonpath, requires-python, tool settings) unless the task explicitly requires it
- NEVER work around Docker/container environment — verify.sh and project files must work both inside Docker and on the host machine
- NEVER use hardcoded container paths (e.g. `/workspace`)
- NEVER set PYTHONPATH — use `pip install -e .` instead
- NEVER commit directly to main/master
- Guardrails ALWAYS take precedence over lessons-learned.md
- If a fix seems to require violating a guardrail, STOP and document the conflict
- Record lessons and guardrails AS SOON AS you hit a problem — do not wait until task completion
