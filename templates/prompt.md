# Ralph Loop Prompt

You are working on [PROJECT_NAME].

## Context Files

@CLAUDE.md
@prd.md

## STEP 1: CHECK FOR COMPLETION (DO THIS FIRST)

Run `bd ready --json` to check for unblocked tasks.

If NO ready tasks exist:

- Run `bd list` to check overall status
- If ALL tasks are closed, output <promise>COMPLETE</promise>
- If tasks exist but are blocked, output <promise>BLOCKED</promise> with explanation
- STOP HERE - do not proceed to Step 2

## STEP 2: SELECT AND EXECUTE ONE TASK

If ready tasks exist:

1. Select the highest-priority ready task
2. Read the task description and any parent epic context
3. Read docs/guardrails.md for rules to follow
4. Check docs/lessons-learned.md for relevant patterns

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

Run `./verify.sh` which executes:

- Lint check
- Format check  
- Type check (if applicable)
- Full test suite

If ANY check fails:

- Fix the issues
- Run verify.sh again
- Do NOT proceed until all checks pass

If you cannot fix the failures after genuine effort:

- Output `<verify-fail>one-line summary of the failure</verify-fail>`
- Document what you tried in docs/lessons-learned.md
- Do NOT close the task — leave it in_progress for the next iteration

## STEP 5: SELF-AUDIT

Before closing the task, re-read the bead description and confirm every requirement in it is met:

- Compare your implementation against each element of the task description
- If any requirement is not addressed, fix it now (return to Step 3)
- Only proceed to Step 6 when all requirements are satisfied

## STEP 6: COMPLETE THE TASK

a. Update task status: `bd update <id> in_progress` → work → `bd close <id> "what was done"`
b. Record discovered work: `bd create "..." bug|feature <priority>`
c. Link discoveries: `bd dep relate <new-id> <original-id>`
d. Commit with message: `[BD-XXX] Brief description`
e. If you learned something useful, append to docs/lessons-learned.md
f. If you hit a problem that wasted time, add a guardrail to docs/guardrails.md

## Rules

- ONLY work on ONE task per iteration
- Quality over speed - small steps compound into big progress
- Always run verify.sh before closing a task
- Never skip failing tests
- Commit after each completed task
- If stuck after genuine effort, document what you tried and move on
- Do NOT modify verify.sh unless the task explicitly requires it
- Do NOT modify build/tool config in `pyproject.toml` (e.g. pythonpath, requires-python, tool settings) unless the task explicitly requires it
- Do NOT work around Docker/container environment differences by changing project files — project files must work on the host machine
- Do NOT use hardcoded container paths (e.g. `/workspace`) — code must work both inside Docker and on the host machine
- Do NOT set PYTHONPATH to fix import issues — use `pip install -e .` instead
- Custom prompts (fix prompts, one-off tasks) MUST include a pre-flight step to read docs/guardrails.md. Use templates/custom-prompt.md as the base
