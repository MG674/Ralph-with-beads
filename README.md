# Ralph with Beads

My implementation of the Ralph loop technique using Beads for task visibility.

## What Is This?

A complete workflow for autonomous AI-driven development combining:

- **[Ralph Loop](https://ghuntley.com/ralph/)** — Iterative AI coding until tasks complete
- **[Beads](https://github.com/steveyegge/beads)** — Git-backed task management for AI agents
- **TDD** — Test-driven development with full quality checks
- **Docker** — Isolated, reproducible execution environment

## Quick Start

1. **Set up a new project:**
   ```bash
   cd your-project
   bd init                              # Initialize Beads
   cp templates/CLAUDE.md ./CLAUDE.md   # Copy and customize
   cp templates/prompt.md ./prompt.md   # Copy and customize
   cp templates/verify-python.sh ./verify.sh  # Or verify-javascript.sh
   chmod +x verify.sh
   mkdir -p docs
   cp docs/guardrails.md ./docs/
   cp docs/lessons-learned.md ./docs/
   ```

2. **Build the Docker image:**
   ```bash
   cd docker
   docker build -t ralph-claude:latest .
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
- **[scripts/](scripts/)** — Ralph execution scripts
- **[prompts/](prompts/)** — Prompts for planning and task generation

## Key Resources

- [Geoffrey Huntley — Ralph Wiggum](https://ghuntley.com/ralph/) — Original technique
- [Matt Pocock — 11 Tips](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — Best practices
- [Steve Yegge — Beads](https://github.com/steveyegge/beads) — Task management
- [Beads Viewer (bv)](https://github.com/Dicklesworthstone/beads_viewer) — Visual task dashboard

## License

MIT — See [LICENSE](LICENSE)
