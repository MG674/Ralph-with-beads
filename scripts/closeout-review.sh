#!/bin/bash
set -e

# =============================================================================
# closeout-review.sh — Project close-out diff review
#
# Compares a project's docs against the Ralph-with-beads framework templates
# to identify learnings that could be promoted to the framework.
#
# Usage: ./scripts/closeout-review.sh /path/to/project
# =============================================================================

RALPH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Directory not found: $PROJECT_DIR"
    exit 1
fi

bold()  { printf '\033[1m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }
yellow(){ printf '\033[33m%s\033[0m' "$1"; }

echo ""
echo "$(bold '=== Ralph-with-beads Close-out Review ===')"
echo "  Project:   $PROJECT_DIR"
echo "  Framework: $RALPH_DIR"
echo ""

# --- Agent-Recorded Learnings ------------------------------------------------

echo "$(bold '1. Agent-Recorded Learnings')"
echo ""
echo "  Ralph agents update these files each iteration (prompt.md Steps 6e/6f)."
echo "  Review ALL entries — not just recent ones."
echo ""

FOUND_LEARNINGS=false

if [ -f "$PROJECT_DIR/docs/guardrails.md" ]; then
    echo "  $(bold 'docs/guardrails.md') — Project-specific rules from failures:"
    if [ -f "$RALPH_DIR/docs/guardrails.md" ]; then
        DIFF_OUT=$(diff -u "$RALPH_DIR/docs/guardrails.md" "$PROJECT_DIR/docs/guardrails.md" 2>/dev/null || true)
        if [ -n "$DIFF_OUT" ]; then
            echo "$DIFF_OUT"
            FOUND_LEARNINGS=true
        else
            echo "  $(green 'No differences') — project matches framework"
        fi
    else
        echo "  $(yellow 'No framework baseline') — showing project file:"
        cat "$PROJECT_DIR/docs/guardrails.md"
        FOUND_LEARNINGS=true
    fi
    echo ""
fi

if [ -f "$PROJECT_DIR/docs/lessons-learned.md" ]; then
    echo "  $(bold 'docs/lessons-learned.md') — Accumulated wisdom:"
    if [ -f "$RALPH_DIR/docs/lessons-learned.md" ]; then
        DIFF_OUT=$(diff -u "$RALPH_DIR/docs/lessons-learned.md" "$PROJECT_DIR/docs/lessons-learned.md" 2>/dev/null || true)
        if [ -n "$DIFF_OUT" ]; then
            echo "$DIFF_OUT"
            FOUND_LEARNINGS=true
        else
            echo "  $(green 'No differences') — project matches framework"
        fi
    else
        echo "  $(yellow 'No framework baseline') — showing project file:"
        cat "$PROJECT_DIR/docs/lessons-learned.md"
        FOUND_LEARNINGS=true
    fi
    echo ""
fi

if [ "$FOUND_LEARNINGS" = false ]; then
    echo "  No learnings files found or no differences detected."
    echo ""
fi

# --- Template Drift ----------------------------------------------------------

echo "$(bold '2. Template Drift')"
echo "  Checking if project files have diverged from framework templates."
echo ""

check_drift() {
    local template="$1" project_file="$2" label="$3"
    if [ ! -f "$project_file" ]; then
        return
    fi
    if [ ! -f "$template" ]; then
        return
    fi
    if ! diff -q "$template" "$project_file" > /dev/null 2>&1; then
        echo "  $(yellow 'DRIFT') $label"
        echo "         Template: $template"
        echo "         Project:  $project_file"
    else
        echo "  $(green 'OK')    $label"
    fi
}

check_drift "$RALPH_DIR/templates/coding-standards.md" "$PROJECT_DIR/coding-standards.md" "coding-standards.md"
check_drift "$RALPH_DIR/templates/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md" "CLAUDE.md"
check_drift "$RALPH_DIR/templates/prompt.md" "$PROJECT_DIR/prompt.md" "prompt.md"

echo ""

# --- Close-out Checklist Reminder --------------------------------------------

echo "$(bold '3. Close-out Checklist')"
echo ""
if [ -f "$RALPH_DIR/templates/closeout-checklist.md" ]; then
    cat "$RALPH_DIR/templates/closeout-checklist.md"
else
    echo "  Checklist not found at $RALPH_DIR/templates/closeout-checklist.md"
fi

echo ""
echo "$(bold 'Done.') Review the diffs above and decide what to promote to the framework."
echo ""
