# Project Close-out Checklist

Use this checklist when a project reaches completion or a major milestone.

## 1. Knowledge Harvest

- [ ] Run `closeout-review.sh` against the project
- [ ] Review diffs of guardrails.md (project vs framework)
- [ ] Review diffs of lessons-learned.md (project vs framework)

## 2. Review Agent-Recorded Learnings

Ralph agents update `docs/lessons-learned.md` and `docs/guardrails.md` each
iteration (prompt.md Steps 6e/6f). Review ALL entries, not just recent ones.

- [ ] Read through every entry in docs/lessons-learned.md
- [ ] Read through every entry in docs/guardrails.md
- [ ] Flag entries that are universal (not project-specific)
- [ ] Flag entries that contradict existing framework guidance

## 3. Feed Back to Ralph-with-beads

For universal learnings that apply across projects:

- [ ] Create branch in ralph-with-beads repo
- [ ] Update framework docs/guardrails.md with universal rules
- [ ] Update framework docs/lessons-learned.md with universal patterns
- [ ] PR and merge to ralph-with-beads main

## 4. Template Improvements

- [ ] Did any project customisations reveal gaps in templates?
- [ ] Should CLAUDE.md template be updated?
- [ ] Should coding-standards.md template be updated?
- [ ] Should verify.sh template be updated?
- [ ] Should prompt.md template be updated?

## 5. Process Improvements

- [ ] Were iteration counts reasonable? (If consistently high, tasks may be too large)
- [ ] Were bead sizes appropriate? (Target: completable in one iteration)
- [ ] Any workflow pain points to address?
- [ ] Any new guardrails needed at the framework level?

## 6. Project Archive

- [ ] All beads closed (`bd list` shows no open tasks)
- [ ] README.md updated with final state
- [ ] All branches merged or deleted
- [ ] Repository archived if no further development planned
