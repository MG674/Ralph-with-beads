# Beads Generation Prompt

Use this prompt to convert a PRD into Beads tasks.

---

Read the PRD file (prd.md) and create Beads tasks for implementation.

## Rules for Creating Beads

1. **One acceptance criterion = one bead** (usually)
   - Each bead should be completable in a single Ralph iteration
   - If a criterion is too large, split it

2. **Clear, actionable titles**
   - Start with a verb: "Implement...", "Add...", "Create...", "Fix..."
   - Be specific: "Add CSV parser for ankle measurements" not "Handle CSV"

3. **Set appropriate priorities**
   - Priority 1: Tracer bullet / critical path items
   - Priority 2: Core features
   - Priority 3: Important but not blocking
   - Priority 4: Nice to have
   - Priority 5: Polish / future enhancements

4. **Link dependencies**
   - Use `bd dep block <blocker-id> <blocked-id>` for hard dependencies
   - Use `bd dep relate <id1> <id2>` for related items

5. **Include testability in description**
   - How will we verify this works?
   - What test should be written?

## Commands to Use

```bash
# Create a feature bead
bd create "Implement CSV file reader" feature 2

# Create a bug fix bead  
bd create "Fix timestamp parsing for UTC" bug 1

# Create a task/chore bead
bd create "Set up pytest configuration" task 1

# Link dependencies (A blocks B)
bd dep block <id-of-A> <id-of-B>

# Link related items
bd dep relate <id1> <id2>

# View what you've created
bd list
```

## Output Format

After creating all beads, provide:
1. Summary of beads created (count by type and priority)
2. Dependency graph (what blocks what)
3. Suggested implementation order (based on priorities and dependencies)

---

Now read prd.md and create the beads.
