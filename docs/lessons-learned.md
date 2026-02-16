# Lessons Learned

Accumulated wisdom from development. Consult when working on related areas.

---

## How to Use This File

- **Read** relevant sections before starting work in that area
- **Add** new learnings when you discover something useful
- **Keep entries concise** — this is reference material, not documentation

---

## Architecture Decisions

### Docker Base Image: Use `node:20`, NOT `ubuntu:24.04`
- Anthropic's official devcontainer uses `node:20` ([source](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile))
- The `node` user is UID 1000, matching typical Linux host users — avoids permission issues
- Ubuntu 24.04 has a `ubuntu` user at UID 1000, causing conflicts when creating a `claude` user
- Claude Code is a Node.js app — `node:20` is the natural base

### Authentication in Docker: Use `claude setup-token` + `CLAUDE_CODE_OAUTH_TOKEN`
- `claude setup-token` generates a 1-year OAuth token for headless/Docker use
- Pass via `-e CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."` — no file mounting needed
- Mounting `~/.claude/.credentials.json` is fragile (UID mismatches, permission issues)
- For API key users: use `ANTHROPIC_API_KEY` env var instead

### Model Selection in Non-Interactive Mode
- Use `claude --model sonnet` (or `opus`) flag when invoking with `-p`
- Model aliases work: `sonnet`, `opus`, `haiku` (resolve to latest versions)

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

### Docker Build Command
- Always run from **repo root**: `docker build -t ralph-claude:latest docker/`
- Do NOT `cd docker && docker build .` — fragile and easy to forget the `cd`
- Do NOT use `-f docker/Dockerfile .` — COPY context will be wrong (git-wrapper.sh is in `docker/`)
- Only `git-wrapper.sh` is baked into the image. Prompt files, guardrails, and lessons-learned are bind-mounted at runtime via the project's `/workspace` volume — so rebuilding the image is only needed when `docker/Dockerfile` or `docker/git-wrapper.sh` change

### Claude Code in Docker — Critical Requirements
1. **Install via npm**, not the curl installer: `npm install -g @anthropic-ai/claude-code`
   - The `curl -fsSL https://claude.ai/install | sh` installer silently fails in Docker builds ([issue #22536](https://github.com/anthropics/claude-code/issues/22536))
2. **Do NOT use `--read-only` filesystem** — Claude Code needs to write state files to `~/.claude/`
3. **Do NOT use `noexec` on tmpfs** — Node.js needs exec permission in `/tmp`
4. **Do NOT run as root with `--dangerously-skip-permissions`** — blocked by security check
   - Workaround: `IS_SANDBOX=1` env var bypasses the check ([issue #3490](https://github.com/anthropics/claude-code/issues/3490))
   - Better: just run as non-root user (UID 1000)
5. **Set `NODE_OPTIONS="--max-old-space-size=4096"`** — prevents OOM in large projects
6. **Set `CLAUDE_CONFIG_DIR`** env var to control where Claude writes config

### Claude Code Env Vars Reference

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token auth (from `claude setup-token`) |
| `ANTHROPIC_API_KEY` | API key auth |
| `CLAUDE_CONFIG_DIR` | Override config directory location |
| `IS_SANDBOX=1` | Allow `--dangerously-skip-permissions` as root |
| `NODE_OPTIONS` | Node.js memory settings |

### Beads Git Config: Set `beads.role`
- Run `git config beads.role developer` in each project repo after init
- Without this, every `bd` command prints `warning: beads.role not configured`
- Harmless but noisy — set it early to keep output clean

### Beads Package Name
- Correct: `npm install -g @beads/bd` (the `bd` CLI)
- Wrong: `npm install -g beads` (installs unrelated package)

### Docker `--user` Flag and HOME
- When using `--user 1000:1000` to override the container user, `HOME` may not be set correctly
- Always pair with `-e HOME=/home/node` (or whatever the user's home is)
- Without this, Claude Code can't find `~/.claude/` config

### Token Persistence for Docker Auth
- Save token to `~/.claude-oauth-token` file: `echo "$CLAUDE_CODE_OAUTH_TOKEN" > ~/.claude-oauth-token && chmod 600 ~/.claude-oauth-token`
- Ralph scripts auto-load from this file if env var isn't set (survives SSH disconnects)
- Also persist in `~/.bashrc` for interactive use

### After Cloning Ralph Scripts
- Scripts need `chmod +x` after cloning: `chmod +x scripts/ralph-hitl.sh scripts/ralph-afk.sh`
- Git doesn't always preserve execute permissions across platforms

### SSH Sessions and Environment Variables
- `export VAR=value` is lost when SSH disconnects
- Always persist to `~/.bashrc` AND `~/.zshrc` (check `echo $SHELL` to confirm which is active)
- After reconnecting: `source ~/.bashrc` to reload

### Pasting Commands from Claude Code (Windows) into Git Bash SSH
- **Maximize the Claude Code window width** before copying — minimises line-wrapping issues that break commands when pasted into the SSH session
- **Use Ctrl+C/V in Claude Code** (Windows native), but **right-click copy/paste in Git Bash** — avoids generating spurious characters
- Long single-line commands often wrap and get split into multiple lines on paste — use shell variables or Python scripts for complex operations

### Before Launching AFK Runs
- **Commit beads changes first**: `git add .beads/issues.jsonl && git commit -m "chore: update beads database"` — if you've run `bd create` or `bd update` manually, the JSONL is unstaged. The AFK script does `git pull --rebase` at start, which fails with unstaged changes. The script logs a warning but continues on a stale base.
- **Check working tree is clean**: `git status` should show nothing unstaged before running `ralph-afk.sh`

### Monitoring AFK Progress
- Log location: `<project>/ralph-runs/ralph-<timestamp>.log`
- List logs (newest first): `ls --sort=newest <project>/ralph-runs/ | head -3` (Omarchy uses `eza` aliased to `ls` — standard `ls -lt` won't work)
- Watch live: `tail -f <project>/ralph-runs/ralph-<timestamp>.log`
- Check process still running: `ps aux | grep ralph`
- The AFK script creates a branch named `ralph/afk-<timestamp>` — your shell prompt will show it

### Official References
- [Anthropic devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile)
- [Anthropic devcontainer docs](https://code.claude.com/docs/en/devcontainer)
- [Docker official Claude Code guide](https://docs.docker.com/ai/sandboxes/claude-code/)
- [Claude Code authentication docs](https://code.claude.com/docs/en/authentication)
