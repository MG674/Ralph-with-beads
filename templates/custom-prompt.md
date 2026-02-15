# [Title -- e.g., Fix PR #25 Review Comments]

You are working on [PROJECT_NAME].

## Context Files

@CLAUDE.md

## STEP 1: GUARDRAILS PRE-FLIGHT (MANDATORY)

Before doing ANYTHING else:
1. Read `docs/guardrails.md` — these rules ALWAYS take precedence
2. Read `docs/lessons-learned.md` — check for relevant patterns
3. Read `coding-standards.md` if making code changes

Do NOT skip this step. Guardrails override all other instructions.

## STEP 2: TASK

Do NOT pick a new bead. Do NOT run `bd ready`. Instead, complete the following:

### 1. [Change title]

[Describe what to change, where, and why. Be specific — reference file paths and line numbers.]

### 2. [Change title]

[Details]

## STEP 3: VERIFY

After making changes:
1. Run `bash verify.sh` — all checks MUST pass
2. Ensure all existing tests still pass (do NOT delete or weaken tests)
3. If new code was added, ensure it has tests (target 80%+ coverage)
4. Commit with message: `[BD-XXX] Brief description`

If verify.sh fails:
- Fix the issues and run again
- Do NOT proceed until all checks pass

## Rules

- ONLY do what is described in Step 2 — nothing else
- Do NOT pick up new beads or run `bd ready`
- Do NOT refactor unrelated code
- Do NOT modify `verify.sh`
- Do NOT modify build/tool config in `pyproject.toml` (e.g. pythonpath, requires-python, tool settings)
- Do NOT work around Docker/container environment differences by changing project files — project files must work on the host machine
- Do NOT use hardcoded container paths (e.g. `/workspace`)
- Do NOT set PYTHONPATH — use `pip install -e .` instead
- Guardrails ALWAYS take precedence over lessons-learned.md
- If a fix seems to require violating a guardrail, STOP and document the conflict rather than proceeding
