# The Ralph Loop Development Workflow

A complete end-to-end process for autonomous AI-driven development using Claude Code, the Ralph Wiggum loop technique, Beads task management, and test-driven development.

**Version:** 2.0  
**Date:** 2026-02-07  
**Context:** VM General Services Ltd — multi-project workflow starting with Ergofigure demo software

---

## 1. What Is This?

This document defines our standard development workflow. It combines:

- **Ralph Loop** — a bash loop that runs Claude Code repeatedly against a task list until all work is done. Each iteration gets a fresh context window, keeping the agent in the "smart zone."
- **Beads** — a Git-backed issue tracker designed for AI agents. Provides addressable task IDs, dependency tracking, audit trails, and session handoff.
- **TDD (Red-Green-Refactor)** — every feature starts with a failing test.
- **Tracer Bullet development** — prove the architecture works end-to-end before filling in features.
- **Docker isolation** — Ralph always runs in a container for safety and reproducibility.

The philosophy: *define what "done" looks like, give the agent small verifiable tasks, and let the loop iterate until it gets there.*

> "The technique is deterministically bad in an undeterministic world. It's better to fail predictably than succeed unpredictably." — Geoffrey Huntley

---

## 2. Repository Structure

Everything lives in a dedicated repo so it can serve multiple projects.

```
ralph-with-beads/
├── README.md                    # Quick-start guide
├── ralph-loop-workflow.md       # This document
├── scripts/
│   ├── ralph-hitl.sh            # Human-in-the-loop (single iteration)
│   ├── ralph-afk.sh             # AFK loop (N iterations, Docker)
│   └── notify.sh                # Completion notification (optional)
├── templates/
│   ├── prompt.md                # The Ralph prompt template
│   ├── CLAUDE.md                # Project-level agent instructions template
│   ├── coding-standards.md      # Code style and conventions
│   └── prd-template.md          # PRD template for new features
├── docker/
│   └── Dockerfile               # Claude Code Docker image config
├── prompts/
│   ├── planning-interview.md    # Questions for PRD creation
│   └── beads-generation.md      # Prompt for converting PRD to beads
└── docs/
    ├── lessons-learned.md       # Accumulated learnings (agent-updated)
    └── guardrails.md            # "Signs" — rules added after failures
```

Each **project repo** (e.g. `ergofigure-demo`, `ergofigure-api`) contains:

```
project-repo/
├── CLAUDE.md                    # Project-specific agent instructions
├── .beads/                      # Beads issue database (Git-tracked)
│   ├── beads.db                 # SQLite cache
│   └── issues.jsonl             # Source of truth (Git-tracked)
├── prd.md                       # Current PRD
├── tests/                       # Test suite
├── src/                         # Source code
├── docs/
│   ├── lessons-learned.md       # Project-specific learnings
│   └── guardrails.md            # Project-specific rules
└── verify.sh                    # Full quality verification script
```

---

## 3. Prerequisites & Setup

### 3.1 Install Claude Code

```bash
# Native binary install
curl -fsSL https://claude.ai/install | sh
claude  # Authenticate with Anthropic account
```

### 3.2 Install Beads

```bash
# Via npm (or bun)
npm install -g beads

# Initialise in your project repo
cd your-project
bd init
```

This creates the `.beads/` directory. The `issues.jsonl` file is the source of truth and gets committed to Git.

### 3.3 Install Beads Viewer (bv)

For terminal-based task visibility with dependency graphs and impact analysis.

```bash
# From https://github.com/Dicklesworthstone/beads_viewer
cargo install beads_viewer
# or clone and build from source
```

Usage: run `bv` from your project root. Vim-style keys (j/k navigation, o/c/r to filter open/closed/ready).

### 3.4 Install Playwright MCP (for UI Testing)

Playwright MCP gives Claude "eyes" to see and interact with your UI.

```bash
# Add Playwright MCP server to Claude Code
claude mcp add playwright npx @playwright/mcp@latest

# Or for manual configuration, add to .claude.json:
# {
#   "mcpServers": {
#     "playwright": {
#       "command": "npx",
#       "args": ["@playwright/mcp@latest", "--headless"]
#     }
#   }
# }
```

### 3.5 Docker Setup

Build the Claude Code Docker image:

```dockerfile
# docker/Dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl git nodejs npm python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN curl -fsSL https://claude.ai/install | sh

# Install Beads
RUN npm install -g beads

# Install Playwright for UI testing
RUN npx playwright install --with-deps chromium

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
```

```bash
cd ralph-with-beads/docker
docker build -t ralph-claude:latest .
```

### 3.6 Git Setup

Every project repo uses Git from the start. Ralph commits after each task. Beads stores issues in Git.

**Branch strategy:** Ralph works on a dedicated branch (e.g. `ralph/feature-name`). PR to main after successful run.

**Key principle:** Git operations happen INSIDE the Docker container. The project directory is mounted as a volume, so commits persist to your local filesystem. After a successful Ralph run, you create a PR from outside the container.

---

## 4. The Planning Process

Before writing any code, we go through a structured planning process. This ensures clear scope, testable requirements, and well-sized tasks.

### 4.1 Requirements Interview

Start with an interview session to gather comprehensive requirements. Use the planning interview prompt:

```markdown
# Planning Interview Prompt

You are helping me define requirements for a new feature/project.
Ask me questions one at a time to understand:

1. **Goal** — What problem does this solve? Who is the user?
2. **Scope** — What's in scope? What's explicitly out of scope?
3. **Success Criteria** — How will we know when it's done?
4. **Constraints** — Technical constraints, dependencies, deadlines?
5. **User Stories** — Walk me through the user's journey step by step.
6. **Edge Cases** — What could go wrong? What are the unusual cases?
7. **Testing** — How would we verify each part works correctly?
8. **Priorities** — If we had to cut scope, what's essential vs nice-to-have?

After each answer, ask a follow-up question to dig deeper.
When you have enough information, summarize the requirements.
```

Save the interview output as `clarify-session.md`.

### 4.2 PRD Creation

Convert the interview into a structured PRD:

```markdown
# PRD: [Feature Name]

## Overview
[One paragraph describing the feature]

## Goals
- Primary goal: ...
- Secondary goals: ...

## Non-Goals (Out of Scope)
- ...

## User Stories
### US-1: [Story Title]
**As a** [user type]
**I want** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] Given... When... Then...
- [ ] Given... When... Then...

**How to Test:**
- Manual: [steps to verify manually]
- Automated: [what the test should check]

### US-2: ...

## Technical Approach
[High-level approach, key decisions]

## Success Metrics
- [Measurable criteria]

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| ... | ... |
```

### 4.3 Testability Review

Before converting to beads, review each user story:

1. **Is the acceptance criteria testable?** Can you write a test that passes/fails based on these criteria?
2. **Is the scope clear?** Could two developers implement this independently and get the same result?
3. **Is it small enough?** Can it be completed in a single Ralph iteration (ideally <30 minutes of work)?
4. **Are dependencies explicit?** What must be done first?

### 4.4 Beads Generation

Convert the PRD into beads tasks:

```bash
# Use Claude to generate beads from PRD
claude -p "Read prd.md. For each user story and acceptance criterion,
           create a bead using 'bd create'. Include:
           - Clear title
           - Type (feature/bug/task)
           - Priority (1=highest, 5=lowest)
           - Link dependencies with 'bd dep block'
           Keep tasks small - one acceptance criterion per bead."
```

Review the generated beads:
```bash
bd list          # See all tasks
bv               # Visual overview with dependencies
```

---

## 5. The Core Files

### 5.1 prompt.md — The Ralph Prompt

This is the heart of the system. Note: **completion check happens FIRST** (per Matt Pocock's recommendation for more accurate completion promises).

```markdown
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

## STEP 5: COMPLETE THE TASK

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
```

### 5.2 CLAUDE.md — Project Agent Instructions

Lives in each project repo. Uses **progressive disclosure** — points to detailed docs rather than including everything inline.

```markdown
# CLAUDE.md — [PROJECT_NAME]

## Project Overview
[Brief description of what this project does]

## Tech Stack
- Language: Python 3.12
- Testing: pytest
- Linting: ruff
- Formatting: black
- Type checking: mypy

## Quick Reference

### Commands
- `./verify.sh` — Run all quality checks (MUST pass before committing)
- `bd ready` — Find next task to work on
- `bd close <id> "message"` — Complete a task
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
| docs/guardrails.md | ALWAYS read at start of each task |
| docs/lessons-learned.md | When working on related areas |
| docs/architecture.md | When making structural changes |
| docs/api-reference.md | When working with external APIs |
| coding-standards.md | When refactoring or reviewing style |

## Git Workflow
- Work on branch: ralph/<feature-name>
- Commit message format: `[BD-XXX] Brief description`
- All commits must pass verify.sh

## Beads Workflow
1. `bd ready` — find next task
2. `bd update <id> in_progress` — claim it
3. Implement with TDD
4. `bd close <id> "message"` — complete it
5. Commit immediately
```

### 5.3 verify.sh — Full Quality Verification

This is the feedback loop that makes Ralph work. **Every check must pass before a task can be closed.**

```bash
#!/bin/bash
set -e

echo "=== LINT ==="
ruff check .

echo "=== FORMAT ==="
black --check .

echo "=== TYPE CHECK ==="
mypy . --ignore-missing-imports

echo "=== TESTS ==="
pytest --tb=short -q

echo "=== COVERAGE ==="
pytest --cov=src --cov-fail-under=80 --cov-report=term-missing

echo "=== ALL CHECKS PASSED ==="
```

For JavaScript/React projects:

```bash
#!/bin/bash
set -e

echo "=== LINT ==="
npx eslint .

echo "=== FORMAT ==="
npx prettier --check .

echo "=== TYPE CHECK ==="
npx tsc --noEmit

echo "=== TESTS ==="
npx jest --ci --coverage --coverageThreshold='{"global":{"branches":80,"functions":80,"lines":80}}'

echo "=== ALL CHECKS PASSED ==="
```

### 5.4 coding-standards.md — Style and Conventions

Keep this concise. It's for refactoring guidance, not comprehensive rules (use linters for that).

```markdown
# Coding Standards

## Naming
- Functions: verb_noun (e.g., `parse_csv`, `calculate_average`)
- Classes: PascalCase nouns (e.g., `DataProcessor`, `ChartRenderer`)
- Constants: UPPER_SNAKE_CASE
- Private: prefix with underscore

## Structure
- One class per file (usually)
- Group related functions in modules
- Keep functions under 20 lines (prefer 10)
- Keep files under 200 lines

## Testing
- Test file mirrors source: `src/parser.py` → `tests/test_parser.py`
- Test function names: `test_<function>_<scenario>_<expected>`
- One assertion per test (usually)
- Use fixtures for setup, not duplication

## Error Handling
- Fail fast with clear error messages
- Validate inputs at boundaries
- Use custom exceptions for domain errors

## Documentation
- Docstrings: what, not how (the code shows how)
- Comments: why, not what (only for non-obvious decisions)
```

---

## 6. Writing Good Tests

Tests are the feedback loop that makes Ralph work. Poor tests = poor Ralph output.

### 6.1 Test Quality Principles

**Tests should be:**
- **Fast** — Run in milliseconds, not seconds
- **Isolated** — No shared state between tests
- **Repeatable** — Same result every time
- **Self-validating** — Pass or fail, no interpretation needed
- **Timely** — Written before or with the code (TDD)

**Tests should NOT:**
- Test implementation details (test behavior, not structure)
- Require external services (mock them)
- Depend on test execution order
- Share mutable state

### 6.2 Test Structure (Arrange-Act-Assert)

```python
def test_calculate_average_with_valid_numbers_returns_mean():
    # Arrange
    numbers = [2, 4, 6, 8]
    
    # Act
    result = calculate_average(numbers)
    
    # Assert
    assert result == 5.0
```

### 6.3 What to Test

**DO test:**
- Happy path (normal operation)
- Edge cases (empty input, single item, max values)
- Error conditions (invalid input, missing data)
- Boundary conditions (off-by-one, limits)

**DON'T test:**
- Third-party libraries (they have their own tests)
- Simple getters/setters
- Private implementation details
- Exact log messages or print output

### 6.4 Test Naming Convention

```
test_<unit>_<scenario>_<expected_result>
```

Examples:
- `test_parse_csv_with_empty_file_returns_empty_list`
- `test_calculate_average_with_single_value_returns_that_value`
- `test_validate_email_with_missing_at_raises_validation_error`

### 6.5 Mutation Testing (Verification)

To verify your tests actually catch bugs, consider mutation testing:

```bash
# Python
pip install mutmut
mutmut run

# JavaScript
npm install --save-dev stryker-cli
npx stryker run
```

Mutation testing modifies your code and checks if tests fail. If tests still pass with mutated code, your tests aren't comprehensive enough.

---

## 7. UI Testing with Playwright MCP

Playwright MCP gives Claude "eyes" to see and interact with your UI. This enables visual verification and end-to-end testing.

### 7.1 What Playwright MCP Can Do

- **Navigate pages** — Load URLs, click links
- **Interact with elements** — Click buttons, fill forms, select options
- **Take screenshots** — Capture visual state for verification
- **Inspect the DOM** — Read text, check element presence
- **Resize viewport** — Test responsive layouts
- **Monitor network** — Check API calls

### 7.2 UI Testing Approach

Add UI verification to your test criteria:

```markdown
### US-3: Display Chart
**Acceptance Criteria:**
- [ ] Chart renders with correct title
- [ ] Data points match input data
- [ ] Responsive: displays correctly at 375px and 1200px width

**How to Test (UI):**
1. Navigate to /dashboard
2. Verify chart title text
3. Take screenshot at desktop width
4. Resize to mobile (375x667)
5. Take screenshot at mobile width
6. Compare against expected layout
```

### 7.3 UI Testing Commands

In your prompt, you can instruct Claude to use Playwright:

```markdown
## UI Verification (when applicable)

If the task involves UI changes:
1. Start the dev server: `npm run dev`
2. Use Playwright MCP to navigate to the relevant page
3. Take a screenshot for verification
4. Check that key elements are present and visible
5. Test at both desktop (1200px) and mobile (375px) widths
6. Save screenshots to tests/screenshots/<feature>.png
```

### 7.4 Visual Regression Testing

For more rigorous UI testing, use Playwright's built-in screenshot comparison:

```javascript
// tests/visual/dashboard.spec.js
import { test, expect } from '@playwright/test';

test('dashboard chart renders correctly', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page.locator('.chart')).toBeVisible();
  await expect(page).toHaveScreenshot('dashboard-chart.png');
});
```

Run with:
```bash
npx playwright test --update-snapshots  # First run: create baselines
npx playwright test                      # Subsequent runs: compare
```

---

## 8. Lessons Learned & Guardrails (Progressive Disclosure)

Two files enable Ralph to improve itself over time. They use **progressive disclosure** — CLAUDE.md tells the agent these files exist and when to read them, rather than loading everything into context.

### 8.1 docs/guardrails.md — Rules From Failures

When Ralph fails in a specific way, add a guardrail so future iterations avoid it.

**Format:**
```markdown
# Guardrails

## CRITICAL (Always Follow)
- NEVER skip type checking even if tests pass
- NEVER commit without running verify.sh
- ALWAYS validate input data before processing

## Data Processing
- CSV parser silently drops rows with missing timestamps — always validate row count
- Moving average calculation fails with < window_size points — add explicit check

## UI
- Chart.js datasets must have matching label array length
- Always test at both 375px and 1200px widths

## Testing
- Pytest fixtures with cleanup must use yield, not return
- Mock external APIs in tests — never call real endpoints
```

**When to add:**
- After any failure that took >10 minutes to debug
- When you discover a non-obvious constraint
- When a bug recurs

### 8.2 docs/lessons-learned.md — Accumulated Wisdom

Patterns, tips, and insights discovered during development.

**Format:**
```markdown
# Lessons Learned

## Data Model
- Ankle measurements should be stored in mm, not cm (precision issues)
- Timestamps must be UTC — local time causes issues across timezones

## Architecture Decisions
- Chose Chart.js over D3 for simplicity (revisit if need more control)
- Using SQLite for local storage; PostgreSQL for production

## Performance
- CSV parsing is slow for files >10MB — consider chunked processing
- Chart redraws are expensive — debounce window resize events

## Integration
- AWS S3 requires explicit region configuration
- NHS API has 100 req/min rate limit
```

### 8.3 How Progressive Disclosure Works

CLAUDE.md contains a "table of contents" pointing to docs:

```markdown
## Documentation (Read When Relevant)

| Document | When to Read |
|----------|--------------|
| docs/guardrails.md | ALWAYS at start of each task |
| docs/lessons-learned.md | When working on related areas |
```

The agent:
1. Reads CLAUDE.md at session start (always loaded)
2. Reads guardrails.md at the start of each task (per prompt.md instruction)
3. Reads lessons-learned.md only when working on related areas

This keeps context lean while preserving institutional knowledge.

### 8.4 Indexing for Large Projects

If docs grow large, add an index file:

```markdown
# docs/INDEX.md

## Guardrails by Area
- Data Processing: guardrails.md#data-processing
- UI/Charts: guardrails.md#ui
- Testing: guardrails.md#testing
- AWS/Cloud: guardrails-cloud.md

## Lessons by Topic
- Data Model: lessons-learned.md#data-model
- Architecture: lessons-learned.md#architecture-decisions
- Performance: lessons-learned.md#performance
- NHS Integration: lessons-nhs.md
```

---

## 9. The Scripts

### 9.1 ralph-hitl.sh — Human-in-the-Loop (Single Iteration)

Use this when starting a new feature, doing risky work, or learning how Ralph behaves.

```bash
#!/bin/bash
set -e

# Usage: ./ralph-hitl.sh /path/to/project [prompt-file]
PROJECT_DIR="${1:-.}"
PROMPT_FILE="${2:-$PROJECT_DIR/prompt.md}"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: prompt.md not found at $PROMPT_FILE"
    exit 1
fi

echo "=== RALPH HITL — Single Iteration ==="
echo "Project: $PROJECT_DIR"
echo "Prompt:  $PROMPT_FILE"
echo ""

# Sync from remote before starting
cd "$PROJECT_DIR"
echo "Syncing from remote..."
git fetch origin
git pull --rebase origin main || true

# Create feature branch if not already on one
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ]; then
    BRANCH_NAME="ralph/$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$BRANCH_NAME"
    echo "Created branch: $BRANCH_NAME"
fi

echo ""
echo "Press Enter to run, Ctrl+C to cancel..."
read

docker run --rm -it \
    -v "$(pwd)":/workspace \
    -v "$HOME/.claude:/root/.claude" \
    -w /workspace \
    ralph-claude:latest \
    -c "claude --dangerously-skip-permissions -p \"\$(cat $PROMPT_FILE)\""

echo ""
echo "=== Iteration complete ==="
echo "Review the changes:"
echo "  git log --oneline -5"
echo "  git diff HEAD~1"
echo "  bd ready"
echo ""
echo "Run again? Execute this script again when ready."
echo "When done, push and create PR:"
echo "  git push -u origin $(git branch --show-current)"
```

### 9.2 ralph-afk.sh — Autonomous Loop (N Iterations, Docker)

Use this once the foundation is solid and tasks are well-defined.

```bash
#!/bin/bash
set -e

# Usage: ./ralph-afk.sh /path/to/project [max-iterations] [prompt-file]
PROJECT_DIR="${1:-.}"
MAX_ITERATIONS="${2:-10}"
PROMPT_FILE="${3:-$PROJECT_DIR/prompt.md}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$PROJECT_DIR/ralph-runs/ralph-$TIMESTAMP.log"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "ERROR: prompt.md not found at $PROMPT_FILE"
    exit 1
fi

mkdir -p "$PROJECT_DIR/ralph-runs"

echo "=== RALPH AFK — $MAX_ITERATIONS iterations ===" | tee "$LOG_FILE"
echo "Project: $PROJECT_DIR" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

cd "$PROJECT_DIR"

# Sync from remote before starting
echo "Syncing from remote..." | tee -a "$LOG_FILE"
git fetch origin
git pull --rebase origin main || true

# Create feature branch
BRANCH_NAME="ralph/afk-$TIMESTAMP"
git checkout -b "$BRANCH_NAME"
echo "Created branch: $BRANCH_NAME" | tee -a "$LOG_FILE"

for ((i=1; i<=$MAX_ITERATIONS; i++)); do
    echo "--- Iteration $i of $MAX_ITERATIONS ---" | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"

    RESULT=$(docker run --rm \
        -v "$(pwd)":/workspace \
        -v "$HOME/.claude:/root/.claude" \
        -w /workspace \
        ralph-claude:latest \
        -c "claude --dangerously-skip-permissions -p '\$(cat $PROMPT_FILE)'" \
        2>&1) || true

    echo "$RESULT" >> "$LOG_FILE"

    # Check for completion signal
    if echo "$RESULT" | grep -q "<promise>COMPLETE</promise>"; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH COMPLETE after $i iterations ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"
        
        # Push branch for PR
        echo "Pushing branch for PR..." | tee -a "$LOG_FILE"
        git push -u origin "$BRANCH_NAME"
        
        echo "" | tee -a "$LOG_FILE"
        echo "Create PR at: https://github.com/[org]/[repo]/pull/new/$BRANCH_NAME" | tee -a "$LOG_FILE"

        if [ -f "$(dirname $0)/notify.sh" ]; then
            bash "$(dirname $0)/notify.sh" "Ralph complete on $(basename $PROJECT_DIR) after $i iterations"
        fi
        exit 0
    fi

    # Check for blocked signal
    if echo "$RESULT" | grep -q "<promise>BLOCKED</promise>"; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH BLOCKED at iteration $i ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"

        if [ -f "$(dirname $0)/notify.sh" ]; then
            bash "$(dirname $0)/notify.sh" "Ralph BLOCKED on $(basename $PROJECT_DIR) at iteration $i"
        fi
        exit 1
    fi

    echo "Iteration $i complete." | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    sleep 5
done

echo "=== RALPH FINISHED — max iterations ($MAX_ITERATIONS) reached ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"

# Push whatever progress was made
git push -u origin "$BRANCH_NAME"
echo "Branch pushed. Create PR to review progress." | tee -a "$LOG_FILE"

if [ -f "$(dirname $0)/notify.sh" ]; then
    bash "$(dirname $0)/notify.sh" "Ralph finished on $(basename $PROJECT_DIR) — max iterations reached"
fi
```

---

## 10. The End-to-End Process

### Phase 0: Project Initialisation (One-Time)

```
1.  Create project repo on GitHub
2.  Clone locally
3.  cd <repo>
4.  bd init                          # Initialise Beads
5.  Copy CLAUDE.md template, adapt for this project
6.  Copy coding-standards.md
7.  Create verify.sh, make executable
8.  Create prompt.md from template
9.  Create docs/lessons-learned.md (empty)
10. Create docs/guardrails.md (with initial rules)
11. mkdir ralph-runs
12. git add -A && git commit -m "Initial project setup with Ralph workflow"
13. git push
```

### Phase 1: Planning (HITL Only)

```
1.  Run planning interview (HITL Claude session)
2.  Create PRD from interview output
3.  Review PRD for testability
4.  Generate beads from PRD
5.  Review beads: bd list, bv
6.  Commit PRD and beads: git add -A && git commit -m "Add PRD and initial beads"
```

### Phase 2: Tracer Bullet (HITL Only)

The tracer bullet proves the architecture works end-to-end. Always HITL.

```
1.  Identify the thinnest slice that touches every layer
    (e.g., "Read one CSV file, extract one data point, display it")
2.  Mark tracer bullet beads with priority 1
3.  git checkout -b ralph/tracer-bullet
4.  Run ralph-hitl.sh iteratively
    Watch each iteration. Check each commit. Refine prompt.md as needed.
5.  When tracer bullet works:
    git push -u origin ralph/tracer-bullet
    Create PR, review, merge to main
```

### Phase 3: Feature Development (HITL then AFK)

```
1.  Create feature PRD
2.  Generate beads for feature
3.  git checkout -b ralph/<feature-name>
4.  Start HITL for risky/spike tasks:
      ./ralph-hitl.sh .
5.  Once spikes resolved, switch to AFK:
      ./ralph-afk.sh . 15
6.  Review progress:
      git log --oneline
      bd list
      bv
7.  If work remains, run more iterations
8.  When feature complete:
      git push -u origin ralph/<feature-name>
      Create PR, review, merge to main
```

### Phase 4: Land the Plane (Session Handoff)

At the end of any work session:

```
1.  All Git changes committed
2.  Beads status is accurate (bd list shows correct states)
3.  Any blockers documented in relevant bead
4.  docs/lessons-learned.md and docs/guardrails.md updated if applicable
5.  Branch pushed to remote
```

To resume:
```bash
cd your-project
git fetch origin
git checkout ralph/<feature>  # or create new branch
bd ready                      # See what's next
bv                            # Visual overview
```

---

## 11. Do We Need progress.txt?

**Short answer:** No, if you're using Beads properly.

**Beads replaces progress.txt** for task tracking. Each bead has:
- Status (open/in_progress/closed)
- Close message (what was done)
- Git history (when it was done)

**When you might still want progress.txt:**
- Iteration-level notes within a single task
- Debug logs for troubleshooting Ralph behavior
- Session notes that don't fit in beads

**Recommendation:** Start without progress.txt. Add it only if you find Beads insufficient for your needs.

---

## 12. Compliance with Matt Pocock's 11 Tips

Cross-reference with [11 Tips for AI Coding with Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum):

| Tip | Our Implementation |
|-----|-------------------|
| 1. Keep PRD items small | Beads tasks target single acceptance criteria |
| 2. Bias toward small steps | Prompt enforces "ONE task per iteration" |
| 3. Prioritize hard stuff first | Beads priorities; tracer bullet first |
| 4. Let Ralph pick tasks | `bd ready` returns highest priority unblocked |
| 5. Track progress | Beads status + Git commits |
| 6. Git is memory | All work committed; beads in Git |
| 7. Keep CI green | verify.sh must pass before closing task |
| 8. Strong feedback loops | TDD + linting + type checking + coverage |
| 9. Use HITL for spikes | ralph-hitl.sh for risky work |
| 10. Cap AFK iterations | --max-iterations flag |
| 11. Delete progress.txt | Session-specific; Beads is persistent |

---

## 13. Key Resources

### Ralph Wiggum Technique
- [Geoffrey Huntley — Ralph Wiggum as a "software engineer"](https://ghuntley.com/ralph/) — Original creator's philosophy, "signs on the playground" metaphor
- [Geoffrey Huntley — how-to-ralph-wiggum](https://github.com/ghuntley/how-to-ralph-wiggum) — Comprehensive playbook
- [Dev Interrupted — Inventing the Ralph Wiggum Loop](https://devinterrupted.substack.com/p/inventing-the-ralph-wiggum-loop-creator) — Deep dive podcast with Geoffrey Huntley
- [Matt Pocock — Getting Started with Ralph](https://www.aihero.dev/getting-started-with-ralph) — Step-by-step quickstart
- [Matt Pocock — 11 Tips for AI Coding with Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — HITL vs AFK, task sizing, feedback loops
- [Awesome Ralph](https://github.com/snwfdhmp/awesome-ralph) — Curated resource list

### Beads Task Management
- [Steve Yegge — Beads](https://github.com/steveyegge/beads) — Git-backed issue tracker for AI agents
- [Beads Viewer (bv)](https://github.com/Dicklesworthstone/beads_viewer) — Terminal UI with dependency graphs

### Testing & UI Verification
- [Playwright MCP](https://github.com/anthropics/claude-code/tree/main/mcp-servers/playwright) — Browser automation for Claude
- [Building an AI QA Engineer with Claude Code and Playwright MCP](https://alexop.dev/posts/building_ai_qa_engineer_claude_code_playwright/) — Visual testing workflow
- [Playwright Skill for Claude Code](https://github.com/lackeyjb/playwright-skill) — Model-invoked automation

### Context Engineering & Skills
- [Anthropic — Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Official guidance
- [Anthropic — Agent Skills Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices) — Progressive disclosure patterns
- [Stop Bloating Your CLAUDE.md](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/) — Practical progressive disclosure
- [Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — HumanLayer's guide

### Development Philosophy
- [The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/) — Tracer bullets, DRY, and other timeless practices (Chapter 2: "Tracer Bullets")
- [Test-Driven Development by Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530) — Kent Beck's TDD guide

---

## 14. Quick Reference Checklist

**Starting a new project:**
- [ ] Create repo, push to GitHub
- [ ] `bd init`
- [ ] Create CLAUDE.md, verify.sh, prompt.md
- [ ] Create docs/lessons-learned.md and docs/guardrails.md
- [ ] Run planning interview
- [ ] Create PRD
- [ ] Generate beads from PRD
- [ ] Run HITL until tracer bullet works
- [ ] Merge tracer bullet to main
- [ ] Write feature PRD, create beads
- [ ] HITL for spikes, AFK for lower-risk work
- [ ] Review, PR, merge, repeat

**Resuming work:**
- [ ] `git fetch && git pull`
- [ ] `bd ready` — what's next?
- [ ] `bv` — visual status
- [ ] Check docs/guardrails.md
- [ ] Run ralph-hitl.sh or ralph-afk.sh

**After each iteration:**
- [ ] verify.sh passes
- [ ] Bead closed with message
- [ ] Changes committed
- [ ] Lessons/guardrails updated if needed

---

## 15. Open Questions & Future Considerations

- **Claude Code built-in Tasks**: May eventually replace Beads. Monitor development.
- **MCP Server for Beads**: Tighter integration than CLI commands.
- **Multi-agent**: Parallel Ralph loops on independent feature branches.
- **CI/CD integration**: Ralph triggered by GitHub issues.
- **Visual regression baselines**: Automated screenshot comparison in CI.
- **Cost tracking**: Per-iteration token usage monitoring.
