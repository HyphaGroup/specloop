# Design: Beads Coordination Integration

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Commands                            │
├─────────────────────────────────────────────────────────────────┤
│  /openspec-proposal  →  /openspec-prioritize  →  /openspec-apply-loop
│       (creates)            (imports to bd)         (executes)   │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Beads Coordination Layer                     │
├─────────────────────────────────────────────────────────────────┤
│  .beads/                                                        │
│  ├── issues.jsonl          # Beads database (git-tracked)       │
│  ├── beads.db              # SQLite cache (gitignored)          │
│  └── openspec-mapping.json # OpenSpec ↔ Beads ID mapping        │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Multi-Agent Execution                        │
├─────────────────────────────────────────────────────────────────┤
│  Main Agent                                                     │
│  ├── bd ready → claims task → works → bd close                  │
│  └── Optionally spawns subagents:                               │
│      ├── .worktrees/bd-xxx.2/  (Agent 2)                        │
│      ├── .worktrees/bd-xxx.3/  (Agent 3)                        │
│      └── Merges back on completion                              │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Import Phase (`/openspec-prioritize`)

```bash
# Input: openspec/changes/<name>/tasks.md
- [ ] 1. Set up module structure
- [ ] 2. Implement feature A
  - [ ] 2.1 Subtask A1
  - [ ] 2.2 Subtask A2
- [ ] 3. Add tests (depends on 2)

# Output: Beads issues
bd create "add-feature" -t epic -p 1                    # → bd-m4k2
bd create "Set up module structure" --parent bd-m4k2   # → bd-m4k2.1
bd create "Implement feature A" --parent bd-m4k2       # → bd-m4k2.2
bd create "Subtask A1" --parent bd-m4k2.2              # → bd-m4k2.2.1
bd create "Subtask A2" --parent bd-m4k2.2              # → bd-m4k2.2.2
bd create "Add tests" --parent bd-m4k2                 # → bd-m4k2.3

# Dependencies
bd dep add bd-m4k2.3 bd-m4k2.2 --type blocks  # tests blocked by feature
```

### 2. Execution Phase (`/openspec-apply-loop`)

```bash
# Agent starts
bd ready --json
# Returns: [{"id": "bd-m4k2.1", "title": "Set up module structure", ...}]

# Agent claims
bd update bd-m4k2.1 --status in_progress --assignee agent-main
bd sync

# Agent works (implements the task)
# ...

# Agent completes
bd close bd-m4k2.1 --reason "Created src/feature/ module"
bd sync

# Check if more tasks available
bd ready --json
# Returns next unblocked tasks
```

### 3. Subagent Spawning (Optional)

When `bd ready` returns multiple tasks, agent may choose to parallelize:

```bash
# Main agent sees multiple ready tasks
bd ready --json
# Returns: [bd-m4k2.2.1, bd-m4k2.2.2, bd-m4k2.4]  # 3 parallel tasks

# Create worktrees
git worktree add .worktrees/bd-m4k2.2.1 -b bd-m4k2.2.1
git worktree add .worktrees/bd-m4k2.2.2 -b bd-m4k2.2.2

# Spawn subagents (platform-specific)
# Each subagent:
#   1. cd .worktrees/<task-id>
#   2. bd update <task-id> --status in_progress --assignee agent-N
#   3. Works on task
#   4. bd close <task-id>
#   5. git commit && git push

# Main agent monitors and merges
git merge bd-m4k2.2.1 bd-m4k2.2.2
git worktree remove .worktrees/bd-m4k2.2.1
git worktree remove .worktrees/bd-m4k2.2.2
```

## Mapping File Schema

`.beads/openspec-mapping.json`:

```json
{
  "version": "1",
  "changes": {
    "<change-id>": {
      "epic_id": "<bd-id>",
      "imported_at": "<ISO8601>",
      "status": "active|complete|archived",
      "tasks": {
        "<task-number>": "<bd-id>",
        "<task-number>.<subtask>": "<bd-id>"
      }
    }
  }
}
```

## State Synchronization

### OpenSpec → Beads (Import)

Triggered by `/openspec-prioritize` or at start of `/openspec-apply-loop`:

1. Run `openspec list --json` to get all changes
2. For each change not in mapping:
   - Parse `tasks.md` to extract task tree
   - Create epic + child issues in Beads
   - Store mapping in `openspec-mapping.json`
3. For changes already in mapping:
   - Check for new tasks in `tasks.md`
   - Add missing tasks as new Beads issues

### Beads → OpenSpec (Sync Back)

When Beads task is closed:

1. Look up task number from mapping
2. Update corresponding line in `tasks.md`:
   - `- [ ]` → `- [x]` for completed
   - `- [-]` for in-progress
3. When all tasks complete, epic auto-closes

## Worktree Strategy

```
project/
├── .beads/                    # Shared beads database
├── .worktrees/                # Temporary worktrees (gitignored)
│   ├── bd-m4k2.2/            # Subagent workspace
│   └── bd-m4k2.3/            # Subagent workspace
├── openspec/
└── src/
```

Key decisions:
- `.worktrees/` in repo root, gitignored
- Each worktree on its own branch named after task ID
- Beads database shared via BEADS_DIR or auto-discovery
- Merge back to main branch on task completion

## Error Handling

### Conflicts During Merge

If worktree merge conflicts:
1. Mark task as blocked in Beads
2. Alert main agent
3. Main agent resolves manually or re-runs task

### Stuck Detection

Reuse existing stuck detection from stop-hook.sh:
- Track `prev_tasks_hash` per task
- If no progress after N iterations, mark stuck
- Report via Beads notes field

### Orphaned Worktrees

Cleanup on `/openspec-apply-loop` start:
```bash
git worktree prune
rm -rf .worktrees/*
```

## Platform Considerations

### Factory Droid
- Stop hook continues to work for single-agent
- Subagent spawning via Task tool
- Status via `/openspec-status` command

### OpenCode
- Plugin handles session.idle event
- Subagent spawning via agent system
- Status via same script with `--json` flag

## Migration Path

1. Existing `/openspec-loop` continues to work
2. New `/openspec-apply-loop` is additive
3. `/openspec-prioritize` gains Beads import (backward compatible)
4. Users opt-in to Beads by running `bd init`
