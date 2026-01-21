# Tasks

## 1. Core Infrastructure

- [x] 1.1 Add `bd` to dependency checks in `install.sh`:
  - [x] 1.1.1 Check if `bd` command exists in PATH
  - [x] 1.1.2 Warn if missing (do NOT fail install, but Beads commands won't work)
  - [x] 1.1.3 Include install instructions in warning: `npm install -g @beads/bd`
- [x] 1.2 Create `scripts/openspec-status` standalone script with `--json` flag
- [x] 1.3 Create `/openspec-status` command that invokes the script

## 2. Beads Import (`/openspec-prioritize`)

- [x] 2.1 Update `commands/openspec-prioritize.md` to require Beads:
  - [x] 2.1.1 Check if `bd` exists, fail with instructions if not
  - [x] 2.1.2 Check if `.beads/` exists, run `bd init` if not
- [x] 2.2 Implement task tree parsing from `tasks.md` (handle nested tasks like `1.1`, `1.2.3`)
- [x] 2.3 Create epic + child issues in Beads with proper parent-child relationships
- [x] 2.4 Parse task dependencies from notes (e.g., "depends on 2") and create `blocks` relationships
- [x] 2.5 Create/update `.beads/openspec-mapping.json` with change→epic and task→issue mappings
- [x] 2.6 Handle incremental import (detect new tasks added to existing changes)

## 3. Apply Loop (`/openspec-apply-loop`)

- [x] 3.1 Create `commands/openspec-apply-loop.md` command definition
- [x] 3.2 Add runtime checks:
  - [x] 3.2.1 Check if `bd` exists, fail with instructions if not
  - [x] 3.2.2 Check if `.beads/` exists, run `bd init` if not
- [x] 3.3 Implement `bd ready` based work selection
- [x] 3.4 Implement task claiming via `bd update --status in_progress`
- [x] 3.5 Implement `tasks.md` sync-back when Beads task status changes
- [x] 3.6 Implement task completion via `bd close` with reason
- [x] 3.7 Add prompt text encouraging subagent spawning when multiple tasks ready
- [x] 3.8 Implement epic completion detection (all children done → archive change)

## 4. Worktree Support (Optional Parallelism)

- [x] 4.1 Add `.worktrees/` to `.gitignore`
- [x] 4.2 Document worktree creation pattern in command prompt
- [x] 4.3 Document worktree cleanup and merge-back pattern
- [x] 4.4 Add worktree pruning on loop start

## 5. Stop Hook / Plugin Updates

- [x] 5.1 Update `hooks/stop-hook.sh` to use Beads for work detection (Droid)
- [x] 5.2 Update `plugins/openspec-loop.ts` with Beads coordination (OpenCode)
- [x] 5.3 Check if `bd` exists, skip/fallback if not (allow normal stop)
- [x] 5.4 Add Beads-aware stuck detection using `bd show` notes field

## 6. Documentation

- [ ] 6.1 Update README.md with Beads integration section
- [ ] 6.2 Add workflow examples for multi-agent coordination
- [ ] 6.3 Document the mapping file schema

## 7. Testing

- [ ] 7.1 Manual test: single-agent flow with Beads
- [ ] 7.2 Manual test: auto `bd init` when `.beads/` missing
- [ ] 7.3 Manual test: fail gracefully when `bd` not installed
- [ ] 7.4 Manual test: `/openspec-status` output (human and JSON modes)

## Dependencies

- Tasks 2.x must complete before 3.x (import before execution)
- Task 5.x can be done in parallel with 3.x
- Task 4.x is independent and optional
- Task 6.x and 7.x should happen after implementation
