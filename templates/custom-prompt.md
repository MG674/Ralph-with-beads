# [Title -- e.g., Fix PR #25 Review Comments]

## Pre-flight (MANDATORY)

Before doing ANY work, read these files:
- `docs/guardrails.md` -- rules that MUST be followed (take precedence over ALL other docs)
- `docs/lessons-learned.md` -- patterns and gotchas for this project

## Task

Do NOT pick a new bead. Do NOT run `bd ready`. Instead, complete the following:

### 1. [Change title]

[Describe what to change, where, and why. Be specific -- reference file paths and line numbers.]

### 2. [Change title]

[Details]

## After Completing

1. Run `bash verify.sh` -- all checks must pass
2. Commit with message: `[BD-XXX] Brief description`
3. Do NOT close any bead or pick new work (unless instructed)

## Rules

- Follow ALL guardrails in docs/guardrails.md -- they take precedence over everything else
- Do NOT modify verify.sh unless explicitly instructed
- If a fix seems to require violating a guardrail, STOP and document the conflict in docs/lessons-learned.md instead of proceeding
