# Specloop

An augmentation for Factory Droid and OpenCode that automatically executes OpenSpec changes using Beads for multi-agent coordination.

## Requirements

- `openspec` CLI
- `bd` (Beads) - `npm install -g @beads/bd`
- `jq`

## Quick Start

```bash
# 1. Install to your project
./install.sh /path/to/project --droid    # or --opencode

# 2. Import changes into Beads
/openspec-prioritize

# 3. Start the loop
/openspec-apply-loop

# 4. Monitor progress
/openspec-status

# 5. Cancel if needed
/openspec-cancel-loop
```

## How It Works

1. `/openspec-prioritize` imports OpenSpec changes into Beads as epics with child tasks
2. `/openspec-apply-loop` activates the loop and starts working
3. The stop hook claims tasks via `bd update --status in_progress`
4. On completion, tasks are closed via `bd close`
5. Loop continues until all work is done or cancelled

## Commands

| Command | Description |
|---------|-------------|
| `/openspec-prioritize` | Import changes to Beads (run first) |
| `/openspec-apply-loop` | Start the execution loop |
| `/openspec-status` | Show progress and status |
| `/openspec-cancel-loop` | Stop the loop |

## Multi-Agent Support

With Beads, multiple agents can work in parallel:
- Each agent claims tasks via `bd update <id> --status in_progress`
- `bd ready` only shows unclaimed, unblocked tasks
- Agents work in separate git worktrees

## Safety Features

- **Max iterations** (default: 50) prevents infinite loops
- **Stuck detection** stops after 3 iterations without progress
- **BLOCKED detection** stops if agent outputs "BLOCKED: reason"

## Files

```
hooks/stop-hook.sh          # Droid stop hook
plugins/openspec-loop.ts    # OpenCode plugin
commands/*.md               # Slash commands
scripts/openspec-status     # Status display (Python/Rich)
scripts/openspec-import-beads  # Beads import script
skills/openspec-bootstrap/  # Project bootstrap skill
```

## State

Loop state stored in `.factory/openspec-loop.json` or `.opencode/openspec-loop.json`:

```json
{
  "active": true,
  "iteration": 5,
  "max_iterations": 50,
  "current_task": "project-abc.3",
  "stuck_count": 0
}
```
