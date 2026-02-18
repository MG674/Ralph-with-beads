# Review Plan for Agent-Readiness

You are reviewing a plan/specification document to determine if it is ready for bead (task) generation. A bead is a single work unit for an autonomous AI coding agent (Ralph).

## Context Files

@[plan document — paste or reference here]
@ARCHITECTURE.md (if exists)
@ADRs (if exist)

## What You Are Doing

Review the plan through six focused passes. Each pass has a different lens to prevent tunnel vision. After all passes, deliver a structured verdict.

Do NOT generate beads — that is a separate step. Your job is to find gaps, ambiguities, and risks that would cause poorly-scoped or unverifiable beads.

---

## Pass 1: Completeness & Structure

Check that the plan covers all necessary sections with specifics, not placeholders.

**Required sections** (mark each PRESENT / MISSING / INCOMPLETE):
- [ ] Purpose — what problem does this solve and for whom?
- [ ] User stories or use cases — who does what and why?
- [ ] Acceptance criteria — how do we know it's done?
- [ ] Technical approach — what technologies, patterns, architecture?
- [ ] Non-goals — what is explicitly out of scope?
- [ ] Risks — what could go wrong?
- [ ] Dependencies — what must exist before this work starts?

**Red flags**:
- Sections with only placeholder text ("TBD", "TODO", "will be determined later")
- Acceptance criteria that only cover the happy path
- Missing error handling or edge case discussion

---

## Pass 2: Architecture & Technical Decisions

Check that architectural decisions are explicit, not left for the agent to guess.

**Review checklist**:
- [ ] Layer boundaries explicitly defined (what belongs where)
- [ ] Module responsibilities are single-purpose (Topic Scope Test: can each component be described in one sentence without "and"?)
- [ ] Key decisions documented with rationale (ADR-style: decision + why + consequences)
- [ ] Data flows described (how data moves through the system, transformations at each stage)
- [ ] Interface contracts between layers specified (input/output types at boundaries)
- [ ] Dependency direction explicit (what imports what, no circular dependencies)
- [ ] Technology choices stated with rationale (not just "use React" but why React)

**Red flags**:
- Implicit architecture — rules that live in tribal knowledge, not the document
- Undocumented boundary decisions (agents will put business logic in controllers)
- Components that do two things ("handles authentication AND user profile management")
- Missing "how" — purpose without implementation guidance

> **Source**: Hexagonal architecture makes "the architecture itself the prompt" — when boundaries are structurally enforced, agents cannot cross them accidentally. (notes.muthu.co)

---

## Pass 3: Acceptance Criteria Quality

Every acceptance criterion must be machine-testable. If a script cannot verify it, it is not an acceptance criterion — it is a wish.

**For each criterion, check**:
- [ ] Names the signal to check (HTTP status, file exists, test passes, log entry present)
- [ ] Specifies exact state to verify, not just "it works"
- [ ] Can be rewritten as an EARS pattern:
  - **Ubiquitous**: The [system] shall [response]
  - **Event-driven**: When [trigger], the [system] shall [response]
  - **State-driven**: While [precondition], the [system] shall [response]
  - **Optional**: Where [condition], the [system] shall [response]
  - **Unwanted**: If [unwanted condition], the [system] shall [response]
- [ ] Includes sample inputs and expected outputs where applicable
- [ ] States anti-constraints: what must NOT be mocked, stubbed, or skipped

**Red flags**:
- Vague criteria: "should work", "looks good", "is fast", "handles errors properly"
- GUI/visual criteria without specifying what to see ("the UI displays correctly")
- No anti-constraints (agents will use --dry-run, excessive mocking, or stubs to "pass")
- Criteria that require human judgement ("the code is clean")

> **Source**: EARS (Easy Approach to Requirements Syntax) — originally from airworthiness regulations for jet engine control systems. Every EARS statement converts directly into a test case. (alistairmavin.com/ears)

---

## Pass 4: Agent-Readiness & Decomposability

Check that the plan can be decomposed into beads that an autonomous agent can complete in a single session.

**Review checklist**:
- [ ] Work can be decomposed into beads that each touch a single architectural layer
- [ ] No features span backend AND frontend in a way that would create oversized beads
- [ ] Each resulting bead could be completed in one agent session (~10 min, less than 50% context window)
- [ ] Each bead would touch a coherent set of files (ideally 1-3)
- [ ] Escape hatches are blocked (no way to claim done via --dry-run, headless tests for GUI work, etc.)
- [ ] Scope is defined at plan level, not left for runtime filtering (agent should not decide what to skip)

**Red flags**:
- "Tracer bullet" features that cross all layers in one unit — must be split into per-layer beads with dependencies
- Features described at high level without breakdown guidance ("implement the dashboard")
- More than 5 acceptance criteria for a single unit of work (split warning)
- Multi-file tasks spanning unrelated modules (68% accuracy drop for multi-file tasks — Augment Code research)

> **Source**: Context rot is a cliff, not a slope — performance degrades non-uniformly and often suddenly as context grows. A model claiming 200K tokens typically becomes unreliable around 130K. (Chroma research)

---

## Pass 5: Dependencies & Build Order

Check that a clear build order exists and dependencies are explicit.

**Review checklist**:
- [ ] Critical path is identifiable — what must be built first to unblock the most work?
- [ ] No circular dependencies between planned components
- [ ] Parallel-safe work is identifiable (independent modules that can be built simultaneously)
- [ ] Foundation → infrastructure → features → integration → polish ordering is clear
- [ ] File overlap between planned units is identifiable (overlapping files must be serialized)

**Red flags**:
- No mention of build order (agents will start with whatever seems easiest)
- Features that require infrastructure that has not been built yet
- Multiple features touching the same files without sequencing plan
- Missing integration plan (features built in isolation with no plan to connect them)

> **Source**: DAG-based task ordering — tasks modeled as a Directed Acyclic Graph. Tasks without dependencies execute in parallel; tasks sharing files are serialized. (Emanuel, Google ADK)

---

## Pass 6: Risks, Edge Cases & Boundaries

Check that failure modes and boundaries are addressed.

**Review checklist**:
- [ ] Error handling paths specified (what happens when things fail?)
- [ ] Security boundaries clear (what can be accessed, what cannot)
- [ ] Non-goals explicitly stated (what we are NOT building)
- [ ] Blast radius identified (what breaks if something goes wrong?)
- [ ] Known unknowns documented (things that should be resolved before coding)
- [ ] External dependencies identified (APIs, services, libraries that may change or fail)

**Red flags**:
- Only happy-path scenarios described
- Security as an afterthought ("we'll add auth later")
- No non-goals section (scope will creep during implementation)
- Unresolved technical questions that the agent will have to guess at

---

## Output Format

For each pass, provide:

```
### Pass N: [Name]
**Verdict**: PASS / CONCERN / FAIL
**Findings**:
- [specific finding with reference to plan section]
**Suggested revisions**:
- [specific change, not vague advice]
```

### Final Verdict

**READY FOR BEAD GENERATION** — all passes PASS or CONCERN (with noted caveats)

or

**NEEDS REVISION** — one or more FAIL verdicts. List specific items that must be fixed:
1. [item — what to fix and why]
2. [item]

---

## Note: Standalone LLM Review (Recommended)

For highest quality, paste the plan into a separate LLM conversation (different from the one that wrote it) and ask it to review. Run 4-5 review rounds, applying feedback each time, until suggestions become incremental rather than structural. This is the single most effective quality gate — it catches assumptions, ambiguities, and gaps that the original author is blind to.

Prompt for the reviewing LLM:
> "Review this plan/specification for an autonomous AI coding agent. Focus on: completeness, architectural clarity, acceptance criteria quality (must be machine-testable), decomposability into small single-layer tasks, dependency ordering, and risk coverage. Be specific — suggest exact changes, not general advice."

> **Source**: Jeffrey Emanuel's iterative review process — 4-5 rounds until suggestions become incremental is the empirical sweet spot.
