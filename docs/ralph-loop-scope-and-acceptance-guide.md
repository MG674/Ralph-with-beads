# Ralph Loop: Defining Scope & Acceptance Criteria

## A sourced guide for getting these two critical steps right

---

## Part 1: Defining Project Scope & Requirements

### The Core Principle: Describe the End State, Not the Steps

The fundamental shift with Ralph is that **you describe what "done" looks like and let the agent figure out how to get there**. Matt Pocock (AI Hero) puts it clearly: "This is a shift from planning to requirements gathering. Instead of specifying each step, you describe the desired end state."

> **Source:** [11 Tips For AI Coding With Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — Matt Pocock, AI Hero

### Recommended Approach: Spec-First, Then PRD

The best-practice workflow has two stages:

#### Stage 1: Write a High-Level Spec (SPEC.md)

Start with a concise "product brief" covering:

- **Who** is the user?
- **What** do they need?
- **What does success look like?**

Addy Osmani recommends: "A high-level spec for an AI agent should focus on *what* and *why*, more than the nitty-gritty *how*. Think of it like the user story and acceptance criteria." He advocates starting with a brief and letting the agent expand it into detail — then reviewing and correcting before any code is written.

GitHub's Spec Kit team found that specs should cover **six core areas** (based on analysis of 2,500+ agent config files):

1. **Commands** — Full executable commands with flags (`npm test`, `pytest -v`)
2. **Testing** — Framework, file locations, coverage expectations
3. **Project structure** — Where source, tests, and docs live
4. **Code style** — One real code snippet beats three paragraphs of description
5. **Git workflow** — Branch naming, commit format, PR requirements
6. **Boundaries** — What the agent must never touch (secrets, vendor dirs, production configs)

> **Source:** [How to write a good spec for AI agents](https://addyosmani.com/blog/good-spec/) — Addy Osmani, Jan 2026

#### Stage 2: Convert Spec to Structured PRD (prd.json)

The spec then gets converted into a **structured JSON PRD** — the format Ralph actually consumes. Each item is a user story with acceptance criteria and a `passes: false` field.

Pocock's recommended prompt for this conversion:

> *"Convert my feature requirements into structured PRD items. Each item should have: category, description, steps to verify, and passes: false. Format as JSON. Be specific about acceptance criteria."*

The PRD becomes **both scope definition and progress tracker** — a living TODO list. Ralph picks the highest-priority item with `passes: false`, works on it, then marks it complete.

> **Source:** [11 Tips For AI Coding With Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — Matt Pocock

### Critical Scoping Rules

**Keep each PRD item small enough to complete in one context window.** The harrymunro/ralph-wiggum implementation docs warn: "If a task is too big, the LLM runs out of context before finishing and produces poor code."

Addy Osmani reinforces this: "A crucial lesson I've learned is to avoid asking the AI for large, monolithic outputs. Instead, we break the project into iterative steps... Each chunk is small enough that the AI can handle it within context and you can understand the code it produces."

The Tweag "Introduction to Agentic Coding" guide adds: "pick something atomic that you understand deeply... Before touching any AI tool, write an implementation plan that defines your goals, constraints, and step-by-step approach."

> **Sources:**
>
> - [ralph-wiggum (harrymunro)](https://github.com/harrymunro/ralph-wiggum)
> - [My LLM coding workflow going into 2026](https://addyosmani.com/blog/ai-coding-workflow/) — Addy Osmani
> - [Introduction to Agentic Coding](https://www.tweag.io/blog/2025-10-23-agentic-coding-intro/) — Tweag/Modus Create

### Use Plan Mode Before Execution

Osmani recommends using Claude Code's **Plan Mode** (Shift+Tab) to restrict the agent to read-only analysis first. Let it explore the codebase, draft a spec, and identify ambiguities — then review and refine before switching to execution mode.

> **Source:** [How to write a good spec for AI agents](https://addyosmani.com/blog/good-spec/) — Addy Osmani

### For Your Demo System Specifically

Since your first project is a **front-end demo for a wearable device** building on existing data processing code, consider structuring scope like:

- **In-scope / Out-of-scope** — Explicitly state what's included (the open-ralph-wiggum PRD template uses `## Scope` with "In:" and "Out:" sections)
- **Existing code constraints** — Reference the CSV processing and data extraction code already built; tell the agent where it lives and what patterns to follow
- **Frontend-specific acceptance** — For front-end stories, the snarktank/ralph docs recommend including "Verify in browser using dev-browser skill" in acceptance criteria so Ralph can visually confirm UI changes

> **Source:** [open-ralph-wiggum](https://github.com/Th0rgal/open-ralph-wiggum) PRD template; [snarktank/ralph](https://github.com/snarktank/ralph) docs

---

## Part 2: Defining Acceptance Criteria / "Definition of Done"

### The Stop Condition Problem

Matt Pocock identifies **two core problems** with Ralph loops:

1. The agent picks tasks that are too large
2. The agent doesn't know when to stop

The PRD-based approach solves both. But the quality of your **acceptance criteria** determines whether Ralph correctly marks a story as done or thrashes endlessly.

An Tran's Ralph analysis states it plainly: "Ralph is a terrible fit when 'done' is fuzzy or risky. Ambiguous product/design decisions will cause the loop to thrash because there's no crisp win condition."

> **Sources:**
>
> - [Matt Pocock on X](https://x.com/mattpocockuk/status/2007924876548637089)
> - [Ralph Wiggum loop](https://antran.app/2026/ralph_wiggum/) — An Tran

### What Good Acceptance Criteria Look Like for Ralph

The key insight from multiple sources: **acceptance criteria must be machine-verifiable**. The "Good Programmer" Medium article describes it precisely: "acceptance criteria as verifiable checklists, quality gates as shell commands."

#### Hierarchy of Verification (strongest to weakest)

1. **Automated tests pass** — Unit, integration, e2e. "The rate at which you can get feedback is your speed limit" (Pocock). Simon Willison notes that a robust test suite gives agents "superpowers."

2. **Quality gates pass** — Typecheck, lint, build. Pocock: "Each commit MUST pass all tests and types. If you don't do this, you're hamstringing future agent runs with bad code."

3. **Browser/visual verification** — For front-end work, use the dev-browser skill so Ralph can navigate to the page, interact with UI, and confirm changes work.

4. **Conformance suites** — Willison advocates YAML-based, language-independent test suites that act as a contract. "Must pass all cases in `conformance/api-tests.yaml`."

5. **LLM-as-Judge** — For subjective criteria (style, readability, UX). Osmani: "Consider using a second agent to review the first agent's output against your spec's quality guidelines."

6. **Self-audit prompts** — Instruct the agent: "After implementing, compare the result with the spec and confirm all requirements are met. List any spec items that are not addressed."

> **Sources:**
>
> - [The Ralph Wiggum pattern](https://thegoodprogrammer.medium.com/the-ralph-wiggum-pattern-automation-and-persistence-for-coding-agents-4e8fa6f81dff) — The Good Programmer, Jan 2026
> - [How to write a good spec for AI agents](https://addyosmani.com/blog/good-spec/) — Addy Osmani
> - [Self-Improving Coding Agents](https://addyosmani.com/blog/self-improving-agents/) — Addy Osmani

### The Effort-Aware Approach

Valentin Nagacevschi proposes **effort-labelling** PRD items (`low` / `medium` / `high`) so the loop can allocate more thinking budget to harder tasks. "A trivial string rename doesn't deserve the same cognitive spend as 'migrate auth tokens without breaking sessions.'"

> **Source:** [The Ralph Loop: When Your PRD Becomes the Steering Wheel](https://medium.com/@ValentinNagacevschi/the-ralph-loop-when-your-prd-becomes-the-steering-wheel-5abf6b1345c0) — Jan 2026

### Use JSON Over Markdown for PRDs

Multiple sources recommend **JSON format** for the PRD rather than prose Markdown. The open-ralph-wiggum docs explain: "Agents are less likely to inappropriately modify JSON test definitions compared to Markdown. The structured format keeps agents focused on implementation rather than redefining success criteria."

This is critical — **you don't want the agent modifying its own acceptance criteria to pass them**.

> **Source:** [open-ralph-wiggum](https://github.com/Th0rgal/open-ralph-wiggum)

### Practical Template for a PRD Item

Based on the snarktank/ralph and Pocock patterns, a good PRD item looks like:

```json
{
  "id": "US-001",
  "title": "Dashboard shows real-time ankle circumference chart",
  "category": "frontend",
  "description": "Display a line chart of ankle circumference readings from the CSV data, with configurable time window and moving average overlay",
  "effort_label": "medium",
  "acceptance_criteria": [
    "Chart renders with data from sample CSV without errors",
    "User can select time window (1h, 6h, 24h, 7d)",
    "Moving average line displays correctly over raw data",
    "Device charging periods are excluded from the plot",
    "All existing tests pass",
    "TypeScript compiles without errors",
    "ESLint passes with no warnings"
  ],
  "passes": false
}
```

### The Agent Brief Pattern

Osmani's "Your AI coding agents need a manager" article distills the ideal brief into seven elements:

1. **The outcome** — what should be true when done
2. **The context** — where in the codebase this lives, what patterns exist
3. **The constraints** — performance, security, API shape, dependency rules, style
4. **The non-goals** — what you're explicitly NOT doing
5. **Acceptance criteria** — concrete checks (tests passing, endpoints behaving)
6. **Integration notes** — which files are off-limits, where seams should be
7. **Verification plan** — how you'll know it works

> **Source:** [Your AI coding agents need a manager](https://addyosmani.com/blog/coding-agents-manager/) — Addy Osmani

---

## Summary Checklist

### Before Starting a Ralph Loop

- [ ] Write a high-level SPEC.md (what & why, not how)
- [ ] Use Plan Mode to let the agent expand and refine the spec
- [ ] Review the expanded spec for hallucinations and missing constraints
- [ ] Convert spec to prd.json with structured, small user stories
- [ ] Each story has **machine-verifiable** acceptance criteria
- [ ] Include quality gates as shell commands (test, typecheck, lint, build)
- [ ] For front-end stories, include browser verification criteria
- [ ] Use JSON format for PRD to prevent the agent redefining success
- [ ] Explicitly state scope boundaries (in-scope / out-of-scope)
- [ ] Reference existing code patterns for the agent to follow
- [ ] Set iteration limits (Pocock recommends 5–10 for small tasks, 30–50 for larger ones)
- [ ] Ensure progress.txt is configured for inter-iteration memory

---

*Compiled Feb 2026. All sources accessed Feb 2026.*
