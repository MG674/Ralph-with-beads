# The Ralph Loop Development Workflow

A complete end-to-end process for autonomous AI-driven development using Claude Code, the Ralph Wiggum loop technique, Beads task management, and test-driven development.

**Version:** 1.0
**Date:** 2026-02-03
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

---

## 2. Repository Structure

Everything lives in a dedicated repo so it can serve multiple projects.

```
ralph-workflow/
├── README.md                    # Quick-start guide
├── ralph-loop-workflow.md       # This document
├── scripts/
│   ├── ralph-hitl.sh            # Human-in-the-loop (single iteration)
│   ├── ralph-afk.sh             # AFK loop (N iterations, Docker)
│   ├── ralph-docker-run.sh      # Docker wrapper for Claude Code
│   └── notify.sh                # Completion notification (optional)
├── templates/
│   ├── prompt.md                # The Ralph prompt template
│   ├── CLAUDE.md                # Project-level agent instructions template
│   ├── prd-template.md          # PRD template for new features
│   └── tracer-bullet-prd.md     # Tracer bullet PRD template
├── docker/
│   └── Dockerfile               # Claude Code Docker image config
├── config/
│   ├── .claude/settings.json    # Claude Code permission settings
│   └── lint-format.sh           # Shared lint/format verification script
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
├── progress.txt                 # Ralph iteration log
├── tests/                       # Test suite
├── src/                         # Source code
└── .github/                     # CI if needed later
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
# Check https://github.com/Dicklesworthstone/beads_viewer for latest install
# Typical:
cargo install beads_viewer
# or clone and build from source
```

Usage: run `bv` from your project root. Vim-style keys (j/k navigation, o/c/r to filter open/closed/ready).

### 3.4 Docker Setup

```bash
# Install Docker Desktop if not already present
# Pull or build Claude Code image
```

**`docker/Dockerfile`** (minimal example — adapt as needed):

```dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl git nodejs npm python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN curl -fsSL https://claude.ai/install | sh

# Install Beads
RUN npm install -g beads

# Working directory
WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
```

### 3.5 Git Setup

Every project repo uses Git from the start. Ralph commits after each task. Beads stores issues in Git. This gives you:

- Full audit trail of what the agent did and when
- Ability to revert bad iterations
- Beads issue history alongside code history

**Branch strategy:** Ralph works on a dedicated branch (e.g. `ralph/feature-name`). You review and merge to `main`.

---

## 4. The Core Files

### 4.1 prompt.md — The Ralph Prompt

This is the heart of the system. It gets fed to Claude Code on every iteration. Customise per project but keep the structure.

```markdown
# Ralph Loop Prompt

You are working on [PROJECT_NAME].

## Context Files
@CLAUDE.md
@prd.md
@progress.txt

## Your Task

1. Run `bd ready --json` to find the highest-priority unblocked task.
2. If no ready tasks exist, check if all tasks are done.
   - If yes, output <promise>COMPLETE</promise>
   - If no, output a summary of what's blocked and why.
3. For the chosen task:
   a. Read the task description and any parent epic context.
   b. **Write a failing test first** (RED).
   c. Implement the minimum code to make the test pass (GREEN).
   d. Refactor if needed (REFACTOR).
   e. Run the full verification suite: `./verify.sh`
   f. If verification fails, fix the issues. Do not skip failures.
   g. Update the task: `bd update <id> in_progress`
4. When the task passes all checks:
   a. `bd close <id> "Brief description of what was done"`
   b. Record any discovered work: `bd create "..." bug|feature <priority>`
   c. Link discoveries: `bd dep relate <new-id> <original-id>`
   d. Commit your changes with a clear message referencing the bead ID.
   e. Update progress.txt with what you did this iteration.
5. If you learn something that future iterations should know, append it
   to docs/lessons-learned.md.
6. If you hit a problem that wasted time, add a guardrail to
   docs/guardrails.md so future iterations avoid it.

## Rules
- ONLY work on ONE task per iteration.
- Quality over speed. Small steps.
- Always run verify.sh before closing a task.
- Never skip failing tests.
- Commit after each completed task.
- If stuck after genuine effort, document what you tried and move on.
  Do NOT loop on the same failure.

## Completion
When ALL beads are closed and `bd ready` returns nothing:
Output <promise>COMPLETE</promise>

If you cannot make progress on any task:
Output <promise>BLOCKED</promise> with explanation.
```

### 4.2 CLAUDE.md — Project Agent Instructions

Lives in each project repo. Tells the agent about the project, coding standards, and quality expectations.

```markdown
# CLAUDE.md — [PROJECT_NAME]

## Project Overview
[Brief description of what this project does]

## Tech Stack
- Language: Python 3.12
- Testing: pytest
- Linting: ruff
- Formatting: black
- Type checking: mypy (where applicable)

## Quality Standards
- This is PRODUCTION code, not a prototype.
- All code must have tests. Target 80%+ coverage.
- All code must pass: ruff check, black --check, mypy, pytest.
- Use type hints on all function signatures.
- Docstrings on all public functions.

## Verification Command
Run `./verify.sh` to check everything. This script runs:
1. ruff check .
2. black --check .
3. mypy .
4. pytest --tb=short

## Beads
- Run `bd quickstart` at the start of each session.
- Use `bd ready` to find your next task.
- File discovered work as new beads immediately.
- Always close beads with a meaningful message.

## Git
- Commit after each completed task.
- Commit message format: `[BD-XXX] Brief description`
- Work on branch: ralph/<feature-name>

## Guardrails
See docs/guardrails.md — read this before starting work.

## Lessons Learned
See docs/lessons-learned.md — consult this for known patterns and pitfalls.
```

### 4.3 verify.sh — The Verification Script

This is what makes TDD + Ralph work. The agent can objectively verify its own work. **Adapt per project.**

**Python project example:**

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

echo "=== ALL CHECKS PASSED ==="
```

**JavaScript/React project example:**

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
npx jest --ci

echo "=== ALL CHECKS PASSED ==="
```

---

## 5. The Scripts

### 5.1 ralph-hitl.sh — Human-in-the-Loop (Single Iteration)

Use this when starting a new feature, doing risky/architectural work, or learning how Ralph behaves with your prompt. You run it, watch what Claude does, check the commit, then decide whether to run it again.

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
echo "Press Enter to run, Ctrl+C to cancel..."
read

cd "$PROJECT_DIR"

docker run --rm -it \
    -v "$(pwd)":/workspace \
    -v "$HOME/.claude:/root/.claude" \
    -w /workspace \
    ralph-claude:latest \
    -c "claude --permission-mode acceptEdits -p \"$(cat $PROMPT_FILE)\""

echo ""
echo "=== Iteration complete ==="
echo "Review the changes:"
echo "  git log --oneline -5"
echo "  git diff HEAD~1"
echo "  bd ready"
echo ""
echo "Run again? Execute this script again when ready."
```

### 5.2 ralph-afk.sh — Autonomous Loop (N Iterations, Docker)

Use this once the foundation is solid and tasks are well-defined. Set it running and walk away.

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

for ((i=1; i<=$MAX_ITERATIONS; i++)); do
    echo "--- Iteration $i of $MAX_ITERATIONS ---" | tee -a "$LOG_FILE"
    echo "Time: $(date)" | tee -a "$LOG_FILE"

    RESULT=$(docker run --rm \
        -v "$(pwd)":/workspace \
        -v "$HOME/.claude:/root/.claude" \
        -w /workspace \
        ralph-claude:latest \
        -c "claude --permission-mode acceptEdits -p '$(cat $PROMPT_FILE)'" \
        2>&1) || true

    echo "$RESULT" >> "$LOG_FILE"

    # Check for completion signal
    if echo "$RESULT" | grep -q "<promise>COMPLETE</promise>"; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== RALPH COMPLETE after $i iterations ===" | tee -a "$LOG_FILE"
        echo "Finished: $(date)" | tee -a "$LOG_FILE"

        # Optional: notification
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

    # Brief pause between iterations
    sleep 5
done

echo "=== RALPH FINISHED — max iterations ($MAX_ITERATIONS) reached ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"

if [ -f "$(dirname $0)/notify.sh" ]; then
    bash "$(dirname $0)/notify.sh" "Ralph finished on $(basename $PROJECT_DIR) — max iterations reached"
fi
```

### 5.3 notify.sh — Optional Completion Notification

```bash
#!/bin/bash
# Adapt this to your preferred notification method
# Options: terminal bell, email, WhatsApp API, etc.
MESSAGE="${1:-Ralph loop finished}"
echo -e "\a"  # Terminal bell
echo "$MESSAGE"
# TODO: Add WhatsApp/email notification if desired
```

---

## 6. The End-to-End Process

### Phase 0: Project Initialisation (One-Time)

```
1.  Create project repo and push to GitHub
2.  git clone <repo>
3.  cd <repo>
4.  bd init                          # Initialise Beads
5.  Copy CLAUDE.md template, adapt for this project
6.  Create verify.sh, make executable
7.  Create prompt.md from template
8.  Create docs/lessons-learned.md (empty)
9.  Create docs/guardrails.md (empty)
10. mkdir ralph-runs                  # For AFK run logs
11. git add -A && git commit -m "Initial project setup with Ralph workflow"
12. git push
```

### Phase 1: Tracer Bullet (HITL Only)

The tracer bullet proves the architecture works end-to-end before you build out features. This is HIGH-RISK, HIGH-JUDGMENT work — always HITL.

```
1.  Write a tracer bullet PRD: the thinnest possible slice that touches
    every layer of the system (e.g. for Ergofigure demo: "Read one CSV
    file, extract one data point, display it on screen").
2.  Create beads for the tracer bullet tasks:
      bd create "Set up project skeleton with pytest + ruff + black" feature 1
      bd create "Implement CSV file reader (single file)" feature 1
      bd create "Extract ankle circumference data point" feature 2
      bd create "Display single data point to console" feature 2
      bd create "Tracer bullet: end-to-end smoke test" feature 1
3.  Run ralph-hitl.sh iteratively.
    Watch each iteration. Check each commit. Refine prompt.md as needed.
4.  When the tracer bullet works end-to-end:
      git checkout -b main
      git merge ralph/tracer-bullet
      Celebrate. The architecture is proven.
```

### Phase 2: Feature Development (HITL then AFK)

Now the foundation is solid. Shift toward AFK for lower-risk work.

```
1.  Write PRD for the next feature slice.
2.  Create beads (or let the agent create them from the PRD):
      claude -p "Read prd.md and create beads tasks for each item.
                 Use bd create for each. Set sensible priorities."
3.  Review the beads: bd list, bv
4.  git checkout -b ralph/<feature-name>
5.  Start HITL for any risky/spike tasks:
      ./ralph-hitl.sh .
6.  Once spikes are resolved, switch to AFK:
      ./ralph-afk.sh . 15
7.  Come back. Review:
      git log --oneline
      bd list
      bv
      Review any new entries in lessons-learned.md and guardrails.md
8.  If work remains, run more iterations or switch back to HITL.
9.  When feature complete:
      git checkout main
      git merge ralph/<feature-name>
      git push
```

### Phase 3: Land the Plane (Session Handoff)

At the end of any work session (whether HITL or AFK), ensure clean state:

```
1.  All Git changes committed
2.  Beads status is accurate (bd list shows correct states)
3.  progress.txt is up to date
4.  Any blockers are documented in the relevant bead
5.  lessons-learned.md and guardrails.md updated if applicable
```

To resume next time:

```bash
cd your-project
bd ready          # See what's next
bv                # Visual overview
cat progress.txt  # What happened last time
# Then either ralph-hitl.sh or ralph-afk.sh
```

---

## 7. TDD Integration: Red-Green-Refactor

The prompt.md enforces this, but here's the flow in detail:

**RED:** Write a test that describes the desired behaviour. Run it. It must fail. If it passes, you either wrote the wrong test or the feature already exists.

**GREEN:** Write the minimum code to make the test pass. No more. Don't anticipate future needs.

**REFACTOR:** Clean up. Remove duplication. Improve names. The tests protect you — if they still pass, the refactor is safe.

The key insight for Ralph: **tests are the completion signal.** The loop can objectively verify its own work without human judgment. This is why TDD + Ralph is such a strong combination.

verify.sh runs the full suite every iteration: lint, format, type check, tests. If any fail, the agent must fix them before closing the task. No shortcuts.

---

## 8. Tracer Bullet Development

Concept from *The Pragmatic Programmer*: fire a single bullet through every layer of the system to prove the architecture works. Then widen the beam.

For Ergofigure demo (Python), the tracer bullet might be:

```
CSV file → Parser → Data model → Single chart → Screen output
```

For the later API project:

```
Mobile request → API endpoint → Database → Response → Mobile display
```

The tracer bullet should be the FIRST thing Ralph works on, always in HITL mode. It exposes integration problems early, before you've built a lot of code on bad assumptions.

After the tracer bullet works, you can confidently let AFK Ralph fill in features because the architecture is proven.

---

## 9. Beads: Task Management & Audit Trail

### Why Beads?

- **Git-backed**: issues.jsonl is committed to your repo. Full history via `git log`.
- **Agent-native**: the agent creates, updates, and closes tasks naturally.
- **Dependencies**: task A can block task B. `bd ready` only returns unblocked tasks.
- **Discovered work**: agent finds a bug while implementing a feature? It files a new bead linked to the original.
- **Session handoff**: "land the plane" pattern — at end of session, bead status is the source of truth.
- **Audit trail**: every status change, every dependency link, every close message is recorded.

### Key Commands

```bash
bd init                            # Initialise in project
bd create "title" bug|feature N    # Create task (N = priority, 1=highest)
bd list                            # List all tasks
bd ready                           # Show unblocked, ready tasks
bd ready --json                    # Machine-readable for agents
bd update <id> in_progress         # Start working on a task
bd close <id> "message"            # Complete a task
bd dep relate <id1> <id2>          # Link related tasks
bd dep block <id1> <id2>           # id1 blocks id2
bd quickstart                      # Agent: orient to project state
```

### Visibility with bv (Beads Viewer)

Run `bv` in your project root for a rich terminal dashboard:
- Vim keys (j/k) to navigate
- `o` / `c` / `r` to filter Open / Closed / Ready
- Dependency graph visualisation
- Impact analysis (which tasks have most downstream dependents)
- `--robot-insights` flag for JSON output agents can consume

### Beads + Ralph Integration

The prompt.md tells the agent to:
1. `bd ready --json` to pick a task
2. Work on it with TDD
3. `bd close <id>` when done
4. `bd create` for any discovered work
5. Commit referencing the bead ID

This means your Git log reads as a narrative of tasks completed, and Beads provides the dependency/priority layer on top.

---

## 10. Lessons Learned & Guardrails (Self-Improvement)

Two files enable Ralph to improve itself over time:

### docs/lessons-learned.md

The agent appends to this when it discovers something useful. Examples:
- "The CSV parser silently drops rows with missing timestamps. Always validate row count after parsing."
- "pytest fixtures in conftest.py must use `yield` not `return` for cleanup."

Future iterations read this file (it's referenced in CLAUDE.md) and avoid known pitfalls.

### docs/guardrails.md

Added when Ralph fails in a specific way. These are "signs on the playground" (per Geoffrey Huntley's metaphor). Examples:
- "NEVER skip type checking even if tests pass."
- "When modifying the data model, always update the serialisation tests first."
- "If ruff reports more than 5 errors, fix them before writing new code."

The prompt.md tells the agent to read guardrails.md before starting. The guardrails accumulate project-specific wisdom across iterations.

---

## 11. Git Workflow

```
main ────────────────────────────────────────────►
   \                                    /
    └── ralph/tracer-bullet ──────────►  (merge)
   \                                    /
    └── ralph/feature-csv-parser ─────► (merge)
   \                                    /
    └── ralph/feature-chart-display ──► (merge)
```

- Ralph always works on a feature branch.
- Each iteration commits after completing a task.
- Commit message format: `[BD-XXX] Brief description`
- You review the branch before merging to main.
- Beads issues.jsonl is committed alongside code changes.

---

## 12. Docker Configuration

### Building the Image

```bash
cd ralph-workflow/docker
docker build -t ralph-claude:latest .
```

### How the Scripts Use Docker

Both ralph-hitl.sh and ralph-afk.sh mount:
- Your project directory as `/workspace`
- Your Claude auth credentials from `~/.claude`

The container runs Claude Code in print mode (`-p`), executes one iteration, then exits. The AFK script loops externally, creating a fresh container (and thus fresh context) each time.

### Benefits of Always-Docker

- Identical environment for HITL and AFK — no "works on my machine" surprises
- Agent can't accidentally modify files outside the project
- Reproducible across machines
- Safe for AFK: the worst it can do is mess up files in /workspace (which is Git-tracked, so reversible)

---

## 13. Adapting Per Project

The ralph-workflow repo is project-agnostic. Each project needs:

| File | What to customise |
|------|-------------------|
| CLAUDE.md | Tech stack, quality standards, verification command |
| verify.sh | Lint/format/test commands for this language |
| prompt.md | Project name, any project-specific rules |
| prd.md | The actual requirements for this project |

### Ergofigure Demo (Python)

- verify.sh: ruff + black + mypy + pytest
- Tracer bullet: CSV → parse → data point → console output
- Beads for task breakdown

### Ergofigure API (Python + React)

- Two verify scripts or a combined one
- Tracer bullet: API request → DB → response → React display
- Potentially separate beads epics for backend and frontend

### Web App (JavaScript + Python)

- ESLint + Prettier + Jest for frontend
- ruff + black + pytest for backend
- Same Ralph loop, same Beads, different verify.sh

---

## 14. Cost & Iteration Guidance

Ralph burns API tokens. Be deliberate.

| Mode | Typical Iterations | Use When |
|------|-------------------|----------|
| HITL | 1-5 | Tracer bullets, spikes, new/risky architecture |
| AFK (conservative) | 5-10 | Small well-defined tasks, solid foundation |
| AFK (extended) | 15-30 | Larger feature slices, high confidence in prompt |
| AFK (overnight) | 30-50 | Batch operations, documentation, test coverage |

**Start conservative.** Run 5 iterations AFK, review, then increase if the work is clean. Never start at 50.

---

## 15. Quick Reference Checklist

Starting a new project:

- [ ] Create repo, push to GitHub
- [ ] `bd init`
- [ ] Create CLAUDE.md, verify.sh, prompt.md
- [ ] Create docs/lessons-learned.md and docs/guardrails.md
- [ ] Write tracer bullet PRD
- [ ] Create beads for tracer bullet tasks
- [ ] Run HITL until tracer bullet works
- [ ] Merge tracer bullet to main
- [ ] Write feature PRD, create beads
- [ ] Run HITL for spikes, AFK for lower-risk work
- [ ] Review, merge, repeat

Resuming work:

- [ ] `bd ready` — what's next?
- [ ] `bv` — visual status
- [ ] `cat progress.txt` — what happened last time?
- [ ] Check lessons-learned.md and guardrails.md
- [ ] Run ralph-hitl.sh or ralph-afk.sh

---

## 16. Key Resources

- [Getting Started With Ralph](https://www.aihero.dev/getting-started-with-ralph) — Matt Pocock's quickstart guide
- [11 Tips for AI Coding With Ralph](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — HITL vs AFK, prompt tips, task sizing
- [Beads GitHub](https://github.com/steveyegge/beads) — Steve Yegge's issue tracker for agents
- [Beads Viewer (bv)](https://github.com/Dicklesworthstone/beads_viewer) — Terminal UI for Beads
- [Official Ralph Plugin](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) — Anthropic's stop-hook implementation (reference only — we use the external bash loop)
- [Awesome Ralph](https://github.com/snwfdhmp/awesome-ralph) — Curated resource list

---

## 17. Open Questions & Future Considerations

Things to evaluate as we gain experience:

- **Claude Code built-in Tasks**: Anthropic recently productised task management with dependency tracking. May eventually replace Beads. Monitor `CLAUDE_CODE_TASK_LIST_ID` feature.
- **Notification integration**: WhatsApp or email notification when Ralph finishes/blocks.
- **CI/CD integration**: Could Ralph run as a GitHub Action triggered by new issues?
- **Multi-agent**: Could we run parallel Ralph loops on independent feature branches?
- **Beads MCP server**: Beads has an MCP plugin for Claude Code which may give tighter integration than CLI commands. Worth testing.
- **Context optimisation**: Monitor token usage per iteration. If costs are high, consider trimming context files or splitting large projects.
