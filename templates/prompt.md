# Ralph Loop Prompt

You are working on [PROJECT_NAME].

## Context Files

@CLAUDE.md
@prd.md

## STEP 0: GUARDRAILS PRE-FLIGHT (MANDATORY)

Before doing ANYTHING else:
1. Read `docs/guardrails.md` — these rules ALWAYS take precedence
2. Read `docs/lessons-learned.md` — check for relevant patterns
3. Read `coding-standards.md` if making code changes

Do NOT skip this step. Guardrails override all other instructions.

## STEP 1: CHECK FOR WORK (DO THIS BEFORE ANYTHING ELSE)

Priority order:

1. Run `bd list --status in_progress --json` — if any results, that is your task — skip to Step 2.
2. Run `bd list --ready --json` — if any results, pick highest priority — go to Step 2.
3. If both return empty:
   - Run `bd list` to check overall status
   - If ALL beads are closed → output `<promise>COMPLETE</promise>` and STOP
   - If some beads are open but ALL are blocked → output `<promise>BLOCKED</promise>` with explanation of what's blocking, and STOP

## STEP 2: UNDERSTAND THE TASK

1. Read the bead description carefully
2. Identify acceptance criteria
3. Check dependencies and related beads
4. If the bead is `in_progress` (resumed from previous iteration), check git log and existing code to understand what was already done

## STEP 3: IMPLEMENT WITH TDD

a. **RED**: Write a failing test that captures the acceptance criteria

   - Run the test to confirm it fails
   - If it passes, your test is wrong or the feature exists

b. **GREEN**: Write the minimum code to make the test pass

   - No more than necessary
   - Don't anticipate future needs

c. **REFACTOR**: Clean up while tests stay green

   - Follow coding-standards.md
   - Remove duplication
   - Improve names

## STEP 4: VERIFY QUALITY

Run `bash verify.sh` (lint, format, type check, tests).

If ALL checks pass → proceed to Step 5.

If checks fail:
- Fix the issues and run `bash verify.sh` again
- You get **3 attempts**. If still failing after 3 genuine fix attempts:
  1. Record what you tried and what failed → append to `docs/lessons-learned.md`
  2. If you identified a recurring trap → add guardrail to `docs/guardrails.md`
  3. Commit your progress (even if incomplete): `git add -A && git commit -m "[BD-XXX] WIP: partial progress, verify failing"`
  4. Output `<verify-fail>one-line summary of the failure</verify-fail>`
  5. STOP — do NOT close the bead, leave it `in_progress` for the next iteration

## STEP 5: SELF-AUDIT (MANDATORY — DO NOT SKIP)

Re-read the bead description and audit EVERY acceptance criterion individually:

1. List each acceptance criterion verbatim from the bead description
2. For EACH criterion, write: "MET — [what satisfies it]" or "NOT MET — [what's missing]"
3. If ANY criterion is NOT MET:
   - If you can implement it now, return to Step 3
   - If the bead is too large to finish, commit WIP with `in_progress` and `<verify-fail>bead too large — [what remains]</verify-fail>`
4. Only proceed to Step 6 when ALL criteria show MET
5. Your close reason (Step 6) must list every criterion and how it was satisfied

WARNING: A `--no-gui`/`--headless` test does NOT satisfy criteria mentioning GUI, visual output, or window display. If the bead says "see scrolling graph" and your only evidence is a headless test, the criterion is NOT MET.

If you are running low on context:
1. Commit your progress: `git add -A && git commit -m "[BD-XXX] WIP: partial progress, context limit"`
2. Output `<verify-fail>context window limit approaching — progress committed</verify-fail>`
3. STOP — leave bead `in_progress` for the next iteration

## STEP 6: COMPLETE THE TASK

1. Close the bead: `bd close <id> --reason "what was done"`
2. If you learned something useful → append to `docs/lessons-learned.md`
3. If you hit a time-wasting problem → add guardrail to `docs/guardrails.md`
4. If you discovered new work → `bd create "..." task|bug|feature <priority>`, and link it if related: `bd dep relate <new-id> <original-id>`
5. Commit all changes: `git add -A && git commit -m "[BD-XXX] Brief description"`

## STEP 7: STOP

Do NOT start another task. One task per iteration.

Output nothing further. The loop script will invoke you again.

## Rules

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
