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

## Prerequisites

- **Docker Desktop 4.50+** — container isolation for AFK runs
- **tmux** — session persistence for SSH-based workflows (survives disconnects)
- **GitHub CLI (`gh`)** — PR creation, issue management
- **Claude Code** — `curl -fsSL https://claude.ai/install.sh | bash` or npm
- **Beads CLI** — `npm install -g @beads/bd` (NOT `npm install -g beads`)
- **Python 3.11+** with venv — for project development
- **Git** with SSH keys configured for your repo

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

## Running with tmux

```bash
# SSH into your dev machine
ssh user@host

# Create a tmux session
tmux new -s ralph

# Run Ralph AFK
bash scripts/ralph-afk.sh /path/to/project 15

# Detach: Ctrl+B then d (safe to disconnect SSH)
# Reattach later: tmux attach -t ralph
# Monitor logs: tail -f /path/to/project/ralph-runs/ralph-*.log
```

## Documentation

- **[ralph-loop-workflow.md](ralph-loop-workflow.md)** — Complete workflow documentation
- **[templates/](templates/)** — Template files for new projects
- **Prompt templates:**
  - `templates/prompt.md` — Standard loop prompt. Copy to your project as `prompt.md`, replace `[PROJECT_NAME]` and context file references.
  - `templates/custom-prompt.md` — For one-off fixes. Copy, fill in task details, pass as prompt file argument.
  - **Never hand-craft continuation prompts** — the standard template handles `in_progress` beads automatically.
- **[templates/closeout-checklist.md](templates/closeout-checklist.md)** — Project close-out checklist
- **[scripts/](scripts/)** — Ralph execution scripts (bootstrap, close-out, HITL, AFK)
- **[prompts/](prompts/)** — Prompts for planning and task generation

## Key Resources

- [Geoffrey Huntley — Ralph Wiggum](https://ghuntley.com/ralph/) — Original technique
- [Matt Pocock — 11 Tips](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum) — Best practices
- [Steve Yegge — Beads](https://github.com/steveyegge/beads) — Task management
- [Beads Viewer (bv)](https://github.com/Dicklesworthstone/beads_viewer) — Visual task dashboard

## Lessons from Production Use

- Always start with HITL mode (`ralph-hitl.sh`) to refine prompts before going AFK
- Cap AFK iterations (15-20 for focused work, 30+ for bulk)
- Check `git diff main -- verify.sh pyproject.toml` after AFK runs for Docker workarounds
- Review Gemini/bot comments before merging PRs
- Keep beads small (2-5 min of work each) for best loop performance
- Run `bd doctor` regularly; `bd cleanup` when past 200 issues
- On zsh: never use `source .venv/bin/activate &&` — use `bash verify.sh` directly
- OAuth token: store in `~/.claude-oauth-token` file or `~/.bashrc` export (survives SSH disconnects)

## License

MIT — See [LICENSE](LICENSE)
