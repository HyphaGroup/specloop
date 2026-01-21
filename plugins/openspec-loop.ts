import type { Plugin } from "@opencode-ai/plugin"
import { readFileSync, existsSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { execSync } from "node:child_process"

interface LoopState {
  active: boolean
  iteration: number
  max_iterations: number
  current_task?: string
  stuck_count: number
  verify_commands: string[]
  blocked_reason?: string
  stuck_reason?: string
}

interface BeadsTask {
  id: string
  title: string
  status: string
  parent?: string
}

interface BeadsEpic {
  id: string
  title: string
  status: string
}

const getStateFile = (dir: string) => join(dir, ".opencode", "openspec-loop.json")
const getProgressFile = (dir: string) => join(dir, ".opencode", "openspec-loop-progress.md")

const readState = (dir: string): LoopState | null => {
  const stateFile = getStateFile(dir)
  if (!existsSync(stateFile)) return null
  try {
    return JSON.parse(readFileSync(stateFile, "utf-8"))
  } catch {
    return null
  }
}

const writeState = (dir: string, state: LoopState) => {
  writeFileSync(getStateFile(dir), JSON.stringify(state, null, 2))
}

const hasBd = (): boolean => {
  try {
    execSync("which bd", { encoding: "utf-8" })
    return true
  } catch {
    return false
  }
}

const getBeadsReadyTasks = (dir: string): BeadsTask[] => {
  try {
    return JSON.parse(execSync("bd ready --json", { cwd: dir, encoding: "utf-8" }))
  } catch {
    return []
  }
}

const getBeadsInProgressTasks = (dir: string): BeadsTask[] => {
  try {
    return JSON.parse(execSync("bd list --status in_progress --json", { cwd: dir, encoding: "utf-8" }))
  } catch {
    return []
  }
}

const getBeadsEpics = (dir: string): BeadsEpic[] => {
  try {
    return JSON.parse(execSync("bd list --type epic --json", { cwd: dir, encoding: "utf-8" }))
  } catch {
    return []
  }
}

const getBeadsBlockedTasks = (dir: string): BeadsTask[] => {
  try {
    return JSON.parse(execSync("bd blocked --json", { cwd: dir, encoding: "utf-8" }))
  } catch {
    return []
  }
}

const getBeadsStats = (dir: string): string => {
  try {
    return execSync("bd stats", { cwd: dir, encoding: "utf-8" }).split("\n").slice(0, 10).join("\n")
  } catch {
    return "(unable to get stats)"
  }
}

const getBeadsIssue = (dir: string, id: string): { id: string; title: string } | null => {
  try {
    return JSON.parse(execSync(`bd show ${id} --json`, { cwd: dir, encoding: "utf-8" }))
  } catch {
    return null
  }
}

const buildPrompt = (task: BeadsTask, changeId: string | null, parentId: string | null, verifyCommands: string[]): string => {
  let changeContext = ""
  if (changeId) {
    changeContext = `Change: ${changeId} (Epic: ${parentId})
Spec files: openspec/changes/${changeId}/

`
  }

  let prompt = `OpenSpec Apply (Beads) | Task: ${task.id}

${changeContext}Current task: ${task.title}

Guardrails:
- Favor straightforward, minimal implementations; keep scope tight.
- Refer to openspec/AGENTS.md if conventions are unclear.

Steps:
1. Claim the task in Beads:
   \`\`\`bash
   bd update ${task.id} --status in_progress
   bd sync
   \`\`\`

2. Read the OpenSpec change files for context:
   - openspec/changes/${changeId || '<change-id>'}/proposal.md
   - openspec/changes/${changeId || '<change-id>'}/tasks.md
   - openspec/changes/${changeId || '<change-id>'}/design.md (if exists)

3. Implement the task, keeping changes minimal and focused.

4. Update tasks.md to reflect progress:
   - Mark task as in-progress: \`- [-]\`
   - When done: \`- [x]\`

5. Complete the task in Beads:
   \`\`\`bash
   bd close ${task.id} --reason "Completed: <brief summary>"
   bd sync
   \`\`\`

6. Commit your work:
   \`\`\`bash
   git add -A && git commit -m "${changeId || '<change>'}: ${task.id} - <brief summary>"
   \`\`\`

BLOCKED Status:
If you cannot proceed due to a spec issue, output: BLOCKED: <reason>`

  if (verifyCommands.length > 0) {
    prompt += `

Verification (run after epic completion):
\`\`\`bash
${verifyCommands.join(" && ")}
\`\`\``
  }

  return prompt
}

export const OpenSpecLoopPlugin: Plugin = async ({ directory, client, $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return

      const state = readState(directory)
      if (!state || !state.active) return

      // Require bd
      if (!hasBd()) {
        await client.app.log({
          service: "openspec-loop",
          level: "error",
          message: "OpenSpec loop requires bd (Beads). Install: npm install -g @beads/bd",
        })
        state.active = false
        state.stuck_reason = "bd not installed"
        writeState(directory, state)
        return
      }

      // Check max iterations
      if (state.max_iterations > 0 && state.iteration >= state.max_iterations) {
        await client.app.log({
          service: "openspec-loop",
          level: "info",
          message: `Max iterations (${state.max_iterations}) reached. Stopping loop.`,
        })
        state.active = false
        writeState(directory, state)
        return
      }

      const readyTasks = getBeadsReadyTasks(directory)
      const inProgressTasks = getBeadsInProgressTasks(directory)
      const epics = getBeadsEpics(directory)
      const incompleteEpics = epics.filter(e => e.status !== "closed")

      // Check completion
      if (readyTasks.length === 0 && inProgressTasks.length === 0) {
        if (incompleteEpics.length === 0) {
          const progressFile = getProgressFile(directory)
          let summary = "OpenSpec Loop Complete (Beads)!\n\n"
          summary += `Beads Summary:\n${getBeadsStats(directory)}\n\n`
          if (existsSync(progressFile)) {
            summary += `Progress:\n${readFileSync(progressFile, "utf-8")}`
          }
          await client.app.log({
            service: "openspec-loop",
            level: "info",
            message: summary,
          })
          state.active = false
          writeState(directory, state)
          await $`osascript -e 'display notification "All Beads epics complete!" with title "OpenCode"'`.quiet()
          return
        } else {
          const blockedTasks = getBeadsBlockedTasks(directory)
          if (blockedTasks.length > 0) {
            await client.app.log({
              service: "openspec-loop",
              level: "warn",
              message: `${blockedTasks.length} tasks blocked, no ready tasks. Stopping.`,
            })
            state.active = false
            state.stuck_reason = "All tasks blocked"
            writeState(directory, state)
            return
          }
        }
      }

      // Get next task
      const nextTask = readyTasks[0]
      if (!nextTask) {
        if (inProgressTasks.length > 0) {
          await client.app.log({
            service: "openspec-loop",
            level: "info",
            message: `No ready tasks, ${inProgressTasks.length} in progress.`,
          })
          return
        }
        await client.app.log({
          service: "openspec-loop",
          level: "info",
          message: "No work found.",
        })
        return
      }

      // Get parent epic to find change-id
      let changeId: string | null = null
      let parentId: string | null = nextTask.parent || null
      if (parentId) {
        const epic = getBeadsIssue(directory, parentId)
        if (epic) {
          changeId = epic.title
        }
      }

      // Update state
      state.iteration++
      state.current_task = nextTask.id
      writeState(directory, state)

      await client.app.log({
        service: "openspec-loop",
        level: "info",
        message: `🔄 Iteration ${state.iteration} | Ready: ${readyTasks.length} | In Progress: ${inProgressTasks.length} | Task: ${nextTask.id}${changeId ? ` (${changeId})` : ''}`,
      })

      const prompt = buildPrompt(nextTask, changeId, parentId, state.verify_commands)
      await client.message.create({
        session: event.properties.sessionID,
        parts: [{ type: "text", text: prompt }],
      })
    },
  }
}
