# Ralph with Beads

My implementation of the Ralph loop technique using Beads for task visibility.

## What Is This?

A complete workflow for autonomous AI-driven development combining:

- **[Ralph Loop](https://ghuntley.com/ralph/)** — Iterative AI coding until tasks complete
- **[Beads](https://github.com/steveyegge/beads)** — Git-backed task management for AI agents
- **TDD** — Test-driven development with full quality checks
- **Docker** — Isolated, reproducible execution environment

## Security Notice

This setup is designed for **single-user development VMs** (e.g. a personal Linux box you SSH into). It is **not suitable for shared or multi-user environments** without additional hardening:

- **Tokens passed via Docker `-e` flags** are visible to any user on the host who can run `docker inspect` or `ps`. On a single-user VM this is acceptable; on a shared machine it leaks credentials.
- **The git security wrapper** intercepts dangerous operations (force-push, push to main, branch deletion, hard reset) via PATH precedence inside the container. It is a safety net, not a sandbox — a determined actor could bypass it.
- **`--dangerously-skip-permissions`** is required for headless Claude Code execution. The security boundary is the Docker container itself (memory/CPU limits, non-root user, git wrapper), not the flag.

If you adapt this for a multi-user or production environment, consider: Docker secrets or mounted credential files, a read-only container filesystem, network isolation, and a dedicated audit logging pipeline.

## Quick Start

1. **Set up a new project:**
   ```bash
   # Automated (recommended)
   ./scripts/bootstrap-project.sh

   # Or manual setup — see ralph-loop-workflow.md Phase 0
   ```

2. **Build the Docker image (from repo root):**
   ```bash
   docker build -t ralph-claude:latest docker/
   ```

3. **Create your PRD and tasks:**
   ```bash
   # Use the planning interview to gather requirements
   # Then create beads from the PRD
   bd create "First task" feature 1
   bd create "Second task" feature 2
   ```

4. **Run Ralph:**
   ```bash
   # Human-in-the-loop (watch each iteration)
   ./scripts/ralph-hitl.sh /path/to/project
   
   # AFK (autonomous, N iterations)
   ./scripts/ralph-afk.sh /path/to/project 15
   ```

## Documentation

- **[ralph-loop-workflow.md](ralph-loop-workflow.md)** — Complete workflow documentation
- **[templates/](templates/)** — Template files for new projects
- **[templates/closeout-checklist.md](templates/closeout-checklist.md)** — Project close-out checklist
- **[scripts/](scripts/)** — Ralph execution scripts (bootstrap, close-out, HITL, AFK)
- **[prompts/](prompts/)** — Prompts for planning and task generation

## Key Resources

- [Geoffrey Huntley — Ralph Wiggum](https://ghuntley.com/ralph/) — Original technique
- [Matt Pocock — 11 Tips](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — Best practices
- [Steve Yegge — Beads](https://github.com/steveyegge/beads) — Task management
- [Beads Viewer (bv)](https://github.com/Dicklesworthstone/beads_viewer) — Visual task dashboard

## License

MIT — See [LICENSE](LICENSE)
