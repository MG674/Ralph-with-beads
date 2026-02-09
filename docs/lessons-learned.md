# Lessons Learned

Accumulated wisdom from development. Consult when working on related areas.

---

## How to Use This File

- **Read** relevant sections before starting work in that area
- **Add** new learnings when you discover something useful
- **Keep entries concise** — this is reference material, not documentation

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
- Ankle measurements stored in mm (not cm) to avoid floating point issues
- Timestamps must be UTC — local time causes cross-timezone bugs
-->

## External APIs

<!-- Integration learnings, rate limits, gotchas -->
<!-- Example:
- NHS API rate limit: 100 requests/minute
- AWS S3 requires explicit region configuration
-->

## Performance

<!-- Optimization discoveries, bottlenecks found -->
<!-- Example:
- CSV parsing slow for files >10MB — consider chunked processing
- Chart redraws expensive — debounce window resize events
-->

## Testing

<!-- Testing patterns, fixture tips, common mistakes -->
<!-- Example:
- Pytest fixtures with cleanup must use yield, not return
- Mock datetime.now() at the module level, not instance level
-->

## Tools & Environment

<!-- Setup tips, configuration gotchas -->
<!-- Example:
- ruff and black can conflict — run black after ruff
- mypy needs explicit py.typed marker for package exports
-->
