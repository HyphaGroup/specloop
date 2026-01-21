#!/bin/bash

# OpenSpec Loop Stop Hook (Beads Only)
# Requires bd (Beads) for work coordination - no legacy fallback

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# State file location
STATE_FILE=".factory/openspec-loop.json"
PROGRESS_FILE=".factory/openspec-loop-progress.md"

# Check if loop is active
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

ACTIVE=$(jq -r '.active // false' "$STATE_FILE")
if [[ "$ACTIVE" != "true" ]]; then
  exit 0
fi

# Require bd
if ! command -v bd >/dev/null 2>&1; then
  echo "❌ OpenSpec loop requires bd (Beads). Install: npm install -g @beads/bd" >&2
  jq '.active = false | .stuck_reason = "bd not installed"' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  exit 0
fi

# Output summary of all work done in this loop
output_loop_summary() {
  echo "" >&2
  echo "═══════════════════════════════════════════════════════════" >&2
  echo "  OpenSpec Loop Complete - Summary" >&2
  echo "═══════════════════════════════════════════════════════════" >&2
  
  local iterations=$(jq -r '.iteration // 0' "$STATE_FILE")
  echo "Total iterations: $iterations" >&2
  
  echo "" >&2
  echo "Beads Summary:" >&2
  bd stats 2>/dev/null | head -10 >&2 || echo "  (unable to get stats)" >&2
  
  if [[ -f "$PROGRESS_FILE" ]]; then
    echo "" >&2
    echo "Work completed:" >&2
    echo "───────────────────────────────────────────────────────────" >&2
    cat "$PROGRESS_FILE" >&2
    echo "───────────────────────────────────────────────────────────" >&2
  fi
  
  echo "" >&2
  echo "Recent commits:" >&2
  git log --oneline -10 2>/dev/null | head -5 >&2 || echo "  (unable to read git log)" >&2
  
  echo "" >&2
  echo "Progress file: $PROGRESS_FILE" >&2
  echo "═══════════════════════════════════════════════════════════" >&2
}

ITERATION=$(jq -r '.iteration // 0' "$STATE_FILE")
MAX_ITERATIONS=$(jq -r '.max_iterations // 0' "$STATE_FILE")
VERIFY_COMMANDS=$(jq -r '.verify_commands // [] | join(" && ")' "$STATE_FILE")

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "OpenSpec loop: Max iterations ($MAX_ITERATIONS) reached." >&2
  jq '.active = false' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  exit 0
fi

# Check for BLOCKED status in last assistant message
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
if [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_MESSAGE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 || echo "")
  if [[ -n "$LAST_MESSAGE" ]]; then
    LAST_TEXT=$(echo "$LAST_MESSAGE" | jq -r '.message.content[] | select(.type == "text") | .text' 2>/dev/null || echo "")
    if echo "$LAST_TEXT" | grep -qi "^BLOCKED:"; then
      BLOCKED_REASON=$(echo "$LAST_TEXT" | grep -i "^BLOCKED:" | head -1 | sed 's/^BLOCKED://i' | xargs)
      echo "🚫 OpenSpec loop: Agent is BLOCKED: $BLOCKED_REASON" >&2
      jq --arg reason "$BLOCKED_REASON" '.active = false | .blocked_reason = $reason' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      exit 0
    fi
  fi
fi

# Check for stuck (consecutive stop hook activations)
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  STUCK_COUNT=$(jq -r '.stuck_count // 0' "$STATE_FILE")
  STUCK_COUNT=$((STUCK_COUNT + 1))
  
  if [[ $STUCK_COUNT -ge 3 ]]; then
    echo "⚠️  OpenSpec loop: Agent appears stuck (3 consecutive stop hook activations). Stopping." >&2
    jq '.active = false | .stuck_reason = "3 consecutive stop hook activations"' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    exit 0
  fi
  
  jq --argjson count "$STUCK_COUNT" '.stuck_count = $count' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
else
  jq '.stuck_count = 0' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

# Get Beads status
READY_TASKS=$(bd ready --json 2>/dev/null || echo '[]')
READY_COUNT=$(echo "$READY_TASKS" | jq 'length')

IN_PROGRESS=$(bd list --status in_progress --json 2>/dev/null || echo '[]')
IN_PROGRESS_COUNT=$(echo "$IN_PROGRESS" | jq 'length')

EPICS=$(bd list --type epic --json 2>/dev/null || echo '[]')
INCOMPLETE_EPICS=$(echo "$EPICS" | jq '[.[] | select(.status != "closed")] | length')

# Check completion
if [[ "$READY_COUNT" == "0" ]] && [[ "$IN_PROGRESS_COUNT" == "0" ]]; then
  if [[ "$INCOMPLETE_EPICS" == "0" ]]; then
    echo "OpenSpec loop: All Beads epics complete!" >&2
    output_loop_summary
    jq '.active = false' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    exit 0
  else
    BLOCKED=$(bd blocked --json 2>/dev/null || echo '[]')
    BLOCKED_COUNT=$(echo "$BLOCKED" | jq 'length')
    if [[ "$BLOCKED_COUNT" -gt 0 ]]; then
      echo "⚠️  OpenSpec loop: $BLOCKED_COUNT tasks blocked, no ready tasks. Stopping." >&2
      jq '.active = false | .stuck_reason = "All tasks blocked"' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      exit 0
    fi
  fi
fi

# Get next task
NEXT_TASK=$(echo "$READY_TASKS" | jq -r '.[0] // empty')
if [[ -z "$NEXT_TASK" ]]; then
  if [[ "$IN_PROGRESS_COUNT" -gt 0 ]]; then
    echo "OpenSpec loop: No ready tasks, $IN_PROGRESS_COUNT in progress." >&2
    exit 0
  fi
  echo "OpenSpec loop: No work found." >&2
  exit 0
fi

TASK_ID=$(echo "$NEXT_TASK" | jq -r '.id')
TASK_TITLE=$(echo "$NEXT_TASK" | jq -r '.title')

# Get parent epic to find the OpenSpec change-id
PARENT_ID=$(echo "$NEXT_TASK" | jq -r '.parent // empty')
CHANGE_ID=""
if [[ -n "$PARENT_ID" ]]; then
  # Epic title is the change-id
  CHANGE_ID=$(bd show "$PARENT_ID" --json 2>/dev/null | jq -r '.title // empty')
fi

# Update state
NEXT_ITERATION=$((ITERATION + 1))
jq --argjson iter "$NEXT_ITERATION" --arg task "$TASK_ID" \
  '.iteration = $iter | .current_task = $task' \
  "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

# Build prompt with change context
CHANGE_CONTEXT=""
if [[ -n "$CHANGE_ID" ]]; then
  CHANGE_CONTEXT="Change: $CHANGE_ID (Epic: $PARENT_ID)
Spec files: openspec/changes/$CHANGE_ID/

"
fi

PROMPT="OpenSpec Apply (Beads) | Task: $TASK_ID

${CHANGE_CONTEXT}Current task: $TASK_TITLE

Guardrails:
- Favor straightforward, minimal implementations; keep scope tight.
- Refer to openspec/AGENTS.md if conventions are unclear.

Steps:
1. Claim the task in Beads:
   \`\`\`bash
   bd update $TASK_ID --status in_progress
   bd sync
   \`\`\`

2. Read the OpenSpec change files for context:
   - openspec/changes/$CHANGE_ID/proposal.md
   - openspec/changes/$CHANGE_ID/tasks.md
   - openspec/changes/$CHANGE_ID/design.md (if exists)

3. Implement the task, keeping changes minimal and focused.

4. Update tasks.md to reflect progress:
   - Mark task as in-progress: \`- [-]\`
   - When done: \`- [x]\`

5. Complete the task in Beads:
   \`\`\`bash
   bd close $TASK_ID --reason \"Completed: <brief summary>\"
   bd sync
   \`\`\`

6. Commit your work:
   \`\`\`bash
   git add -A && git commit -m \"$CHANGE_ID: $TASK_ID - <brief summary>\"
   \`\`\`

BLOCKED Status:
If you cannot proceed due to a spec issue, output: BLOCKED: <reason>"

if [[ -n "$VERIFY_COMMANDS" ]]; then
  PROMPT="$PROMPT

Verification (run after epic completion):
\`\`\`bash
$VERIFY_COMMANDS
\`\`\`"
fi

PROGRESS_MSG="🔄 Iteration $NEXT_ITERATION | Ready: $READY_COUNT | In Progress: $IN_PROGRESS_COUNT | Task: $TASK_ID"

jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "$PROGRESS_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
