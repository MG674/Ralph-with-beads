# Generate Beads from Plan

You are generating beads (task units) for an autonomous AI coding agent (Ralph). Each bead must be completable in a single agent session with high-quality, machine-testable acceptance criteria.

## Context Files

@[reviewed plan/spec document]
@ARCHITECTURE.md (if exists)
@ADRs (if exist)

## Pre-Generation Checklist

Before generating beads, confirm:

- [ ] Plan has been reviewed for agent-readiness (using review-plan.md or equivalent)
- [ ] Architectural decisions are documented (not left for the agent to decide)
- [ ] Acceptance criteria in the plan are machine-testable
- [ ] Layer boundaries are explicit

If any box is unchecked, STOP. Review the plan first.

---

## Decomposition Rules

Apply these rules to break the plan into beads. Every rule has a source — these are not opinions, they are patterns from failures.

### 1. Topic Scope Test

Can you describe the bead in one sentence without "and"?

- GOOD: "Implement the CSV parser for sensor readings"
- BAD: "Implement the CSV parser and the data visualization"

If you need "and", split into two beads.

> Source: Geoffrey Huntley — the simplest heuristic for single-responsibility

### 2. Single Architectural Layer

Each bead touches ONE layer: backend OR frontend OR infrastructure. Never both.

- GOOD: "Add distance calculation endpoint (backend)"
- BAD: "Add distance calculation and display results in GUI"

Tracer bullets are especially prone to crossing layers. Split into per-layer beads with explicit dependencies between them.

> Source: c00 incident — Ralph closed a cross-layer bead by delivering only the backend and skipping GUI criteria

### 3. Session-Sized

Each bead must be completable in one agent session (~10 minutes productive work, less than 50% context window usage).

Rules of thumb:
- 1-3 files touched (ideal)
- 1-5 acceptance criteria (more than 5 = split warning)
- Single testable outcome

If you find yourself writing "implement X, then Y, then Z" in the description, that is three beads.

> Source: Augment Code research — 68% accuracy drop for multi-file tasks. Chroma — context rot is a cliff at ~65% of window.

### 4. No Placeholders or Stubs

Each bead delivers complete, working functionality. No "implement skeleton", "add TODO for later", or "stub out the interface".

If a bead cannot deliver working code without a stub, it depends on another bead that should be created first.

> Source: Geoffrey Huntley guardrail — "implement completely or don't start"

### 5. Coherent File Scope

Group related file edits. If Bead A modifies 3 files that Bead B also modifies, they should be one bead (or serialized with an explicit dependency).

Never create two beads that independently modify the same file without a dependency link.

---

## Acceptance Criteria Rules

Every criterion must pass the "can a script verify this?" test. If the answer is no, rewrite it.

### Format: EARS Patterns

Write each criterion using one of these patterns:

| Pattern | Template | Example |
|---------|----------|---------|
| Ubiquitous | The [system] shall [response] | "The parser shall output a list of SensorReading objects" |
| Event-driven | When [trigger], the [system] shall [response] | "When POST /api/readings receives valid CSV, the API shall return 200 with parsed count" |
| State-driven | While [precondition], the [system] shall [response] | "While the calibration file is missing, the system shall use default calibration values" |
| Optional | Where [condition], the [system] shall [response] | "Where debug mode is enabled, the system shall log raw sensor values" |
| Unwanted | If [unwanted condition], the [system] shall [response] | "If the CSV contains malformed rows, the parser shall skip them and log warnings" |

> Source: EARS (Easy Approach to Requirements Syntax) — from airworthiness regulations for jet engine control systems. Adopted by Kiro and the spec-driven development community.

### Required Elements

Each bead's acceptance criteria MUST include:

1. **Functional criteria** — what the code does (EARS format)
2. **Verification command** — how to check it passes (e.g., "pytest tests/test_parser.py passes", "bash verify.sh passes")
3. **Anti-constraints** — what must NOT be mocked, stubbed, or skipped

Example anti-constraints:
- "Integration test must hit the actual database, not a mock"
- "GUI criteria require a visible window — headless/dry-run does not satisfy"
- "Do not use --dry-run to satisfy the deployment criterion"

### Starting State

All criteria start as `passes: false`. Only test execution can flip them. The agent cannot self-report completion — external verification is the minimum bar.

> Source: Anthropic's harness pattern — "use a feature list with items initially marked as failing so the agent has a clear outline of what full functionality looks like"

---

## Dependency Ordering

### Build Order Principles

1. **Foundation first** — shared types, configuration, utilities that everything else imports
2. **Infrastructure second** — database setup, API scaffolding, build pipeline
3. **Features third** — actual business logic, one layer at a time
4. **Integration fourth** — connecting layers, end-to-end flows
5. **Polish last** — error messages, logging, documentation

### Critical Path

Identify which beads unblock the most downstream work. These get highest priority (P0/P1).

A bead that blocks 5 others is more important than a bead that blocks none, regardless of feature importance.

### Parallel Safety

Mark beads that can run in parallel (no shared files, no dependency). Mark beads that MUST be serialized (shared files or explicit dependency).

---

## Output Format

### For Each Bead

```
### BD-[sequence]: [Title]

**Type**: task | feature | bug
**Priority**: P0 | P1 | P2 | P3 | P4
**Layer**: backend | frontend | infrastructure | integration
**Depends on**: [BD-X, BD-Y] or "none"
**Files** (estimated): [list of files this bead will touch]

**Description**:
[1-3 sentences. What to build and why. Reference architecture/plan sections.]

**Acceptance Criteria**:
1. [EARS-format criterion] — passes: false
2. [EARS-format criterion] — passes: false
3. [anti-constraint] — passes: false
4. When `bash verify.sh` is run, all checks pass — passes: false

**Notes**: [optional — gotchas, edge cases, references to ADRs]
```

### bd CLI Commands

After all beads are defined, provide copy-paste-ready commands:

```bash
# Create beads
bd create "BD-1 title" task P1
bd create "BD-2 title" feature P1
# ... etc

# Set dependencies
bd dep add BD-2 BD-1    # BD-2 depends on BD-1
# ... etc
```

### Dependency DAG (Text)

```
BD-1 (foundation)
├── BD-2 (infrastructure)
│   ├── BD-4 (feature A)
│   └── BD-5 (feature B)
└── BD-3 (infrastructure)
    └── BD-6 (feature C)
BD-7 (integration) ← depends on BD-4, BD-5, BD-6
BD-8 (polish) ← depends on BD-7
```

---

## Post-Generation Self-Review

After generating all beads, run five verification passes. Fix any issues before delivering.

### Pass 1: Topic Scope Test

For every bead, state its purpose in one sentence. If any sentence contains "and" connecting two distinct responsibilities, split that bead.

### Pass 2: Boundary Check

For every bead, confirm it touches exactly one architectural layer. If any bead spans layers, split it.

### Pass 3: Testability Audit

For every acceptance criterion across all beads, confirm it is machine-testable. Rewrite any criterion that requires human judgement.

### Pass 4: Coverage Check

Map every requirement from the plan to at least one bead. List any plan requirements not covered by any bead — these are gaps.

### Pass 5: DAG Validation

- Confirm no circular dependencies
- Confirm the critical path is sensible (foundation → infrastructure → features → integration → polish)
- Confirm beads that touch overlapping files are serialized
- Confirm parallel-safe beads are not unnecessarily serialized

---

## Common Mistakes to Avoid

- **Tracer bullet = one bead**: Always split into per-layer beads with dependencies
- **"Implement and test X"**: Testing is part of every bead (TDD) — don't make it a separate bead
- **Beads for documentation**: Only create doc beads if the plan explicitly requires documentation as a deliverable
- **Over-granular splits**: If two changes are to the same file and make no sense independently, keep them together
- **Missing verify.sh criterion**: Every bead should include "verify.sh passes" as a criterion — this catches formatting, linting, and type errors

> Source: Anthropic — "verification is the single highest-leverage thing you can invest in for agentic coding"
