# Multi-Agent Coordination

Enables multiple agents to work on OpenSpec changes in parallel using Beads for coordination.

## ADDED Requirements

### Requirement: Beads-based work queue

The system MUST use Beads (`bd`) as the work coordination layer when Beads is initialized in the project.

#### Scenario: Import changes to Beads via prioritize

- **GIVEN** a project with `openspec/changes/` containing pending changes
- **AND** Beads is initialized (`.beads/` directory exists)
- **WHEN** user runs `/openspec-prioritize`
- **THEN** each change becomes a Beads epic with hierarchical ID
- **AND** each task in `tasks.md` becomes a child issue under the epic
- **AND** task dependencies are converted to `blocks` relationships
- **AND** mapping is stored in `.beads/openspec-mapping.json`

#### Scenario: Work selection via bd ready

- **GIVEN** changes have been imported to Beads
- **WHEN** `/openspec-apply-loop` selects next work
- **THEN** it uses `bd ready --json` to find unblocked, unclaimed tasks
- **AND** it claims work via `bd update <id> --status in_progress`
- **AND** it syncs claims via `bd sync`

#### Scenario: Task completion updates both systems

- **GIVEN** an agent completes a task
- **WHEN** the task is marked complete
- **THEN** `bd close <id>` is called with completion reason
- **AND** corresponding line in `tasks.md` is updated to `[x]`
- **AND** when all tasks for a change complete, the epic auto-closes

### Requirement: Beads initialization

The system MUST ensure Beads is initialized before coordination commands run.

#### Scenario: Auto-initialize Beads

- **GIVEN** `bd` command is available in PATH
- **AND** `.beads/` directory does not exist
- **WHEN** `/openspec-prioritize` or `/openspec-apply-loop` runs
- **THEN** it runs `bd init` to initialize Beads
- **AND** proceeds with normal operation

#### Scenario: Fail without bd command

- **GIVEN** `bd` command is not available in PATH
- **WHEN** `/openspec-prioritize` or `/openspec-apply-loop` runs
- **THEN** it fails with an error message
- **AND** includes installation instructions: `npm install -g @beads/bd`

### Requirement: Progress monitoring

The system MUST provide real-time progress visibility across agents.

#### Scenario: Status check via command

- **GIVEN** work is in progress via Beads coordination
- **WHEN** user runs `/openspec-status`
- **THEN** it shows ready tasks, in-progress tasks (with assignee), and blocked tasks
- **AND** it shows completion percentage per epic

#### Scenario: Status output modes

- **GIVEN** `/openspec-status` is invoked
- **WHEN** `--json` flag is provided
- **THEN** output is machine-readable JSON
- **WHEN** no flag is provided
- **THEN** output is human-readable formatted text

### Requirement: Optional parallel execution

The system SHALL support spawning subagents for parallel work when multiple tasks are ready.

#### Scenario: Subagent spawning encouraged

- **GIVEN** `bd ready` returns multiple unblocked tasks
- **WHEN** `/openspec-apply-loop` prompt is generated
- **THEN** prompt encourages agent to consider spawning subagents
- **AND** prompt includes worktree creation pattern

#### Scenario: Worktree isolation

- **GIVEN** agent decides to spawn subagents
- **WHEN** subagent is created for a task
- **THEN** subagent works in `.worktrees/<task-id>/` directory
- **AND** work is merged back to main branch on completion
- **AND** worktree is cleaned up after merge

### Requirement: OpenSpec-Beads mapping

The system MUST maintain bidirectional mapping between OpenSpec and Beads identifiers.

#### Scenario: Mapping file structure

- **GIVEN** changes are imported to Beads
- **THEN** `.beads/openspec-mapping.json` contains:
  - Change ID to epic ID mapping
  - Task number to issue ID mapping
  - Import timestamp
  - Status (active/complete/archived)

#### Scenario: Incremental import

- **GIVEN** a change already imported to Beads
- **WHEN** new tasks are added to `tasks.md`
- **AND** `/openspec-prioritize` runs again
- **THEN** only new tasks are created in Beads
- **AND** mapping is updated with new task IDs
