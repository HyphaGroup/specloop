# Proposal: Integrate Beads for Multi-Agent Coordination

## Summary

Add Beads (`bd`) integration to enable multiple agents to work on OpenSpec changes in parallel without stepping on each other's work. Beads provides git-backed issue tracking with dependency management, hash-based IDs that prevent merge conflicts, and a `bd ready` command that shows unblocked work.

## Problem

Currently, the openspec-loop is single-agent:
1. One agent works through changes sequentially
2. No coordination mechanism for parallel work
3. Priority queue (`openspec-queue.json`) is static and doesn't track work-in-progress
4. No way to see what's being worked on vs. what's available

## Solution

Use Beads as the coordination layer:

1. **`/openspec-prioritize`** imports OpenSpec changes into Beads:
   - Each change becomes an epic (`bd-xxx`)
   - Each task in `tasks.md` becomes a child issue (`bd-xxx.1`, `bd-xxx.2`)
   - Task dependencies become `blocks` relationships

2. **`/openspec-apply-loop`** uses Beads for work assignment:
   - `bd ready` returns unblocked, unclaimed tasks
   - Agent claims work via `bd update <id> --status in_progress --assignee <agent-id>`
   - `bd sync` pushes claims to git so other agents see them
   - On task completion: `bd close <id>` and epic auto-completes when all children done

3. **Optional subagent spawning**:
   - When multiple tasks are ready, agent may spawn subagents
   - Each subagent works in a separate git worktree
   - Work merges back on completion

4. **`/openspec-status`** shows real-time progress via Beads state

## Mapping Strategy

Store mapping between OpenSpec and Beads in `.beads/openspec-mapping.json`:

```json
{
  "changes": {
    "add-feature": {
      "epic_id": "bd-m4k2",
      "imported_at": "2024-01-21T10:30:00Z",
      "tasks": {
        "1": "bd-m4k2.1",
        "1.1": "bd-m4k2.1.1",
        "2": "bd-m4k2.2"
      }
    }
  }
}
```

This keeps OpenSpec pristine (no modification to validated files) and stores mapping in Beads territory.

## Dependencies

- **Beads CLI** (`bd`) must be installed and in PATH
- Beads v0.40+ recommended for agent tracking features
- Git worktrees for parallel agent isolation (optional)

## Scope

- Modify `/openspec-prioritize` to import to Beads instead of JSON queue
- Create `/openspec-apply-loop` as replacement for `/openspec-loop` with Beads integration
- Create `/openspec-status` script for progress monitoring
- Update `install.sh` to check for `bd` dependency
- Add `.beads/` initialization guidance

## Out of Scope

- Automatic Beads installation
- Beads MCP server integration (future enhancement)
- Cross-repo coordination (single repo for now)
