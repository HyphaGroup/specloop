---
description: "Import OpenSpec changes into Beads for coordination"
---

# OpenSpec Prioritize

Import OpenSpec changes into Beads for multi-agent coordination.

## Quick Start

Run the import script:

```bash
# Import all incomplete changes
.factory/scripts/openspec-import-beads

# Preview what would be created
.factory/scripts/openspec-import-beads --dry-run

# Import specific changes
.factory/scripts/openspec-import-beads change-one change-two
```

For OpenCode, use `.opencode/scripts/openspec-import-beads` instead.

## What It Does

1. Checks for `bd` (Beads) and `openspec` CLI
2. Initializes Beads if `.beads/` doesn't exist
3. For each incomplete OpenSpec change:
   - Creates an epic in Beads
   - Parses `tasks.md` to extract tasks
   - Creates child issues for each task
4. Saves mapping to `.beads/openspec-mapping.json`
5. Runs `bd sync` to persist changes

## Verify Import

After running, verify with:

```bash
# List all epics (OpenSpec changes)
bd list --type epic

# List all tasks
bd list --type task

# See ready (unblocked, unclaimed) tasks
bd ready

# Check mapping file
cat .beads/openspec-mapping.json
```

## Analyze and Set Dependencies

After import, analyze the changes to identify dependencies:

1. **Read each change's proposal.md and design.md** to understand:
   - What the change does
   - What it depends on (other changes, external systems)
   - What might depend on it

2. **Identify cross-change dependencies:**
   - Does change B require functionality from change A?
   - Are there shared components being modified?
   - Is there a logical build order (foundation → features → polish)?

3. **Set epic-level dependencies** for changes that must be done in order:
   ```bash
   # If "add-auth" must complete before "add-user-profiles":
   bd dep add <user-profiles-epic> <add-auth-epic> --type blocks
   ```

4. **Set task-level dependencies** within a change if tasks.md doesn't already reflect them:
   ```bash
   # Task 3 depends on task 2
   bd dep add <task-3-id> <task-2-id> --type blocks
   ```

5. **Set priority on epics** (1 = highest) if you want a specific order when dependencies are equal:
   ```bash
   bd update <epic-id> --priority 1
   ```

6. **Verify the dependency graph:**
   ```bash
   bd graph
   bd ready  # Should show only unblocked work
   ```

**Ask the user** if you're unsure about dependencies between changes - they may have context about the project roadmap.

## Incremental Import

Running the script again will:
- Skip already-imported changes
- Add any new tasks found in existing changes
- Not duplicate existing tasks

## Troubleshooting

If import fails:

```bash
# Check bd is working
bd list

# Check openspec is working
openspec list --json

# Manual epic creation
bd create "change-name" -t epic

# Manual task creation
bd create "Task title" -t task --parent <epic-id>
```
