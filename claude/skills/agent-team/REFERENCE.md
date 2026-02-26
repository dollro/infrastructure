# Agent Team — API Reference

Companion reference for the `agent-team` skill.

---

## Built-in Agent Controls (In-Process Mode)

| Key | Action |
|-----|--------|
| **Shift+Down / Shift+Up** | Cycle through teammates |
| **Enter** | View selected teammate's live session |
| **Escape** | Back to lead / interrupt teammate |
| **Ctrl+T** | Toggle task list overlay |
| **Shift+Tab** | Toggle Delegate Mode |

**Delegate Mode** restricts the lead to coordination tools only (no Edit, Write, Bash). The lead can only spawn teammates, send messages, manage the task list, and shut down teammates. This is the correct mode for team coordination — it also auto-approves tool use for agents.

---

## Primitives

| Primitive | What It Is | Location |
|-----------|-----------|----------|
| **Team** | Named group of agents. One leader, multiple teammates. | `~/.claude/teams/{name}/config.json` |
| **Teammate** | Agent that joined a team. Has name, color, inbox. | Listed in team config |
| **Task** | Work item with subject, status, owner, dependencies. | `~/.claude/tasks/{team}/N.json` |
| **Inbox** | JSON file for receiving messages. | `~/.claude/teams/{name}/inboxes/{agent}.json` |

### Subagent vs Teammate

| Aspect | `Task({...})` (Subagent) | `Task({ team_name, name, ... })` (Teammate) |
|--------|--------------------------|----------------------------------------------|
| Lifespan | Until task complete | Until shutdown requested |
| Communication | Returns result directly | Inbox messages |
| Task access | None | Shared task list |
| Visibility | Shift+Down → Enter to view | Same |
| Best for | One-off searches, analysis | Parallel builds, ongoing work |

---

## Teammate Operations

### spawnTeam
```
Teammate({ operation: "spawnTeam", team_name: "my-project", description: "Building feature X" })
```

### write — Message One Teammate
```
Teammate({ operation: "write", target_agent_id: "backend", value: "Contract changed: ..." })
```

### broadcast — Message ALL Teammates
```
Teammate({ operation: "broadcast", name: "team-lead", value: "Critical change" })
```
Sends N messages for N teammates. Prefer `write`.

### requestShutdown
```
Teammate({ operation: "requestShutdown", target_agent_id: "backend", reason: "Done" })
```

### approveShutdown / rejectShutdown (Teammate calls)
```
Teammate({ operation: "approveShutdown", request_id: "shutdown-123" })
Teammate({ operation: "rejectShutdown", request_id: "shutdown-123", reason: "Still working" })
```

### approvePlan / rejectPlan (Leader)
```
Teammate({ operation: "approvePlan", target_agent_id: "architect", request_id: "plan-456" })
Teammate({ operation: "rejectPlan", target_agent_id: "architect", request_id: "plan-456", feedback: "..." })
```

### cleanup
```
Teammate({ operation: "cleanup" })
```
Fails if teammates still active.

---

## Task System

```
TaskCreate({ subject: "Implement API", description: "...", activeForm: "Building API..." })
TaskList()
TaskGet({ taskId: "2" })
TaskUpdate({ taskId: "2", owner: "backend" })
TaskUpdate({ taskId: "2", status: "in_progress" })
TaskUpdate({ taskId: "2", status: "completed" })
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })
```
Blocked tasks auto-unblock when dependencies complete.

---

## Spawning Agents

### Subagent (No Team, Synchronous)
```
Task({ subagent_type: "Explore", description: "Find auth files", prompt: "...", model: "haiku" })
```

### Teammate (Team, Background)
```
Task({ team_name: "project-build", name: "backend", subagent_type: "general-purpose", run_in_background: true, prompt: "..." })
```

### With Plan Approval
```
Task({ team_name: "project-build", name: "architect", subagent_type: "Plan", mode: "plan", run_in_background: true, prompt: "..." })
```

### Built-in Agent Types

| Type | Tools | Model | Best For |
|------|-------|-------|----------|
| `general-purpose` | All | Inherited | Implementation |
| `Explore` | Read-only | Haiku | Search, research |
| `Plan` | Read-only | Inherited | Architecture |
| `Bash` | Bash only | Inherited | Git, commands |

---

## Orchestration Patterns

**Parallel Specialists** — Contracts first → spawn all → parallel build → integration test.

**Pipeline** — Sequential tasks via `addBlockedBy`. Each stage needs the previous output.

**Swarm** — Pool of independent tasks, N workers with identical prompts race to claim.

**Research + Implementation** — Synchronous subagent for research → results feed teammate prompts.

---

## Optional: Zellij Monitoring Dashboard

If running inside zellij, the skill can open a supplementary monitoring tab with `scripts/watch-*.sh`. This gives a bird's-eye overview of tasks, inbox, and team members — complementing the built-in keyboard controls.

The scripts poll JSON files on disk:
- `watch-tasks.sh` — polls `~/.claude/tasks/*/?.json`
- `watch-inbox.sh` — tails `~/.claude/teams/*/inboxes/team-lead.json`
- `watch-team.sh` — polls `~/.claude/teams/*/config.json`

---

## Debugging

```bash
# Team config
cat ~/.claude/teams/*/config.json | jq '.members[] | {name, agentType, backendType}'

# All inboxes
for f in ~/.claude/teams/*/inboxes/*.json; do echo "=== $(basename $f) ==="; cat "$f" | jq '.'; done

# Task states
cat ~/.claude/tasks/*/?.json | jq '{id, subject, status, owner, blockedBy}'

# Verify agent teams enabled
grep -r "AGENT_TEAMS" ~/.claude/settings.json
```

### Common Errors

| Error | Fix |
|-------|-----|
| "Cannot cleanup with active members" | `requestShutdown` all agents first |
| "Already leading a team" | `cleanup` first or use different name |
| "Agent not found" | Check `config.json` for actual names |
| "Team does not exist" | `spawnTeam` first |

---

*Ref: https://code.claude.com/docs/en/agent-teams*
