#!/bin/bash
set -e

# =============================================================================
# bootstrap-project.sh — Automates Phase 0 project initialisation
#
# Creates or configures a project repo with the Ralph-with-beads workflow.
# Handles GitHub org selection, scaffolding, CI, and repo settings.
#
# Usage: ./scripts/bootstrap-project.sh
# =============================================================================

RALPH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GEMINI_INSTALL_ID="96380478"

# --- Helpers -----------------------------------------------------------------

bold()  { printf '\033[1m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }
yellow(){ printf '\033[33m%s\033[0m' "$1"; }
red()   { printf '\033[31m%s\033[0m' "$1"; }

confirm() {
    local prompt="$1" default="${2:-Y}"
    if [ "$default" = "Y" ]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi
    read -r -p "$prompt " answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy] ]]
}

prompt_input() {
    local prompt="$1" default="$2" result
    if [ -n "$default" ]; then
        read -r -p "$prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -r -p "$prompt: " result
        echo "$result"
    fi
}

# Read a top-level key from a JSON file, output as JSON string
read_json_key() {
    local file="$1" key="$2"
    python3 -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1]))[sys.argv[2]]))" "$file" "$key" 2>/dev/null \
        || python -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1]))[sys.argv[2]]))" "$file" "$key"
}

# Merge required status checks into branch protection JSON
merge_status_checks() {
    local base_json="$1"
    python3 -c "
import json, sys
data = json.loads(sys.argv[1])
data['required_status_checks'] = {'strict': True, 'contexts': ['lint-and-test']}
print(json.dumps(data))
" "$base_json" 2>/dev/null \
    || python -c "
import json, sys
data = json.loads(sys.argv[1])
data['required_status_checks'] = {'strict': True, 'contexts': ['lint-and-test']}
print(json.dumps(data))
" "$base_json"
}

# Copy a template file with diff/skip/overwrite handling for existing files
copy_template() {
    local src="$1" dest="$2" label="$3"
    if [ ! -f "$src" ]; then
        echo "  $(yellow 'SKIP') $label (template not found: $src)"
        return
    fi
    if [ -f "$dest" ]; then
        if diff -q "$src" "$dest" > /dev/null 2>&1; then
            echo "  $(green 'OK')   $label (identical, skipped)"
            return
        fi
        echo ""
        echo "  $(yellow 'DIFF') $label — existing file differs from template:"
        diff -u "$dest" "$src" || true
        echo ""
        while true; do
            read -r -p "  [S]kip / [O]verwrite / [D]iff again? " choice
            case "$choice" in
                [Ss]) echo "  Skipped $label"; return ;;
                [Oo]) cp "$src" "$dest"; echo "  $(green 'Overwritten') $label"; return ;;
                [Dd]) diff -u "$dest" "$src" || true ;;
                *) echo "  Please enter S, O, or D" ;;
            esac
        done
    else
        cp "$src" "$dest"
        echo "  $(green 'Created') $label"
    fi
}

# --- Prerequisites -----------------------------------------------------------

echo ""
echo "$(bold '=== Ralph-with-beads Project Bootstrap ===')"
echo ""

for cmd in gh git; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "$(red 'ERROR'): $cmd is not installed."
        exit 1
    fi
done

if ! command -v bd &> /dev/null; then
    echo "$(yellow 'WARNING'): bd (beads) is not installed. bd init will be skipped."
    echo "  Install: npm install -g beads"
    HAVE_BD=false
else
    HAVE_BD=true
fi

# Verify gh is authenticated
if ! gh auth status &> /dev/null 2>&1; then
    echo "$(red 'ERROR'): gh is not authenticated. Run: gh auth login"
    exit 1
fi

# --- Step 1: Project Identity ------------------------------------------------

echo "$(bold 'Step 1: Project Identity')"
echo ""

PROJECT_NAME=""
while [ -z "$PROJECT_NAME" ]; do
    PROJECT_NAME=$(prompt_input "Project name (repo name)")
done
PROJECT_DESC=$(prompt_input "Project description (optional)" "")

echo ""
if confirm "Create a NEW repository?" "Y"; then
    MODE="new"
else
    MODE="existing"
fi

# --- Step 2a: New Repo -------------------------------------------------------

if [ "$MODE" = "new" ]; then
    echo ""
    echo "$(bold 'Step 2: GitHub Repository Setup')"
    echo ""

    # Fetch orgs dynamically
    GH_USER=$(gh api user --jq '.login')
    ORGS=$(gh api user/orgs --jq '.[].login' 2>/dev/null || true)

    echo "Available owners:"
    echo "  1) $GH_USER (personal)"
    i=2
    DEFAULT_CHOICE=1
    declare -a ORG_LIST=("$GH_USER")
    while IFS= read -r org; do
        [ -z "$org" ] && continue
        ORG_LIST+=("$org")
        echo "  $i) $org"
        if [ "$org" = "VM-General-Services-Ltd" ]; then
            DEFAULT_CHOICE=$i
        fi
        ((i++))
    done <<< "$ORGS"

    echo ""
    OWNER_IDX=$(prompt_input "Select owner" "$DEFAULT_CHOICE")
    OWNER="${ORG_LIST[$((OWNER_IDX - 1))]}"
    echo "  Owner: $OWNER"

    echo ""
    if confirm "Private repository?" "Y"; then
        VISIBILITY="private"
    else
        VISIBILITY="public"
    fi

    # License
    echo ""
    echo "$(bold 'License:')"
    echo "  Default: VM General Services Ltd / Ergofigure Ltd proprietary"
    if confirm "  Use this license?" "Y"; then
        LICENSE_SRC="$RALPH_DIR/templates/LICENSE-proprietary.txt"
    else
        echo ""
        echo "  Options:"
        echo "    1) MIT"
        echo "    2) None (no license file)"
        echo "    3) Custom (provide path)"
        LIC_CHOICE=$(prompt_input "  Select" "1")
        case "$LIC_CHOICE" in
            1) LICENSE_SRC="MIT" ;;
            2) LICENSE_SRC="" ;;
            3) LICENSE_SRC=$(prompt_input "  Path to license file") ;;
            *) LICENSE_SRC="" ;;
        esac
    fi

    # Create the repo
    echo ""
    echo "Creating repository $OWNER/$PROJECT_NAME ($VISIBILITY)..."

    CREATE_ARGS=("$OWNER/$PROJECT_NAME" "--$VISIBILITY" "--clone")
    if [ -n "$PROJECT_DESC" ]; then
        CREATE_ARGS+=("--description" "$PROJECT_DESC")
    fi
    if [ "$LICENSE_SRC" = "MIT" ]; then
        CREATE_ARGS+=("--license" "mit")
        LICENSE_SRC=""  # gh handles it
    fi

    gh repo create "${CREATE_ARGS[@]}"
    cd "$PROJECT_NAME"
    PROJECT_DIR="$(pwd)"

    # Copy proprietary license if selected
    if [ -n "$LICENSE_SRC" ] && [ -f "$LICENSE_SRC" ]; then
        cp "$LICENSE_SRC" LICENSE
        echo "  $(green 'Created') LICENSE"
    fi

# --- Step 2b: Existing Repo --------------------------------------------------

else
    echo ""
    echo "$(bold 'Step 2: Connect to Existing Repository')"
    echo ""
    echo "Provide one of:"
    echo "  - Local path (e.g. /home/user/my-project)"
    echo "  - GitHub URL (e.g. https://github.com/owner/repo)"
    echo "  - owner/repo shorthand (e.g. VM-General-Services-Ltd/my-project)"
    echo ""

    REPO_REF=$(prompt_input "Repository location")

    if [ -d "$REPO_REF" ]; then
        # Local path
        cd "$REPO_REF"
        if ! git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
            echo "$(red 'ERROR'): $REPO_REF is not a git repository"
            exit 1
        fi
    elif [[ "$REPO_REF" == *"github.com"* ]] || [[ "$REPO_REF" == */* ]]; then
        # GitHub URL or owner/repo
        echo "Cloning $REPO_REF..."
        gh repo clone "$REPO_REF"
        CLONE_DIR=$(basename "$REPO_REF" .git)
        cd "$CLONE_DIR"
    else
        echo "$(red 'ERROR'): Could not interpret '$REPO_REF' as a path, URL, or owner/repo"
        exit 1
    fi

    PROJECT_DIR="$(pwd)"

    # Detect owner from remote
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [ -n "$REMOTE_URL" ]; then
        OWNER=$(echo "$REMOTE_URL" | sed -E 's#.*[:/]([^/]+)/[^/]+(\.git)?$#\1#')
        echo "  Detected owner: $OWNER"
    else
        OWNER=""
    fi

    # Check for existing beads
    if [ -d ".beads" ] && [ "$HAVE_BD" = true ]; then
        echo ""
        echo "  Existing .beads/ directory found. Current tasks:"
        bd list || true
    fi
fi

# --- Step 3: Language Selection -----------------------------------------------

echo ""
echo "$(bold 'Step 3: Language Selection')"
echo ""
echo "  1) Python"
echo "  2) JavaScript"
echo "  3) Other (skip language-specific files)"
echo ""
LANG_CHOICE=$(prompt_input "Select language" "1")

case "$LANG_CHOICE" in
    1) LANGUAGE="python" ;;
    2) LANGUAGE="javascript" ;;
    *)
        LANGUAGE="other"
        echo ""
        echo "  $(yellow 'Note'): You will need to create verify.sh, .gitignore, and"
        echo "  .github/workflows/ci.yml manually for your language."
        ;;
esac

# --- Step 4: Scaffold Ralph Files --------------------------------------------

echo ""
echo "$(bold 'Step 4: Scaffolding Ralph Workflow Files')"
echo ""

mkdir -p docs ralph-runs

copy_template "$RALPH_DIR/templates/CLAUDE.md" "CLAUDE.md" "CLAUDE.md"
copy_template "$RALPH_DIR/templates/prompt.md" "prompt.md" "prompt.md"
copy_template "$RALPH_DIR/templates/coding-standards.md" "coding-standards.md" "coding-standards.md"

if [ "$LANGUAGE" != "other" ]; then
    copy_template "$RALPH_DIR/templates/verify-${LANGUAGE}.sh" "verify.sh" "verify.sh"
    if [ -f "verify.sh" ]; then
        chmod +x verify.sh
    fi
    copy_template "$RALPH_DIR/templates/gitignore-${LANGUAGE}" ".gitignore" ".gitignore"
fi

# docs/ files — use framework docs as starting templates
copy_template "$RALPH_DIR/docs/guardrails.md" "docs/guardrails.md" "docs/guardrails.md"
copy_template "$RALPH_DIR/docs/lessons-learned.md" "docs/lessons-learned.md" "docs/lessons-learned.md"

# ralph-runs/.gitkeep
if [ ! -f "ralph-runs/.gitkeep" ]; then
    touch ralph-runs/.gitkeep
    echo "  $(green 'Created') ralph-runs/.gitkeep"
fi

# Beads init
if [ "$HAVE_BD" = true ]; then
    echo ""
    echo "  Initialising Beads..."
    bd init 2>/dev/null || echo "  $(yellow 'Note'): Beads already initialised"
fi

# --- Step 5: Placeholder Substitution ----------------------------------------

echo ""
echo "$(bold 'Step 5: Placeholder Substitution')"

for file in CLAUDE.md prompt.md; do
    if [ -f "$file" ]; then
        if grep -q '\[PROJECT_NAME\]' "$file" 2>/dev/null; then
            python3 -c "
import sys
with open(sys.argv[1], 'r') as f:
    content = f.read()
content = content.replace('[PROJECT_NAME]', sys.argv[2])
with open(sys.argv[1], 'w') as f:
    f.write(content)
" "$file" "$PROJECT_NAME"
            echo "  Updated $file: [PROJECT_NAME] -> $PROJECT_NAME"
        fi
    fi
done

# --- Step 6: CI/CD Setup -----------------------------------------------------

if [ "$LANGUAGE" != "other" ]; then
    echo ""
    echo "$(bold 'Step 6: CI/CD Setup')"
    echo ""

    mkdir -p .github/workflows
    copy_template "$RALPH_DIR/templates/ci-${LANGUAGE}.yml" ".github/workflows/ci.yml" ".github/workflows/ci.yml"
fi

# --- Step 7: Configure Repo Settings -----------------------------------------

echo ""
echo "$(bold 'Step 7: Repository Settings')"
echo ""

# Get repo full name for API calls
REPO_FULL=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)

if [ -n "$REPO_FULL" ]; then
    # Apply repo defaults
    DEFAULTS="$RALPH_DIR/templates/repo-defaults.json"
    if [ -f "$DEFAULTS" ]; then
        echo "  Applying repository settings (squash merge, auto-delete branches)..."

        # Extract and apply repository settings
        REPO_SETTINGS=$(read_json_key "$DEFAULTS" "repository")
        gh api "repos/$REPO_FULL" -X PATCH --input - <<< "$REPO_SETTINGS" > /dev/null 2>&1 \
            && echo "  $(green 'OK') Repository settings applied" \
            || echo "  $(yellow 'SKIP') Could not apply repo settings (check permissions)"
    fi

    # Branch protection (combined with status checks)
    echo ""
    if confirm "  Set up branch protection on main?" "Y"; then
        PROTECTION=$(read_json_key "$DEFAULTS" "branch_protection")

        # Offer status checks if a CI workflow was configured
        if [ "$LANGUAGE" != "other" ]; then
            echo ""
            if confirm "  Enable required status checks (lint-and-test)?" "Y"; then
                PROTECTION=$(merge_status_checks "$PROTECTION")
            fi
        fi

        gh api "repos/$REPO_FULL/branches/main/protection" -X PUT --input - <<< "$PROTECTION" > /dev/null 2>&1 \
            && echo "  $(green 'OK') Branch protection applied" \
            || echo "  $(yellow 'SKIP') Could not apply branch protection (main branch may not exist yet)"
    fi

    # Gemini Code Assist for VM-General-Services-Ltd repos
    if [ "$OWNER" = "VM-General-Services-Ltd" ]; then
        echo ""
        echo "  Attempting to add repo to Gemini Code Assist..."
        REPO_ID=$(gh api "repos/$REPO_FULL" --jq '.id' 2>/dev/null || true)
        if [ -n "$REPO_ID" ]; then
            gh api "user/installations/${GEMINI_INSTALL_ID}/repositories/$REPO_ID" -X PUT > /dev/null 2>&1 \
                && echo "  $(green 'OK') Added to Gemini Code Assist" \
                || echo "  $(yellow 'SKIP') Gemini Code Assist — may already cover all repos"
        fi
    fi
else
    echo "  $(yellow 'SKIP') Could not determine repo — settings not applied"
fi

# --- Step 8: Initial Commit & Push -------------------------------------------

echo ""
echo "$(bold 'Step 8: Initial Commit')"
echo ""

# Check if there are changes to commit
if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -m "Bootstrap project with Ralph-with-beads workflow

Scaffolded by bootstrap-project.sh from ralph-with-beads framework."
    echo ""
    echo "  $(green 'OK') Initial commit created"

    # Push if remote exists
    if git remote get-url origin &> /dev/null 2>&1; then
        git push -u origin "$(git branch --show-current)" 2>/dev/null \
            && echo "  $(green 'OK') Pushed to remote" \
            || echo "  $(yellow 'SKIP') Push failed — you may need to push manually"
    fi
else
    echo "  No changes to commit."
fi

# --- Summary ------------------------------------------------------------------

echo ""
echo "$(bold '=== Bootstrap Complete ===')"
echo ""
echo "  Project:  $PROJECT_NAME"
echo "  Location: $PROJECT_DIR"
echo "  Language: $LANGUAGE"
if [ -n "$REPO_FULL" ]; then
    echo "  Repo:     https://github.com/$REPO_FULL"
fi
echo ""
echo "$(bold 'Next steps:')"
echo "  1. Review and customise CLAUDE.md for your project"
echo "  2. Run the planning interview to create your PRD"
echo "  3. Generate beads from the PRD: bd create ..."
echo "  4. Start iterating: ./scripts/ralph-hitl.sh ."
echo ""
