# Running Ralph — Setup and Operations Guide

How to get Ralph running on each machine, verify it works, and operate it day-to-day.

**Status:** Work in progress. Omarchy documented, Windows MCP TBD.

---

## Omarchy (Linux, Docker-based)

### Architecture

Ralph runs inside Docker on Omarchy. The chain is:

```
ralph-afk.sh (host bash)
  → sources CLAUDE_CODE_OAUTH_TOKEN from ~/.bashrc
  → creates feature branch
  → docker run ralph-claude:latest -c "claude -p ..."
      → Claude Code 2.1.42 (npm install inside image)
      → Python 3.11.2 (Debian bookworm)
      → bd 0.49.6 (SQLite backend, reads/writes JSONL)
      → git-wrapper.sh intercepts git for audit
```

### Prerequisites

| Component | Location | Version | Notes |
|-----------|----------|---------|-------|
| Docker image | `ralph-claude:latest` | Built 2026-02-15 | `docker build -t ralph-claude:latest docker/` from ralph-with-beads root |
| OAuth token | `~/.bashrc` | 1-year token | `export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."` |
| AFK script | `~/projects/ralph-with-beads/scripts/ralph-afk.sh` | — | Template script, not project-specific |
| HITL script | `~/projects/ralph-with-beads/scripts/ralph-hitl.sh` | — | Single iteration, interactive |
| Project prompt | `<project>/prompt.md` | — | Bead workflow prompt, lives in each project repo |
| bd in Docker | Inside image | 0.49.6 | SQLite backend. Dolt upgrade blocked (GLIBC 2.38 needed, bookworm has 2.36) |

### Authentication

The OAuth token is stored in `~/.bashrc` as an environment variable:

```bash
export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."
```

The AFK/HITL scripts also check `~/.claude-oauth-token` as a fallback (file-based, survives SSH disconnects without sourcing `.bashrc`).

The token is passed into Docker via `-e CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"`.

**Important:** When running via `tmux` or non-interactive SSH, `~/.bashrc` may not be sourced. Either:
- `source ~/.bashrc` before running the script, or
- Store the token in `~/.claude-oauth-token` as well

### Running

**AFK (autonomous loop):**
```bash
# Basic — creates new branch, runs N iterations
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 10

# Continue on existing branch
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 10 --branch ralph/afk-20260221_141836

# Custom prompt (e.g. fix a GH issue instead of beads)
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 1 fix-pr25-reviews.md
```

**HITL (single iteration, interactive):**
```bash
bash ~/projects/ralph-with-beads/scripts/ralph-hitl.sh ~/projects/ergofigure-eye-demonstration
```

**Via tmux (survives SSH disconnect):**
```bash
tmux new -d -s ralph 'source ~/.bashrc && bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 10'
```

### Logs

All run logs go to `<project>/ralph-runs/ralph-<timestamp>.log`. Tail live:
```bash
tail -f ~/projects/ergofigure-eye-demonstration/ralph-runs/ralph-*.log
```

### Verifying the Setup

Use the diagnostic test prompt (`prompts/diagnostic-test.md`) to verify Docker, auth, and bd without doing any real work:

```bash
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 1 ~/projects/ralph-with-beads/prompts/diagnostic-test.md
```

Expected outcome:
- Script creates a temporary branch, runs 1 iteration
- Claude prints version info, git status, bd list
- Outputs `<promise>COMPLETE</promise>`
- Script pushes branch and exits

Check the log for diagnostics. Clean up after:
```bash
cd ~/projects/ergofigure-eye-demonstration
git checkout main
git branch -D ralph/afk-<timestamp>
git push origin --delete ralph/afk-<timestamp>
```

**Verified working:** 2026-02-21. Claude Code 2.1.42, bd 0.49.6, Python 3.11.2 inside Docker.

### Rebuilding the Docker Image

If the image needs updating (new Claude Code version, new tools):

```bash
cd ~/projects/ralph-with-beads
docker build -t ralph-claude:latest docker/
```

### Known Issues

- **bd 0.49.6 in Docker vs 0.55.4 on Windows**: Different backends (SQLite vs Dolt). JSONL is the sync mechanism. See MEMORY.md for details.
- **`claude` is not installed on Omarchy host**: Only inside Docker. Don't try to run `claude` directly.
- **Docker binary execution**: Running `docker run ralph-claude:latest <command>` without `-c` flag fails because the entrypoint is `/bin/bash`. Always use `-c "..."` to pass commands.

---

## Windows (MCP-based)

TBD — will document the Windows AFK script (`ralph-afk-windows.sh`), MCP prompt template, and visual verification workflow.
