# Project Context

## Purpose
A Factory Droid / OpenCode augmentation that creates self-driving implementation loops for OpenSpec-based projects using Beads for work coordination. When activated, it intercepts agent stop attempts and continues working through tasks until all are complete.

Key goals:
- Automate iterative spec implementation without human intervention
- Use Beads (`bd`) for task-level work coordination
- Support multi-agent parallel execution via worktrees
- Detect stuck agents and spec-level blockers automatically
- Provide verification command support for quality gates

## Tech Stack
- **Shell**: Bash (stop-hook.sh)
- **TypeScript**: OpenCode plugin (openspec-loop.ts)
- **JSON Processing**: jq
- **Integration**: Factory Droid hooks / OpenCode plugins
- **CLI Dependencies**: 
  - `openspec` CLI (for `list --json`)
  - `bd` (Beads) for work coordination

## Project Conventions

### Code Style
- Bash scripts use `set -euo pipefail` for safety
- Variables in UPPER_CASE
- Use `jq` for all JSON manipulation (no sed/awk on JSON)
- Atomic file updates via temp file + mv pattern
- Exit codes: 0 = allow stop, non-zero = error

### Architecture Patterns
- **Stop Hook Pattern**: Intercepts agent exit via Factory's Stop hook event
- **Plugin Pattern**: OpenCode uses TypeScript plugins for session.idle event
- **Beads Coordination**: Uses `bd ready`, `bd update`, `bd close` for task management
- **State File Pattern**: `.factory/openspec-loop.json` tracks loop state
- **Mapping File Pattern**: `.beads/openspec-mapping.json` maps changes to epics

### Testing Strategy
- Manual testing via `--dry-run` flag on install.sh
- Test in real projects with openspec + beads setup
- No automated unit tests (shell scripts)

### Git Workflow
- Direct commits to main (single-developer plugin)
- Worktrees for parallel agent execution (`.worktrees/`)

## Domain Context
- **OpenSpec**: Specification-driven development with proposals, tasks, and changes
- **Beads**: Git-backed issue tracker with dependency management
- **Factory Droid**: AI coding assistant with hooks for lifecycle events
- **OpenCode**: Alternative AI coding assistant with plugin system

### OpenSpec Structure
```
openspec/
├── project.md           # Project context
├── AGENTS.md            # Agent conventions
└── changes/
    └── <change-id>/
        ├── proposal.md  # What to build
        ├── design.md    # How to build (optional)
        └── tasks.md     # Checklist with [ ]/[-]/[x]/[~] markers
```

### Beads Structure
```
.beads/
├── beads.db                  # SQLite database
└── openspec-mapping.json     # OpenSpec → Beads mapping
```

### Task Status Markers
- `- [ ]` - Pending task
- `- [-]` - In-progress task
- `- [x]` - Completed task
- `- [~]` - Deferred/blocked task

## Important Constraints
- **Beads Required**: No fallback to JSON queues - `bd` must be installed
- **jq Dependency**: Hook script requires jq for JSON processing
- **openspec CLI**: Must be in PATH for `openspec list --json`

## External Dependencies
- **Factory Droid / OpenCode**: Provides hooks/plugins system
- **openspec CLI**: Provides `list --json` and `show --json` commands
- **bd (Beads)**: Provides `ready`, `update`, `close`, `list` commands
- **jq**: JSON processing in shell scripts
- **Bash**: Shell interpreter (macOS/Linux compatible)

## State File Schema

### .factory/openspec-loop.json
```json
{
  "active": true,
  "iteration": 5,
  "max_iterations": 50,
  "current_task": "oubliette-m4k2.3",
  "stuck_count": 0,
  "verify_commands": ["npm test", "npm run lint"],
  "blocked_reason": null,
  "stuck_reason": null
}
```

### .beads/openspec-mapping.json
```json
{
  "version": "1",
  "changes": {
    "add-oauth-support": {
      "epic_id": "oubliette-m4k2",
      "imported_at": "2024-01-21T10:30:00Z",
      "tasks": {
        "1": "oubliette-m4k2.1",
        "1.1": "oubliette-m4k2.1.1",
        "2": "oubliette-m4k2.2"
      }
    }
  }
}
```
