---
name: agent-team
description: Build a project using Claude Code Agent Teams. Use when the user wants multiple agents collaborating on a build, mentions "agent team", "parallel build", "swarm", or asks to split work across agents.
---

# Build with Agent Team

You are the **lead agent** coordinating a parallel build using Claude Code Agent Teams. Your role is strictly coordination — you do NOT write code yourself. You design a team with contracts, spawn teammates, and orchestrate their work.

For exact API syntax and message formats, see [REFERENCE.md](REFERENCE.md).

## Prerequisites

**Execute this check block first:**

```bash
# Agent teams enabled?
grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" ~/.claude/settings.json 2>/dev/null \
    && echo "✅ Agent teams enabled" \
    || echo "❌ Add CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to ~/.claude/settings.json"
```

### Tool Permissions

Agents inherit the parent's permission model. Without auto-approval, every file edit by every agent triggers a confirmation prompt.

**Check if permissions are handled:**
- If the user started with `claude --dangerously-skip-permissions` → good.
- Otherwise tell them to press **Shift+Tab** (Delegate Mode) which both auto-approves tools AND prevents the lead from coding directly — the correct mode for team coordination.

**Wait for confirmation before spawning agents.**

### Optional: Zellij Monitoring Dashboard

If the user is running inside zellij (`$ZELLIJ` is set), you can open a supplementary monitoring tab showing task states and inbox activity. This is **optional** — the built-in agent controls (see below) are the primary way to observe agents.

```bash
if [ -n "$ZELLIJ" ]; then
    SKILL_SCRIPTS="$(find ~/.claude/skills -path '*/agent-team/scripts/watch-tasks.sh' 2>/dev/null | head -1 | xargs dirname 2>/dev/null)"
    [ -z "$SKILL_SCRIPTS" ] && SKILL_SCRIPTS="$(find .claude/skills -path '*/agent-team/scripts/watch-tasks.sh' 2>/dev/null | head -1 | xargs dirname 2>/dev/null)"
    if [ -n "$SKILL_SCRIPTS" ]; then
        chmod +x "$SKILL_SCRIPTS"/*.sh 2>/dev/null
        cat > /tmp/agent-monitor.kdl << KDL
layout {
    pane split_direction="vertical" {
        pane name="Tasks" size="50%" command="${SKILL_SCRIPTS}/watch-tasks.sh"
        pane split_direction="horizontal" size="50%" {
            pane name="Leader Inbox" command="${SKILL_SCRIPTS}/watch-inbox.sh"
            pane name="Team Members" command="${SKILL_SCRIPTS}/watch-team.sh"
        }
    }
}
KDL
        zellij action new-tab --layout /tmp/agent-monitor.kdl -n "Agent Monitor"
        echo "✅ Zellij monitor tab opened"
    fi
fi
```

## Inputs

The user provides:
- **Plan path** — path to a markdown plan file describing what to build (ask if not provided)
- **Team size** — number of agents (optional, derive from plan if not specified)

---

## How to Observe and Control Agents

Agents run in-process. You observe them through **built-in keyboard controls** in the lead terminal:

| Key | Action |
|-----|--------|
| **Shift+Down / Shift+Up** | Cycle through teammates — select one |
| **Enter** | View the selected teammate's live session (full output, reasoning, file edits) |
| **Escape** | Go back to the lead / interrupt a teammate's turn |
| **Ctrl+T** | Toggle the task list overlay |
| **Shift+Tab** | Toggle Delegate Mode (lead can only coordinate, not code) |

**This is how you watch agents work.** You see their full reasoning, tool calls, and file edits in real-time — just navigate to them with Shift+Down then Enter.

---

## Phase 1: Understand the Project

1. Read `CLAUDE.md` at the project root (if it exists) — conventions, tech stack, build/test commands
2. Read `docs/index.md` (if it exists) — architecture, module structure
3. Scan the directory structure and key files

Then read the plan file. Identify: what are we building, what are the major components, what are the dependencies, is this greenfield or extending existing code.

## Phase 2: Decide on Team vs Solo

Use a **single agent** if the work is linear or touches few files. Use **agent teams** if there are 2+ independent components with clear boundaries. Say so if solo is sufficient.

## Phase 3: Design Team Structure

If the user specified a team size, use it. Otherwise derive from the plan.

**Sizing:** 2 agents for two independent layers, 3 for three distinct areas, 4+ for large systems.

**For each agent define:**
- **Name** — short, descriptive (e.g., `backend`, `auth-service`, `ui`)
- **Ownership** — exact files/directories they own exclusively
- **Off-limits** — files they must NOT touch
- **Responsibilities** — what they build from the plan
- **Agent type** (`subagent_type`):
  - `general-purpose` — full tools, best for implementation
  - `Explore` — read-only, haiku model, best for search/research
  - `Plan` — read-only, best for architecture
  - `Bash` — bash only, best for commands/git

## Phase 4: Define Contracts BEFORE Spawning

At each integration boundary, define:
- **Exact interface** — function signatures, endpoints, data shapes
- **Exact data structures** — concrete examples in code/JSON, NOT prose
- **Error/edge cases**

Identify **cross-cutting concerns** and assign each to exactly one agent.

**Quality check:** Could two agents build to this independently and integrate on the first try?

## Phase 5: Create Team, Tasks, and Spawn

### 5a. Create the Team
```
Teammate({ operation: "spawnTeam", team_name: "project-build", description: "Building [what]" })
```

### 5b. Create Tasks with Dependencies
```
TaskCreate({ subject: "Implement backend", description: "...", activeForm: "Building backend..." })
TaskCreate({ subject: "Implement frontend", description: "...", activeForm: "Building frontend..." })
TaskCreate({ subject: "Integration test", description: "...", activeForm: "Testing..." })
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })
```

### 5c. Enter Delegate Mode

Press **Shift+Tab** to enter Delegate Mode. This:
- Auto-approves tool use for all agents (solves the permission prompt problem)
- Restricts YOUR tools to coordination only (no Edit, Write, Bash) — you can only spawn, message, manage tasks, and shutdown
- This is the correct mode for team coordination

### 5d. Spawn All Agents in Parallel

Spawn each with `team_name` + `name` + `run_in_background: true`. Include full context:

```
Task({
  team_name: "project-build",
  name: "backend",
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: `You are the backend agent.

## Project Context
[From CLAUDE.md]

## Your Ownership
- You own: [dirs/files]
- Do NOT touch: [other agents' files]

## What You're Building
[From plan]

## Contracts
### You Produce
[Exact spec] — message the lead if you need to deviate:
Teammate({ operation: "write", target_agent_id: "team-lead", value: "..." })

### You Consume
[Exact spec] — build against this exactly

### Cross-Cutting Concerns You Own
[Shared behaviors assigned to you]

## Task
Claim: TaskUpdate({ taskId: "1", owner: "backend", status: "in_progress" })
Done: TaskUpdate({ taskId: "1", status: "completed" })

## Validate Before Done
1. [build/test/lint command]
2. [acceptance check]
Do NOT mark complete until all pass.`
})
```

Repeat for each agent. After spawning, use **Shift+Down** and **Enter** to watch each agent working live.

## Phase 6: Orchestrate

- **Watch agents live** — Shift+Down to select, Enter to view their session
- **Check task list** — Ctrl+T to toggle the task list overlay
- **Relay contract issues** — `Teammate({ operation: "write", target_agent_id: "...", value: "..." })`
- **Broadcast sparingly** — `Teammate({ operation: "broadcast", name: "team-lead", value: "..." })` sends N messages
- **Track progress** — `TaskList()` or Ctrl+T
- **Idle agents are normal** — send a message to wake them

### Contract Verification Before Integration
Ask each agent what interfaces they implemented. Compare both sides. Flag mismatches.

## Phase 7: Validate

After `TaskList()` shows all complete:
1. Can the system start?
2. Does the happy path work?
3. Do integrations connect?
4. Are edge cases handled?

If failed, message the relevant agent — it wakes from idle.

## Phase 8: Shutdown and Cleanup

```
Teammate({ operation: "requestShutdown", target_agent_id: "backend", reason: "Build complete" })
Teammate({ operation: "requestShutdown", target_agent_id: "frontend", reason: "Build complete" })
// Wait for approvals
Teammate({ operation: "cleanup" })
```

---

## Common Pitfalls

1. **Permission prompts blocking agents** — enter Delegate Mode (Shift+Tab) before spawning
2. **Lead coding instead of coordinating** — Delegate Mode prevents this (removes Edit/Write/Bash from lead)
3. **Can't see agent output** — use Shift+Down then Enter to view any agent's live session
4. **Spawning without contracts** — define ALL contracts first
5. **Vague contracts** — require exact JSON shapes, not prose
6. **Broadcasting everything** — use targeted `write`
7. **Missing project context** — include CLAUDE.md in spawn prompts
8. **Orphaned cross-cutting concerns** — assign each to one agent

---

## Execute

1. **Prerequisites** — verify agent teams enabled
2. **Tool permissions** — confirm `--dangerously-skip-permissions` or Delegate Mode. **Wait for user.**
3. **Read project context** — `CLAUDE.md`, `docs/index.md`
4. **Read the plan**
5. **Assess team vs solo**
6. **Optionally** open zellij monitoring tab (if in zellij)
7. **Design team + define contracts**
8. **Create team**: `Teammate({ operation: "spawnTeam", ... })`
9. **Create tasks** + dependencies
10. **Enter Delegate Mode** (Shift+Tab)
11. **Spawn all agents** with `run_in_background: true`
12. **Watch agents work** — Shift+Down, Enter to view live sessions
13. **Orchestrate** — relay messages, mediate contracts, check Ctrl+T task list
14. **Contract diff** before integration
15. **End-to-end validation**
16. **Shutdown** → `cleanup`
17. **Confirm** build meets the plan
