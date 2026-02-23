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

All scripts require `--label` to keep machines in their own lanes. Use `omarchy` for this machine, `windows-mcp` for Windows, or `all` to disable filtering.

**AFK (autonomous loop):**
```bash
# Basic — creates new branch, runs N iterations (omarchy beads only)
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 10 ~/projects/ergofigure-eye-demonstration/prompt.md --label omarchy

# Continue on existing branch
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 10 ~/projects/ergofigure-eye-demonstration/prompt.md --label omarchy --branch ralph/afk-20260221_141836

# Custom prompt (e.g. fix a GH issue — use "all" label since not bead-filtered)
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 1 fix-pr25-reviews.md --label all
```

**HITL (single iteration, interactive):**
```bash
bash ~/projects/ralph-with-beads/scripts/ralph-hitl.sh ~/projects/ergofigure-eye-demonstration ~/projects/ergofigure-eye-demonstration/prompt.md --label omarchy
```

**Via tmux (survives SSH disconnect):**
```bash
tmux new -d -s ralph 'source ~/.bashrc && bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 10 ~/projects/ergofigure-eye-demonstration/prompt.md --label omarchy'
```

### Logs

All run logs go to `<project>/ralph-runs/ralph-<timestamp>.log`. Tail live:
```bash
tail -f ~/projects/ergofigure-eye-demonstration/ralph-runs/ralph-*.log
```

### Verifying the Setup

Use the diagnostic test prompt (`prompts/diagnostic-test.md`) to verify Docker, auth, and bd without doing any real work:

```bash
bash ~/projects/ralph-with-beads/scripts/ralph-afk.sh ~/projects/ergofigure-eye-demonstration 1 ~/projects/ralph-with-beads/prompts/diagnostic-test.md --label all
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

All scripts require `--label` to keep machines in their own lanes. Use `windows-mcp` for this machine, `omarchy` for Omarchy, or `all` to disable filtering.

**AFK (autonomous loop):**
```bash
# cd to parent directory to keep paths short (spaces in paths cause issues)
cd "$HOME/OneDrive/10 Business/IT Skills"
S=ralph-with-beads/scripts/ralph-afk-windows.sh
P=ergofigure-eye-demonstration

# Basic — creates new branch, runs N iterations (windows-mcp beads only)
bash "$S" "$P" 10 "$P/prompt-mcp.md" --label windows-mcp

# Continue on existing branch
bash "$S" "$P" 30 "$P/prompt-mcp.md" --label windows-mcp --branch ralph/afk-20260221_143818

# Custom prompt (e.g. fix a GH issue — use "all" label since not bead-filtered)
bash "$S" "$P" 1 path/to/fix-prompt.md --label all
```

**No HITL script for Windows yet** — use AFK with 1 iteration.

### Logs

Same as Omarchy — logs go to `<project>/ralph-runs/ralph-<timestamp>.log`.

### Verifying the Setup

**Basic connectivity test:**
```bash
cd "$HOME/OneDrive/10 Business/IT Skills"
S=ralph-with-beads/scripts/ralph-afk-windows.sh
P=ergofigure-eye-demonstration
bash "$S" "$P" 1 ralph-with-beads/prompts/diagnostic-test.md --label all
```

**MCP GUI test** (confirms windows-mcp Snapshot/Click tools work inside Ralph):
```bash
cd "$HOME/OneDrive/10 Business/IT Skills"
S=ralph-with-beads/scripts/ralph-afk-windows.sh
P=ergofigure-eye-demonstration
bash "$S" "$P" 1 ralph-with-beads/prompts/diagnostic-mcp.md --label all
```

Expected outcome:
- Script creates a temporary branch, runs 1 iteration
- Claude prints version info (basic) or launches app and takes snapshot (MCP)
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

### Choosing the Right Prompt File

Each project has two prompt files:

| Prompt | When to Use |
|--------|------------|
| `prompt.md` | Standard TDD loop. No GUI testing. Use for Omarchy or headless-only beads. |
| `prompt-mcp.md` | TDD + MCP visual validation (Step 5). Has Snapshot/Click/Type/Shortcut/Wait allowlist. **Required for `windows-mcp` labelled beads.** |

**CRITICAL:** The `--label windows-mcp` flag only filters which beads Ralph picks up. It does NOT enable MCP testing — the prompt file controls that. If you launch with `--label windows-mcp` but pass `prompt.md`, Ralph will do standard TDD only and skip all visual verification.

```bash
# WRONG — windows-mcp beads but no GUI testing:
bash ralph-afk-windows.sh project 10 project/prompt.md --label windows-mcp

# RIGHT — windows-mcp beads WITH GUI testing:
bash ralph-afk-windows.sh project 10 project/prompt-mcp.md --label windows-mcp
```

Template source for new projects: `ralph-with-beads/templates/prompt-mcp.md`.

### Stopping Ralph Gracefully Between Iterations

There is no built-in stop file mechanism. To stop Ralph cleanly after the current iteration finishes:

**Rename the prompt file:**
```bash
mv prompt.md prompt.md.paused          # or prompt-mcp.md
```

**How it works:** The AFK script re-reads the prompt file via `cat` at the start of each iteration. With `set -eo pipefail`, the `cat` failure exits the script immediately — before any new work begins. The current iteration finishes completely (commits, logs, bead closure), then the script dies cleanly at the top of the next iteration.

**Restore when ready to restart:**
```bash
mv prompt.md.paused prompt.md
```

**Why not Ctrl+C or kill?** Killing mid-iteration risks uncommitted changes, half-written files, or open beads left `in_progress`. The rename trick guarantees a clean boundary.

### Known Issues

- **Nested session detection**: `claude -p` refuses to run inside an existing Claude Code session. Always run from a separate terminal. Error: "Claude Code cannot be launched inside another Claude Code session."
- **Paths with spaces**: Git Bash struggles with spaces in paths when arguments span line breaks. Use `cd` to shorten paths, or use `$HOME` expansion.
- **Ctrl+C may not kill Claude**: If the script hangs, use `taskkill //F //IM claude.exe` from another terminal.
- **Dolt binaries must NOT be in git**: `.beads/dolt/` is local working state that changes on every `bd` operation. If tracked in git, Dolt binary diffs cause merge conflicts on `git pull --rebase` and create persistent uncommitted changes that trigger Ralph's thrashing detection. **Fix**: ensure `.beads/.gitignore` excludes `dolt/`, `dolt-access.lock`, `ephemeral.sqlite3`, `metadata.json`. Only JSONL, config, hooks, and README should be tracked. See lessons-learned.md for the full incident.
- **Prompt file is required**: All scripts now require the prompt file as a positional argument and error if missing. See [#50](https://github.com/MG674/Ralph-with-beads/issues/50) for context.
- **Wrong prompt = no MCP testing**: Incident 2026-02-21 — 5 iterations ran with `prompt.md` instead of `prompt-mcp.md` on `windows-mcp` beads. Ralph completed beads with TDD only, no visual verification. Always double-check the prompt file matches the label.

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

---

## Before Starting an AFK Run (Checklist)

Run through this every time before launching Ralph:

1. **Commit or stash all changes** — unstaged changes cause `git pull --rebase` to fail at script startup
2. **Verify `.beads/dolt/` is NOT tracked in git** — run `git ls-files .beads/dolt/` (should return nothing). If files are tracked, fix with `git rm -r --cached .beads/dolt/` and update `.beads/.gitignore`
3. **Check you're on the right branch** (or let the script create a new one)
4. **Match prompt to label:**
   - `--label omarchy` → `prompt.md`
   - `--label windows-mcp` → `prompt-mcp.md`
5. **Ensure venv is clean** — if you recently switched branches, recreate it (see "Stale venv" below)
6. **Desktop unlocked** (Windows MCP only) — Ralph needs screen access for Snapshot/Click/Type
7. **Run from a separate terminal** (Windows only) — NOT from inside Claude Code

---

## After an AFK Run (Post-AFK Checklist)

Run through this every time after Ralph finishes, before creating a PR:

### 1. Check for Docker workarounds (Omarchy runs)

Ralph in Docker sometimes modifies `verify.sh` or `pyproject.toml` to work around the container environment (e.g. adding `PYTHONPATH`, changing `requires-python`, skipping checks). These changes break the host.

```bash
git diff main -- verify.sh pyproject.toml
```

If either file was modified and the changes look Docker-specific, revert them:
```bash
git checkout main -- verify.sh pyproject.toml
git commit -m "fix: revert Docker workarounds in verify.sh/pyproject.toml"
```

### 2. Check for removed `# type: ignore` comments

Ralph on Docker (Python 3.11) has looser type stubs than the host (Python 3.13). Ralph frequently removes `# type: ignore` comments that are needed on the host, causing mypy failures.

```bash
git diff main -- '*.py' | grep '^-.*type: ignore'
```

If you see removals, restore them. This has happened on every Omarchy run so far (PR #47, PR #65 — 16 removed in one run).

### 3. Check Gemini review comments

If the repo has Gemini code review enabled, check its comments after pushing:

```bash
gh pr view <PR> --repo <owner>/<repo> --comments
```

**Gotchas:**
- **Stale diffs**: Gemini sometimes reviews an old diff. Check comment timestamps vs the latest commit timestamp before acting on feedback.
- **False positives**: Gemini once flagged today's date as a "future date." Always sanity-check before making changes.

### 4. Recreate the venv

Ralph's branch may have added/changed dependencies. Recreate from scratch:

```bash
rm -rf .venv
python3 -m venv .venv
.venv/bin/pip install -e '.[dev]'     # Linux
.venv/Scripts/pip install -e '.[dev]'  # Windows
```

### 5. Run verify.sh on the host

```bash
bash verify.sh
```

This catches Python 3.13 incompatibilities that passed in Docker's Python 3.11 (see "Python 3.13 test failures" below).

### 6. Sync bead closures to JSONL

If Ralph closed any beads, verify the closures made it into the JSONL (see "Cross-Platform Beads Synchronisation" below). This is especially important on Omarchy where `bd close` writes to SQLite but not JSONL.

### 7. Fix issues and commit

If any checks above found problems, fix them, commit, and push to the branch before creating the PR.

---

## Common Ralph Behaviours to Watch For

### Ralph removes `# type: ignore` comments

**What happens:** Docker's Python 3.11 has looser type stubs. Ralph sees `# type: ignore` as unnecessary and removes them. On the host (Python 3.13), mypy then fails.

**How to catch:** Step 2 of the post-AFK checklist.

**Prevention:** A guardrail was added to `docs/guardrails.md` (PR #47) telling Ralph not to remove them. Ralph still does it sometimes.

### Ralph modifies verify.sh / pyproject.toml for Docker

**What happens:** Ralph encounters a Docker-specific issue (wrong Python path, missing tool) and "fixes" it by modifying `verify.sh` or `pyproject.toml`. These changes break the host build.

**Incident:** 2026-02-14. Ralph modified verify.sh to work around Docker paths. Host verify.sh broke. Had to revert.

**Prevention:** Guardrails in `prompt.md` explicitly forbid modifying these files unless the task requires it.

### Ralph test quality on Python 3.13

**What happens:** Ralph writes tests that pass on Docker's Python 3.11 but fail on the host's Python 3.13. Common patterns:

- **Wrong enum names**: Python 3.13 changed some enum `repr()` output
- **MagicMock as random seed**: Python 3.13 rejects non-numeric seeds; 3.11 was permissive
- **Async timing differences**: Tests with tight timing assumptions fail on different Python versions

**How to catch:** Step 5 of the post-AFK checklist (`bash verify.sh` on host).

### Ralph commits to the wrong branch

**What happens:** If the working directory is checked out on branch A but the script was told to continue branch B, Ralph may end up committing to branch A.

**Incident:** 2026-02-21. Windows Ralph was supposed to work on `ralph/afk-20260221_154238` but committed iterations 2-5 onto the Omarchy branch (`ralph/afk-20260221_152343`).

**Prevention:** Before starting, verify `git branch` shows the expected branch. If using `--branch`, ensure that branch exists and is checked out. Clean up stale branches from previous runs.

---

## Git Bash Tips (Windows)

### Line breaks break long commands

Git Bash on Windows wraps long lines visually, but if you paste a multi-line command from documentation, the line breaks become literal newlines and break argument parsing.

**Fix:** Use shell variables to shorten the command:

```bash
# Instead of pasting this monster:
bash ralph-with-beads/scripts/ralph-afk-windows.sh ergofigure-eye-demonstration 29 ergofigure-eye-demonstration/prompt-mcp.md --label windows-mcp

# Break it up:
S=ralph-with-beads/scripts/ralph-afk-windows.sh
P=ergofigure-eye-demonstration
bash "$S" "$P" 29 "$P/prompt-mcp.md" --label windows-mcp
```

### `grep -oP` crashes MSYS2 CLANGARM64

On Windows ARM (MSYS2 CLANGARM64), `grep -oP` returning exit code 1 (no match) inside `$(...)` command substitution with `set -eo pipefail` crashes the entire bash session — not just the command, the whole terminal.

**Fix:** Use `sed -n` instead of `grep -oP`:

```bash
# BROKEN on Windows ARM:
RESULT=$(echo "$TEXT" | grep -oP '(?<=<tag>).*(?=</tag>)')

# WORKS everywhere:
RESULT=$(echo "$TEXT" | sed -n 's/.*<tag>\(.*\)<\/tag>.*/\1/p')
```

This fix was applied to `ralph-afk-windows.sh` line 258 (thrashing detection).

### Stale venv after branch switching

After `git checkout` to a different branch, `.venv/bin/black`, `.venv/bin/ruff`, etc. may point to stale package installs from the previous branch's dependencies.

**Fix:** Delete and recreate:

```bash
rm -rf .venv
python3 -m venv .venv
.venv/Scripts/pip install -e '.[dev]'
```

---

## Branch Cleanup After PR Merge

GitHub squash-merge creates a new commit hash, so `git branch -d` fails with "not fully merged" even though the PR is merged.

**Always use `-D` (force delete) after confirming the PR is merged:**

```bash
# Verify PR is merged first
gh pr view <number> --repo <owner>/<repo> --json state --jq '.state'

# Then force-delete local branches
git branch -D ralph/afk-<timestamp>

# Delete remote branches
git push origin --delete ralph/afk-<timestamp>
```

---

## Recovering the Dolt Database (Windows)

After a PR merge that removes `.beads/dolt/` from git tracking (or after any situation where the local Dolt database is corrupt/missing but the JSONL is intact), you need to reinitialize the database from JSONL.

### Symptoms

- `bd list` returns an error about missing `repo_state.json` or database not found
- `git pull` fails with merge conflicts on `.beads/dolt/` binary files
- `bd doctor` reports "Fresh clone detected (44 issues in issues.jsonl, no database)"

### Recovery Steps

```bash
# 1. Back up the JSONL (source of truth)
cp .beads/issues.jsonl /tmp/issues.jsonl.bak

# 2. Remove corrupt/stale Dolt state
#    Keep: issues.jsonl, .gitignore, config.yaml, hooks/, README.md
#    Remove: dolt/, dolt-access.lock, metadata.json
rm -rf .beads/dolt/ .beads/dolt-access.lock .beads/metadata.json

# 3. Reinitialize — creates a fresh empty Dolt database
bd init --prefix ergo --from-jsonl

# 4. Import issues from JSONL into the new database
#    (bd init creates the DB but doesn't auto-import)
bd import -i .beads/issues.jsonl

# 5. Verify
bd list
```

### Key Detail

`bd init --from-jsonl` creates a fresh database structure but does **not** automatically hydrate it from the JSONL. You must run `bd import -i .beads/issues.jsonl` explicitly to populate the database. Without this step, `bd list` returns empty results even though the JSONL has all your issues.

### When This Happens

- After merging a PR that added `.beads/dolt/` to `.gitignore` and ran `git rm -r --cached .beads/dolt/` — the merge deletes the tracked Dolt files, leaving a corrupt local state
- After a fresh clone of a repo that correctly excludes Dolt from git
- After any accidental deletion of `.beads/dolt/`

---

## Cross-Platform Beads Synchronisation

When running Ralph on both machines, bead statuses can drift out of sync. Each machine has its own local database (SQLite on Omarchy, Dolt on Windows) and the shared JSONL in git is the sync mechanism. **This sync does not happen automatically** — you must verify it.

### The Problem

| Machine | bd version | Backend | Writes to JSONL? |
|---------|-----------|---------|-------------------|
| Omarchy (Docker) | 0.49.6 | SQLite | Only via `bd sync` inside Docker |
| Windows | 0.55.4 | Dolt | Only via `bd sync` |

`bd close` updates the local database but does **not** automatically export to JSONL. If the JSONL isn't synced and committed before merging, the other machine won't see the closures.

**Incident (2026-02-21):** Omarchy Ralph closed 14 beads during PR #65. Closures stayed in SQLite only — the JSONL in git still showed them as open. Windows had no idea they were done.

### After Every Multi-Machine Run: Verify Bead Sync

Add this to the post-AFK checklist whenever both machines have been running beads:

```bash
# On Omarchy — sync SQLite to JSONL
docker run --rm -v "$(pwd):/workspace" -w /workspace ralph-claude:latest -c "bd sync"

# On Windows — sync Dolt to JSONL
bd sync

# Then check the JSONL matches expectations
grep -c '"status":"closed"' .beads/issues.jsonl
grep -c '"status":"open"' .beads/issues.jsonl
```

### Watching for Legacy Duplicates

Omarchy's SQLite contains old beads from previous naming eras (`ergofigure-eye-demonstration-*`, `ergofigure-*`). A naive `bd sync` will dump **all** of them into the JSONL (124 legacy + 33 current in one incident).

**Safe sync approach for Omarchy:** Instead of raw `bd sync`, use a filtered export:

```bash
# On Omarchy — sync and then filter to current prefix only
docker run --rm -v "$(pwd):/workspace" -w /workspace ralph-claude:latest -c "bd sync" && \
python3 -c "
import json, os; inf = '.beads/issues.jsonl'

with open(inf) as f:
    beads = [json.loads(l) for l in f if l.strip()]
current = [b for b in beads if b['id'].startswith('ergo-')]
with open(inf + '.tmp', 'w') as f:
    for b in current:
        f.write(json.dumps(b, separators=(',', ':')) + '\n')
os.replace(inf + '.tmp', inf)
print(f'Kept {len(current)} ergo-* beads, removed {len(beads) - len(current)} legacy')
"
```

Windows (bd v0.55.4 with Dolt) doesn't have legacy beads in its database, so `bd sync` is safe there.

### Quick Status Check (Either Machine)

```bash
# Count beads by status in JSONL (works anywhere with grep)
echo "Closed: $(grep -c '"status":"closed"' .beads/issues.jsonl)"
echo "Open:   $(grep -c '"status":"open"' .beads/issues.jsonl)"
echo "WIP:    $(grep -c '"status":"in_progress"' .beads/issues.jsonl)"
echo "Total:  $(wc -l < .beads/issues.jsonl)"
```

Expected totals for ergofigure-eye-demonstration: **33 beads** (from BEAD_SPECIFICATIONS.md).

### Merge Order Matters

When both machines have JSONL changes on separate branches, merge them carefully:

1. Merge the first PR (e.g. Omarchy closures)
2. Rebase the second branch onto updated main: `git pull --rebase origin main`
3. Resolve any JSONL conflicts (usually just status fields — pick the more-progressed status)
4. Push and merge the second PR

---

## MCP GUI Testing Notes (Windows Only)

### Desktop must be unlocked

MCP tools (Snapshot, Click, Type) interact with the actual Windows desktop. The screen must be:
- Unlocked (not at lock screen)
- Not asleep
- Accessible (no full-screen app blocking)

If Ralph is running AFK with MCP and the screen locks, all visual validation steps will fail.

### Focus contention protocol (interactive sessions)

When a human operator and Claude both need the GUI:

1. Claude proposes a sequence of actions
2. Human says "go" and takes hands off keyboard/mouse
3. Claude executes all steps autonomously
4. Claude takes a final screenshot for verification
5. Claude returns focus to the terminal
6. Human reviews Claude's summary

**Key principle:** The human cannot see Claude's output while Claude controls the GUI (switching to terminal steals focus). Agree on actions BEFORE starting.

### customtkinter accessibility limitations

customtkinter buttons appear as **unnamed** in the accessibility tree — no labels exposed. Ralph must rely on vision (screenshots) + coordinates for precise interaction, not accessibility tree element names.
