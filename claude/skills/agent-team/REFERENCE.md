# Agent Team — API Reference & Zellij Integration

Companion reference for the `agent-team` skill. Consult when you need exact syntax or troubleshooting.

---

## Claude Code Agent Team Primitives

| Primitive | What It Is | Location |
|-----------|-----------|----------|
| **Agent** | A Claude instance with tools. You are an agent. | N/A (process) |
| **Team** | A named group of agents. One leader, multiple teammates. | `~/.claude/teams/{name}/config.json` |
| **Teammate** | An agent that joined a team. Has name, color, inbox. | Listed in team config |
| **Leader** | The agent that created the team. Receives messages, approves plans. | First member in config |
| **Task** | A work item with subject, status, owner, dependencies. | `~/.claude/tasks/{team}/N.json` |
| **Inbox** | JSON file where an agent receives messages. | `~/.claude/teams/{name}/inboxes/{agent}.json` |

### Subagent vs Teammate

| Aspect | `Task({...})` (Subagent) | `Task({ team_name, name, ... })` (Teammate) |
|--------|--------------------------|----------------------------------------------|
| Lifespan | Until task complete | Until shutdown requested |
| Communication | Returns result directly | Inbox messages |
| Task access | None | Shared task list |
| Team membership | No | Yes |
| Best for | One-off searches, analysis | Parallel builds, ongoing work |

---

## Teammate Tool Operations

### spawnTeam
```
Teammate({ operation: "spawnTeam", team_name: "my-project", description: "Building feature X" })
```
Creates `~/.claude/teams/{name}/` and `~/.claude/tasks/{name}/`. You become leader.

### write — Message One Teammate
```
Teammate({ operation: "write", target_agent_id: "backend", value: "Contract changed: ..." })
```
**Critical:** Agent text output is NOT visible to the team. Agents MUST use `write` to communicate.

### broadcast — Message ALL Teammates
```
Teammate({ operation: "broadcast", name: "team-lead", value: "Critical change affecting everyone" })
```
Sends N messages for N teammates. Prefer `write` for targeted communication.

### requestShutdown
```
Teammate({ operation: "requestShutdown", target_agent_id: "backend", reason: "All tasks complete" })
```

### approveShutdown (Teammate calls this)
```
Teammate({ operation: "approveShutdown", request_id: "shutdown-123" })
```

### rejectShutdown (Teammate calls this)
```
Teammate({ operation: "rejectShutdown", request_id: "shutdown-123", reason: "Still working" })
```

### approvePlan / rejectPlan (Leader)
```
Teammate({ operation: "approvePlan", target_agent_id: "architect", request_id: "plan-456" })
Teammate({ operation: "rejectPlan", target_agent_id: "architect", request_id: "plan-456", feedback: "Add error handling" })
```

### cleanup
```
Teammate({ operation: "cleanup" })
```
Fails if teammates still active. Always `requestShutdown` first.

---

## Task System

### TaskCreate
```
TaskCreate({ subject: "Review auth module", description: "Review all files in app/services/auth/...", activeForm: "Reviewing auth module..." })
```

### TaskList / TaskGet
```
TaskList()                    // All tasks with status, owner, blockedBy
TaskGet({ taskId: "2" })     // Full details for one task
```

### TaskUpdate
```
TaskUpdate({ taskId: "2", owner: "backend" })              // Claim
TaskUpdate({ taskId: "2", status: "in_progress" })         // Start
TaskUpdate({ taskId: "2", status: "completed" })           // Done
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })      // Dependencies
```
When a blocking task completes, blocked tasks auto-unblock.

---

## Spawning Agents

### Subagent (No Team, Synchronous)
```
Task({ subagent_type: "Explore", description: "Find auth files", prompt: "Find all auth files", model: "haiku" })
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
| `general-purpose` | All | Inherited | Implementation, multi-step tasks |
| `Explore` | Read-only | Haiku (fast) | Codebase search, file discovery |
| `Plan` | Read-only | Inherited | Architecture, design planning |
| `Bash` | Bash only | Inherited | Git ops, command execution |

---

## Zellij Integration

Agents run via `in-process` backend. Zellij provides **visualization and monitoring**.

### Workflow

```bash
zellij                                    # 1. start zellij
claude --dangerously-skip-permissions     # 2. start claude with auto-approve
# then ask claude to build with agent team — the skill handles monitoring setup
```

### Monitoring Layout

The skill generates a KDL layout at runtime pointing to bundled `scripts/watch-*.sh` files and opens it as a zellij tab via `zellij action new-tab`.

### Per-Agent Inbox Panes

Open floating panes tailing each agent's inbox:
```bash
zellij run -f -n "📬 backend" -- bash -c "
    while [ ! -f ~/.claude/teams/TEAM/inboxes/backend.json ]; do sleep 1; done
    tail -f ~/.claude/teams/TEAM/inboxes/backend.json | jq '.' 2>/dev/null || cat
"
```

### Dynamic Layout Generation

```bash
generate_agent_layout() {
    local team_name="$1"; shift; local agents=("$@")
    local layout="/tmp/agent-inboxes-${team_name}.kdl"
    echo 'layout {' > "$layout"
    echo '    pane split_direction="horizontal" {' >> "$layout"
    for agent in "${agents[@]}"; do
        cat >> "$layout" << EOF
        pane name="${agent}" command="bash" {
            args "-c" "tail -f ~/.claude/teams/${team_name}/inboxes/${agent}.json 2>/dev/null | jq '.' 2>/dev/null || (echo 'Waiting...'; sleep infinity)"
        }
EOF
    done
    echo '    }' >> "$layout"; echo '}' >> "$layout"; echo "$layout"
}
# Usage:
zellij action new-tab --layout $(generate_agent_layout "project-build" "backend" "frontend") -n "Inboxes"
```

### Useful Zellij Commands

```bash
zellij action rename-pane "backend-agent"              # Rename focused pane
zellij action dump-screen /tmp/agent-output.txt        # Capture pane scrollback
zellij action toggle-floating-panes                    # Show/hide floating inbox panes
zellij action stack-panes -- terminal_1 terminal_2     # Stack panes to save space
zellij action close-pane                               # Close focused pane
zellij action close-tab                                # Close focused tab
```

---

## Message Formats (Inbox JSON)

| Type | Key Fields |
|------|------------|
| Regular message | `from`, `text`, `timestamp`, `read` |
| Idle notification | `type: "idle_notification"`, `from`, `completedTaskId`, `completedStatus` |
| Shutdown request | `type: "shutdown_request"`, `requestId`, `from`, `reason` |
| Shutdown approved | `type: "shutdown_approved"`, `requestId`, `from`, `backendType` |
| Plan approval request | `type: "plan_approval_request"`, `from`, `requestId`, `planContent` |

---

## Orchestration Patterns

**Parallel Specialists** — Leader defines contracts → spawns all agents → parallel build → integration test. Best for components with clear boundaries.

**Pipeline** — Sequential task chain via `addBlockedBy`. Best when each stage needs the previous output.

**Swarm** — Pool of independent tasks, N workers with identical prompts race to claim. Best for many similar tasks.

**Research + Implementation** — Synchronous subagent for research → results feed into teammate prompts.

---

## Debugging

```bash
# Team config
cat ~/.claude/teams/*/config.json | jq '.members[] | {name, agentType, backendType}'

# All inboxes
for f in ~/.claude/teams/*/inboxes/*.json; do echo "=== $(basename $f) ==="; cat "$f" | jq '.'; done

# Task states
cat ~/.claude/tasks/*/?.json | jq '{id, subject, status, owner, blockedBy}'

# Live inbox in zellij floating pane
zellij run -f -n "inbox" -- tail -f ~/.claude/teams/*/inboxes/team-lead.json

# Verify agent teams enabled
grep -r "AGENT_TEAMS" ~/.claude/settings.json
```

### Common Errors

| Error | Fix |
|-------|-----|
| "Cannot cleanup with active members" | `requestShutdown` all agents first |
| "Already leading a team" | `cleanup` first or use different name |
| "Agent not found" | Check `config.json` for actual agent names |
| "Team does not exist" | `spawnTeam` first |

---

*Based on Claude Code Agent Teams API. Ref: https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea*
