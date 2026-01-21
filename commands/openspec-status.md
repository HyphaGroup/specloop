---
description: "Show OpenSpec + Beads coordination status"
argument-hint: "[--json]"
---

# OpenSpec Status

Show the current status of OpenSpec changes and Beads coordination.

**Prerequisites:**
- `bd` (Beads) must be installed: `npm install -g @beads/bd`
- Beads must be initialized in the project: `bd init`

**Usage:**

Run the status script to see current state:

```bash
# Human-readable output
.factory/scripts/openspec-status

# JSON output (for programmatic use)
.factory/scripts/openspec-status --json
```

For OpenCode, use `.opencode/scripts/openspec-status` instead.

**Output includes:**
- **Epics**: OpenSpec changes imported as Beads epics
- **In Progress**: Tasks currently being worked on (with assignee)
- **Ready**: Tasks with no blockers that can be started
- **Blocked**: Tasks waiting on dependencies

**Example output:**
```
═══════════════════════════════════════════════════════════
  OpenSpec + Beads Status
═══════════════════════════════════════════════════════════

Summary: 3 ready | 1 in progress | 2 blocked | 2 epics

Changes (Epics):
───────────────────────────────────────────────────────────
  bd-m4k2: add-oauth-support [in_progress]
  bd-g7x1: add-sync-engine [open]

In Progress:
───────────────────────────────────────────────────────────
  ◐ bd-m4k2.2: Implement token refresh [agent-1]

Ready (can start):
───────────────────────────────────────────────────────────
  ○ bd-m4k2.3: Add OAuth middleware
  ○ bd-m4k2.4: Write OAuth tests
  ○ bd-g7x1.1: Set up sync module

Blocked:
───────────────────────────────────────────────────────────
  ● bd-m4k2.5: Integration tests (by: bd-m4k2.3, bd-m4k2.4)
  ● bd-g7x1.2: Implement sync logic (by: bd-g7x1.1)

═══════════════════════════════════════════════════════════
```
