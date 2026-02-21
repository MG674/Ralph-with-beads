# Running Ralph — Setup and Operations Guide

How to get Ralph running on each machine, verify it works, and operate it day-to-day.

**Status:** Both machines documented and verified working (2026-02-21).

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

## Windows (Native, Git Bash)

### Architecture

Ralph runs natively on Windows (no Docker). The chain is:

```
ralph-afk-windows.sh (Git Bash)
  → auth via ~/.claude/ credentials (Max subscription) or env vars
  → creates feature branch
  → claude --dangerously-skip-permissions --model sonnet -p "..."
      → Claude Code 2.1.50 (npm global install)
      → Python 3.13.7 (host Python)
      → bd 0.55.4 (Dolt backend)
      → MCP servers available (windows-mcp for GUI testing)
```

### Prerequisites

| Component | Location | Version | Notes |
|-----------|----------|---------|-------|
| Claude Code | npm global | 2.1.50 | `npm install -g @anthropic-ai/claude-code` |
| Auth | `~/.claude/` | Max subscription | OAuth credentials stored by `claude login` |
| AFK script | `ralph-with-beads/scripts/ralph-afk-windows.sh` | — | Windows-specific (native, no Docker) |
| bd CLI | `~/.local/bin/bd.exe` | 0.55.4 | Dolt backend. Manual install (npm postinstall fails on ARM) |
| Python | System | 3.13.7 | Host Python, not containerised |
| MCP | `~/.claude.json` | windows-mcp | `uvx windows-mcp` — Snapshot, Click, Type, Shortcut, Wait |

### Authentication

Windows uses the Claude Max subscription credentials stored by `claude login`. No environment variable needed — credentials live in `~/.claude/`.

Alternative: set `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` as environment variables.

### Running

**Important:** Cannot run from inside a Claude Code session (nested session detection). Always use a separate terminal.

**AFK (autonomous loop):**
```bash
# cd to parent directory to keep paths short (spaces in paths cause issues)
cd "$HOME/OneDrive/10 Business/IT Skills"

# Basic — creates new branch, runs N iterations
bash ralph-with-beads/scripts/ralph-afk-windows.sh ergofigure-eye-demonstration 10 ergofigure-eye-demonstration/prompt.md

# Continue on existing branch
bash ralph-with-beads/scripts/ralph-afk-windows.sh ergofigure-eye-demonstration 10 ergofigure-eye-demonstration/prompt.md --branch ralph/afk-20260221_143818

# Custom prompt (e.g. fix a GH issue instead of beads)
bash ralph-with-beads/scripts/ralph-afk-windows.sh ergofigure-eye-demonstration 1 path/to/fix-prompt.md
```

**No HITL script for Windows yet** — use AFK with 1 iteration.

### Logs

Same as Omarchy — logs go to `<project>/ralph-runs/ralph-<timestamp>.log`.

### Verifying the Setup

```bash
cd "$HOME/OneDrive/10 Business/IT Skills"
bash ralph-with-beads/scripts/ralph-afk-windows.sh ergofigure-eye-demonstration 1 ralph-with-beads/prompts/diagnostic-test.md
```

Expected outcome:
- Script creates a temporary branch, runs 1 iteration
- Claude prints version info, git status, bd list
- Outputs `<promise>COMPLETE</promise>`
- Script pushes branch and exits

Clean up after:
```bash
cd ergofigure-eye-demonstration
git checkout main
git restore .beads/issues.jsonl
git branch -D ralph/afk-<timestamp>
git push origin --delete ralph/afk-<timestamp>
```

**Verified working:** 2026-02-21. Claude Code 2.1.50, bd 0.55.4, Python 3.13.7 native.

### Known Issues

- **Nested session detection**: `claude -p` refuses to run inside an existing Claude Code session. Always run from a separate terminal. Error: "Claude Code cannot be launched inside another Claude Code session."
- **Paths with spaces**: Git Bash struggles with spaces in paths when arguments span line breaks. Use `cd` to shorten paths, or use `$HOME` expansion.
- **Ctrl+C may not kill Claude**: If the script hangs, use `taskkill //F //IM claude.exe` from another terminal.
- **bd Dolt JSONL changes**: bd v0.55.4 (Dolt backend) may modify `.beads/issues.jsonl` during runs. The push step may fail with "uncommitted changes detected". Restore with `git checkout -- .beads/issues.jsonl` after.
- **Prompt file is not optional**: If the prompt file argument is lost (e.g. line break splitting args), the script silently defaults to `$PROJECT_DIR/prompt.md`. See [#50](https://github.com/MG674/Ralph-with-beads/issues/50).

---

## Key Differences Between Machines

| Aspect | Omarchy | Windows |
|--------|---------|---------|
| Execution | Docker container | Native (Git Bash) |
| Claude Code | 2.1.42 (in image) | 2.1.50 (npm global) |
| Python | 3.11.2 (Debian) | 3.13.7 (host) |
| bd | 0.49.6 (SQLite) | 0.55.4 (Dolt) |
| Auth | OAuth token env var | Max subscription credentials |
| MCP | Not available | windows-mcp for GUI testing |
| Script | `ralph-afk.sh` | `ralph-afk-windows.sh` |
| Kill stuck process | `docker kill` | `taskkill //F //IM claude.exe` |
