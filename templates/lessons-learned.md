# Lessons Learned

Accumulated wisdom from development. Consult when working on related areas.

---

## How to Use This File

- **Read** relevant sections before starting work in that area
- **Add** new learnings when you discover something useful
- **Keep entries concise** — this is reference material, not documentation
- **Precedence**: If anything in this file contradicts docs/guardrails.md, the guardrail wins. Do NOT add lessons that weaken or circumvent guardrails

---

## Architecture Decisions

<!-- Record key decisions and their rationale -->
<!-- Example:
- Chose SQLite for local storage because: single-file, no server, good for prototyping
- Will migrate to PostgreSQL for production (see docs/architecture.md)
-->

## Data Model

<!-- Learnings about data structures, formats, edge cases -->
<!-- Example:
- Measurements stored in mm (not cm) to avoid floating point issues
- Timestamps must be UTC — local time causes cross-timezone bugs
-->

## External APIs

<!-- Integration learnings, rate limits, gotchas -->

## Performance

<!-- Optimization discoveries, bottlenecks found -->

## Testing

<!-- Testing patterns, fixture tips, common mistakes -->
- **Verify the technique, not just the output**: When a bead specifies a performance technique, tests should verify the technique is actually used (e.g., assert artist is reused across frames, assert `draw_idle` is not called, verify `set_data` is used instead of creating new artists). Passing tests that only check output will miss technique violations.

## Tools & Environment

- **verify.sh**: Run as `bash verify.sh` (not `./verify.sh`). Portable across environments.
- **venv activate returns exit code 1**: On some shells (zsh), `source .venv/bin/activate` returns 1 (due to `hash -r` on empty hash table). The venv DOES activate — the exit code is misleading. NEVER use `source .venv/bin/activate && command` — the `&&` silently skips the second command.
- **bd pre-commit hook**: The beads pre-commit hook auto-stages `.beads/issues.jsonl` on every commit. This is by design — beads data travels with commits.
- **bd dep syntax**: `bd dep <blocker-id> --blocks <blocked-id>` (NOT `bd dep block <blocker> <blocked>`). The `block` subcommand doesn't exist.
- **bd close syntax**: Use `bd close <id> --reason "message"` not `bd close <id> "message"`. The reason must be passed via the `--reason` flag.
- **Coverage exclusions**: Exclude `if __name__ == "__main__":` blocks from coverage via `[tool.coverage.report]` exclude_lines in pyproject.toml to achieve realistic coverage targets.

## Beads Workflow

- **Short issue prefix**: Set `bd config set issue-prefix <2-3 chars>` early. Auto-detect from long directory names creates unwieldy IDs.
- **Task sizing**: Each bead should be completable in one agent session (~10 min productive work, <50% context window). If a bead mentions BOTH data processing AND visual rendering, split it.
- **Review pass after generation**: After creating all beads, do a review pass: `bd doctor --fix`, check deps for missing links / unnecessary serial chains / circular deps, verify descriptions are clear enough for a fresh agent.
- **Parallelization**: Explicitly note which beads at the same priority level can run concurrently.
- **Keep database small**: Run `bd cleanup` when past ~200 issues. JSONL >25k tokens causes agent file-read failures.
- **Run `bd doctor` regularly**: Handles migrations, metadata updates, git hooks, and auto-fixes structural issues.
- **One task per session, then kill**: Agents should complete one bead then stop. Fresh context = better performance + lower cost.
- **File beads liberally**: Any work >2 minutes should be its own bead. During code reviews, file beads for findings as you go.
