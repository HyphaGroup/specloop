---
description: "Execute OpenSpec changes using Beads coordination"
argument-hint: "[--max-iterations N] [--verify COMMAND...]"
---

# OpenSpec Apply Loop (Beads Coordinated)

Execute OpenSpec changes using Beads for work coordination. Supports multi-agent parallel execution.

**Prerequisites Check:**

```bash
# Check if bd exists
if ! command -v bd >/dev/null 2>&1; then
  echo "Error: bd (Beads) not found. Install with: npm install -g @beads/bd"
  exit 1
fi

# Initialize Beads if needed
if [[ ! -d ".beads" ]]; then
  echo "Initializing Beads..."
  bd init
fi
```

**Step 1: Initialize State**

Create `.factory/openspec-loop.json`:

```json
{
  "active": true,
  "iteration": 0,
  "max_iterations": 50,
  "verify_commands": [],
  "coordination": "beads"
}
```

Parse arguments:
- `--max-iterations=N` or `--max-iterations N` (default: 50)
- `--verify COMMAND...` - Commands to run after each change

**Step 2: Check for Work**

Use Beads to find available work:

```bash
# Get ready tasks (unblocked, unclaimed)
bd ready --json
```

If no tasks ready, check if there are incomplete changes not yet imported:
```bash
openspec list --json
```

If incomplete changes exist but not in Beads, run `/openspec-prioritize` to import them.

**Step 3: Claim Work**

When you find a ready task:

```bash
# Claim the epic AND task (prevents other agents from working on this change)
bd update <epic-id> --status in_progress   # Mark epic in progress first
bd update <task-id> --status in_progress

# Sync claim to git so other agents see it
bd sync
```

**Note:** Only one agent works on an epic at a time. Other agents will skip to different epics that aren't in progress.

**Step 4: Execute Task**

1. Read the task details: `bd show <task-id> --json`
2. Find the parent epic to get the change ID
3. Read the corresponding `openspec/changes/<change-id>/` files
4. Implement the task
5. Update `tasks.md` to mark task as in-progress: `- [-]`

**Step 5: Complete Task**

When task is done:

```bash
# Mark complete in tasks.md: - [x]
# Then close in Beads
bd close <task-id> --reason "Implemented: <brief summary>"
bd sync
```

**Step 6: Check for More Work**

```bash
bd ready --json
```

- If more tasks ready → go to Step 3
- If no tasks but epic has children in progress → wait or help
- If all tasks complete → epic auto-closes, run `/openspec-archive`

**Parallel Execution (Optional):**

If `bd ready` returns multiple tasks, consider spawning subagents:

```bash
# Check ready count
READY_COUNT=$(bd ready --json | jq 'length')

if [[ $READY_COUNT -gt 1 ]]; then
  echo "Multiple tasks ready ($READY_COUNT). Consider spawning subagents for parallel work."
  echo ""
  echo "To parallelize with worktrees:"
  echo "  git worktree add .worktrees/<task-id> -b <task-id>"
  echo "  # Spawn subagent in that directory"
  echo "  # Each subagent claims and works on one task"
  echo "  # Merge back when done"
fi
```

Each subagent should:
1. Work in its own worktree: `.worktrees/<task-id>/`
2. Claim one task via `bd update`
3. Complete work and `bd close`
4. Commit and push
5. Main agent merges worktrees back

**Sync-Back to tasks.md:**

Keep `tasks.md` in sync with Beads status:
- When claiming: `- [ ]` → `- [-]`
- When completing: `- [-]` → `- [x]`
- When deferring: `- [-]` → `- [~]` (add note explaining why)

**Epic Completion:**

When all child tasks are closed:
1. The epic shows as complete in `bd list --type epic`
2. Run `openspec archive <change-id>` to archive the change
3. Commit: `git add -A && git commit -m "Complete <change-id>"`
4. Continue to next epic or exit if none remain

**Verification (if configured):**

After completing all tasks for an epic, run verification:

```bash
# Run verify commands
npm test && npm run lint

# If fails, fix issues before archiving
```

**Stop Behavior:**

When you try to stop, the stop hook checks Beads:
- If `bd ready` has tasks from a non-in-progress epic → continues you on next task
- If all ready tasks belong to epics already in progress (another agent working) → allows stop
- If all work done → allows stop

**Multi-agent coordination:** The hook filters out tasks from in-progress epics, allowing multiple agents to work in parallel on different epics without interfering.

To cancel: delete `.factory/openspec-loop.json` or run `/openspec-cancel-loop`.
