# Security Test Suite — Ralph-with-beads

Manual and automated tests to validate security hardening.

Run automated tests: `./scripts/run-security-tests.sh`

---

## Test 1: Git Wrapper Blocks Force-Push

**Objective:** Verify `git push -f` is blocked

**Procedure:**

1. Build image: `docker build -t ralph-claude-test:latest docker/`
2. Run container: `docker run --rm -it -w /workspace ralph-claude-test:latest /bin/bash`
3. Inside container: `git push -f origin HEAD`

**Expected Result:** Error message: "Force push is not allowed by security policy"

---

## Test 2: Git Wrapper Blocks Main Pushes

**Objective:** Verify direct pushes to main/master are blocked

**Procedure:**

1. Inside Docker container (from Test 1)
2. Try: `git push origin main`

**Expected Result:** Error message: "Cannot push directly to main/master — create PR instead"

---

## Test 3: Container Runs as Non-Root

**Objective:** Verify container user is non-root

**Procedure:**

```bash
docker run --rm ralph-claude-test:latest whoami
```

**Expected Result:** Output: `claude` (not `root`)

---

## Test 4: Credential File Permissions

**Objective:** Verify credentials are mounted read-only

**Procedure:**

1. Create test credential file: `echo '{"key":"test"}' > /tmp/test-cred.json`
2. Mount in container:
   `docker run -v /tmp/test-cred.json:/cred.json:ro -it ralph-claude-test:latest bash`
3. Try to modify: `echo '{}' > /cred.json`

**Expected Result:** Permission denied error

---

## Test 5: Docker Timeout Kills Hung Containers

**Objective:** Verify timeout kills long-running processes

**Procedure:**

```bash
timeout 10 docker run --rm ralph-claude-test:latest sleep 60
echo $?
```

**Expected Result:** Exit code 124 (timeout killed process)

---

## Test 6: Memory Limit Prevents Runaway Allocation

**Objective:** Verify `--memory=4g` prevents memory exhaustion

**Procedure:**

```bash
docker run --rm --memory=4g ralph-claude-test:latest python3 -c "
import array
try:
    a = array.array('d', range(1000000000))
except MemoryError:
    print('MemoryError caught — limit working')
"
```

**Expected Result:** Process is killed or MemoryError raised (not system crash)

---

## Test 7: Thrashing Detection Works

**Objective:** Verify 5-iteration failure pattern detection

**Procedure:**

1. Modify ralph-afk.sh to use test prompt with synthetic failures
2. Create beads that always fail in same way
3. Run: `./scripts/ralph-afk.sh . 10 prompt.md`
4. After 3 consecutive same failures, should exit with THRASHING

**Expected Result:** Script exits with "RALPH THRASHING" and failure pattern logged

---

## Test 8: Input Validation Rejects Invalid Paths

**Objective:** Verify scripts reject non-git directories

**Procedure:**

```bash
mkdir -p /tmp/not-git
./scripts/ralph-hitl.sh /tmp/not-git
```

**Expected Result:** Error: "Not a git repository: /tmp/not-git" and exit 1

---

## Test 9: Git Error Handling Fails Loudly

**Objective:** Verify git fetch/pull failures cause script exit

**Procedure:**

1. Create test repo with invalid remote
2. Set remote to non-existent: `git remote set-url origin https://invalid.test/repo.git`
3. Run ralph-hitl.sh

**Expected Result:** Script exits with error message, doesn't silently continue

---

## Test 10: Prompt File Validation

**Objective:** Verify script validates prompt file exists

**Procedure:**

```bash
./scripts/ralph-hitl.sh . /nonexistent/prompt.md
```

**Expected Result:** Error: "Prompt file not found: /nonexistent/prompt.md" and exit 1

---

## Test 11: Git Wrapper Blocks Hard Reset

**Objective:** Verify `git reset --hard` is blocked

**Procedure:**

1. Inside Docker container
2. Try: `git reset --hard HEAD~1`

**Expected Result:** Error message: "Hard reset is not allowed by security policy"

---

## Test 12: Git Wrapper Blocks Branch Deletion

**Objective:** Verify `git branch -D` is blocked

**Procedure:**

1. Inside Docker container
2. Try: `git branch -D some-branch`

**Expected Result:** Error message: "Branch deletion is not allowed by security policy"

---

## Automated Test Runner

See `scripts/run-security-tests.sh` for automated validation of tests 1-3, 5, 8, 10-12.
