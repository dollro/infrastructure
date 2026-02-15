---
name: agent-team
description: Build a project using Claude Code Agent Teams with built-in team orchestration. Takes a plan document path and optional team size. Use when you want multiple agents collaborating on a build.
argument-hint: [plan-path] [num-agents]
disable-model-invocation: true
---

# Build with Agent Team

You are coordinating a build using Claude Code Agent Teams. Your job is to understand the project, design a team, define contracts, spawn agents in parallel, and orchestrate the build.

You use the built-in team orchestration tools: `TeamCreate` for team setup, `TaskCreate`/`TaskUpdate`/`TaskList` for task tracking, `Task` with `team_name`/`name` for spawning teammates, and `SendMessage` for communication.

## Arguments

- **Plan path**: `$ARGUMENTS[0]` — Path to a markdown file describing what to build
- **Team size**: `$ARGUMENTS[1]` — Number of agents (optional, you'll determine this if not given)

---

## Step 1: Understand the Project

Before reading the plan, understand the project you're working in.

1. **Read `CLAUDE.md`** at the project root (if it exists). This tells you about the project's conventions, tech stack, build commands, test commands, and architectural decisions.
2. **Read `docs/index.md`** (if it exists). This gives you deeper architectural context, module structure, and design rationale.
3. **Scan the existing codebase** — look at the directory structure, key files, and existing patterns. Understand what already exists vs. what the plan is adding.

Only after you understand the project context, read the plan at `$ARGUMENTS[0]`.

When reading the plan, understand:
- What are we building or changing?
- What are the major components or layers?
- What technologies and patterns are already in use?
- What are the dependencies between components?
- Is this greenfield or extending existing code?

---

## Step 2: Assess Whether Agent Teams Are Needed

Not every build benefits from multiple agents. Consider:

- **Use a single agent** if the work is linear, touches few files, or has tight sequential dependencies
- **Use agent teams** if there are independent components that can be built in parallel with clear boundaries

If you determine a single agent is sufficient, say so and proceed without the team machinery.

---

## Step 3: Determine Team Structure

If team size is specified (`$ARGUMENTS[1]`), use that number. Otherwise, derive it from the plan.

**Sizing heuristics:**
- 2 agents: Two clearly independent layers or concerns
- 3 agents: Three distinct ownership areas with integration points
- 4+ agents: Large systems with many independent modules

**For each agent, define:**
1. **Name** — Short, descriptive, derived from the project's actual architecture (not generic labels)
2. **Ownership** — Exact files and directories they own exclusively
3. **Does NOT touch** — What's off-limits (prevents merge conflicts)
4. **Key responsibilities** — What they're building, in terms of the plan
5. **Agent type** — Choose the appropriate `subagent_type`:
   - `fullstack-developer` for implementation agents building features end-to-end
   - `code-reviewer` for review/validation agents
   - `general-purpose` as fallback for mixed or unusual work

---

## Step 4: Create Team and Tasks

### Create the Team

Use `TeamCreate` with a meaningful name and description derived from the project:

```
TeamCreate:
  team_name: "project-build"   # derived from project/plan name
  description: "Building [what the plan describes]"
```

This automatically creates a shared task list at `~/.claude/tasks/{team-name}/`.

### Create Tasks with Dependencies

Use `TaskCreate` for each agent's deliverable and for integration testing. Use `TaskUpdate` to set up dependencies with `addBlockedBy`.

```
TaskCreate: "Implement backend API endpoints"
  description: "Build REST endpoints matching the Backend→Frontend contract..."
  activeForm: "Implementing backend API endpoints"

TaskCreate: "Implement frontend UI components"
  description: "Build UI components consuming the Backend→Frontend contract..."
  activeForm: "Implementing frontend UI components"

TaskCreate: "Integration testing"
  description: "Verify all contract boundaries connect correctly..."
  activeForm: "Running integration tests"

TaskUpdate: integration-task
  addBlockedBy: [backend-task, frontend-task]
```

Since contracts are defined upfront, implementation tasks have no inter-agent blocking — only integration testing is blocked by implementation tasks.

---

## Step 5: Define Contracts

This is the critical step that makes parallel work possible. Agents building in parallel will diverge on interfaces unless they start with agreed-upon contracts.

### How to Think About Contracts

Identify where components integrate — where one agent's output becomes another agent's input. At each integration boundary, define the contract with enough specificity that both sides can build independently.

A good contract specifies:
- **Exact interface** — function signatures, endpoint URLs, data shapes, file formats, whatever the boundary requires
- **Exact data structures** — concrete examples, not prose descriptions
- **Error/edge cases** — what happens when things go wrong

A bad contract says "the backend returns sessions." A good contract shows the exact JSON shape, URL, and status codes — or the exact function signature, parameter types, and return types — whatever is appropriate for the project.

### Identify Cross-Cutting Concerns

Some behaviors span multiple agents and will fall through the cracks unless explicitly assigned. Look for:
- Conventions that both sides of a boundary must agree on
- Shared configuration, constants, or types
- Behaviors that affect multiple layers (error handling, logging, state management)

Assign each cross-cutting concern to exactly one agent.

### Contract Quality Check

Before including a contract in agent prompts, verify:
- Is it specific enough that two agents could build to it independently and integrate on the first try?
- Are data shapes shown as concrete examples (code, JSON, types), not prose?
- Are edge cases covered?

<details>
<summary><strong>Example: Web Application Contracts</strong></summary>

For a typical web app with Database → Backend → Frontend layers:

**Database → Backend contract:**
```
Function signatures:
  create_session(title: str) -> Session
  get_session(id: UUID) -> Session | None
  add_message(session_id: UUID, role: str, content: str) -> Message

Pydantic models:
  Session(id: UUID, title: str, created_at: datetime)
  Message(id: UUID, session_id: UUID, role: str, content: str, created_at: datetime)
```

**Backend → Frontend contract:**
```
POST /api/sessions/
  Request: {"title": "New chat"}
  Response 201: {"id": "uuid", "title": "New chat", "created_at": "iso8601"}

GET /api/sessions/{id}/messages
  Response 200: [{"id": "uuid", "role": "user", "content": "...", "created_at": "iso8601"}]

SSE: GET /api/sessions/{id}/stream
  Events: {"type": "chunk", "data": {"content": "partial text"}}
          {"type": "done", "data": {"message_id": "uuid"}}
```

**Cross-cutting concerns assigned:**
- URL trailing slash convention → Backend agent
- Error response shape (`{"error": "message"}`) → Backend agent
- Streaming storage semantics (accumulate chunks, not per-chunk rows) → Database agent

This is just one example. Your project may have completely different boundaries — library API surfaces, CLI argument parsing contracts, document template function signatures, data pipeline stage interfaces, etc. Derive contracts from the actual project architecture.

</details>

---

## Step 6: Spawn All Agents in Parallel

With contracts defined and tasks created, spawn all agents simultaneously using the `Task` tool with `team_name` and `name` parameters. Each agent receives full context to build independently from the start.

Enter **Delegate Mode** before spawning. You should not implement code yourself — your role is coordination.

### Spawning

Spawn each agent in a single message with multiple `Task` tool calls (parallel launch):

```
Task:
  team_name: "project-build"
  name: "backend"                    # human-readable, used for messaging
  subagent_type: "fullstack-developer"  # or general-purpose, code-reviewer
  mode: "plan"                       # optional: require plan approval before implementing
  prompt: "You are the backend agent for this build. ..."
```

Use `mode: "plan"` when you want agents to present their implementation approach before coding. You approve or reject plans via `SendMessage` type `"plan_approval_response"`.

### Spawn Prompt Template

```
You are the [ROLE] agent for this build.

## Project Context
[Key info from CLAUDE.md — conventions, build commands, patterns to follow]

## Your Ownership
- You own: [directories/files]
- Do NOT touch: [other agents' files]

## What You're Building
[Relevant section from plan]

## Contracts

### Contract You Produce
[The contract this agent is responsible for delivering]
- Build to match this exactly
- If you need to deviate, message the lead using SendMessage and wait for approval

### Contract You Consume
[The contract this agent depends on]
- Build against this interface exactly — do not guess or deviate

### Cross-Cutting Concerns You Own
[Integration behaviors this agent is responsible for]

## Coordination
- Use SendMessage type "message" to the lead if you discover something that affects a contract
- Ask before deviating from any agreed contract
- Flag cross-cutting concerns that weren't anticipated
- Messages from the lead are delivered automatically — no need to poll

## Task Assignment
- Your task ID is [TASK_ID]. Mark it in_progress when you start with TaskUpdate.
- Mark it completed with TaskUpdate when all validations pass.

## Before Reporting Done
Run these validations and fix any failures:
1. [specific validation command — derived from CLAUDE.md and plan]
2. [specific validation command]
Do NOT mark your task complete until all validations pass.
```

After spawning, use `TaskUpdate` with `owner` to assign each task to the corresponding agent name.

---

## Step 7: Facilitate Collaboration

All agents work in parallel. Your job as lead:

- **Receive messages automatically** — teammate messages are delivered to you as they arrive, queued if you're mid-turn
- **Relay contract issues** — use `SendMessage` type `"message"` to the affected agent when another agent flags a contract issue
- **Broadcast critical changes** — use `SendMessage` type `"broadcast"` sparingly, only for contract changes that affect all agents
- **Mediate contract changes** — if an agent needs to deviate, evaluate the change, update the contract, and notify affected agents
- **Unblock agents** waiting on decisions
- **Track progress** — use `TaskList` to monitor task statuses and ownership

### Understanding Idle State

Teammates go idle after every turn — **this is normal**. An idle teammate:
- Has finished their current turn and is waiting for input
- Can receive messages — sending a message wakes them up
- Is NOT "done" or "broken" — idle just means waiting

Don't react to idle notifications unless you need to assign new work or follow up.

### Resuming Agents

If an agent hits an issue and needs to continue:
- Use the `Task` tool with the `resume` parameter and the agent's ID to continue with full context preserved
- Only spawn a fresh agent if the approach was fundamentally wrong

### Pre-Completion Contract Verification

Before agents mark tasks complete, run a contract diff:
- Ask each agent what exact interfaces they implemented
- Compare both sides of every contract boundary
- Flag mismatches before integration testing

### Cross-Review

Each agent reviews another agent's work at the integration boundary:
- "Does the interface you consume actually look like what was built?"
- "Can you use the other agent's output as expected?"

---

## Step 8: Validation

Validation happens at two levels: **agent-level** and **lead-level**.

### Agent Validation

Each agent validates their own domain before marking their task complete. Derive validation commands from:
1. **CLAUDE.md** — project's existing test/build/lint commands
2. **The plan** — any acceptance criteria or validation section
3. **The technology** — what would catch regressions in this layer?

Include specific validation commands in each agent's spawn prompt.

### Lead Validation (End-to-End)

After ALL agents have marked their tasks complete (check with `TaskList`), you validate the integrated system yourself:

1. **Can the system start?** — Run the project's start commands. No errors.
2. **Does the happy path work?** — Walk through the primary user flow from the plan.
3. **Do integrations connect?** — Data flows correctly across all contract boundaries.
4. **Are edge cases handled?** — Empty states, error states, loading states.

If validation fails:
- Identify which agent's domain contains the issue
- Use `SendMessage` to that agent describing the specific problem
- Resume the agent with `Task` `resume` if they're idle
- Re-run validation after the fix

---

## Step 9: Shutdown and Cleanup

Once the build is validated and complete:

1. **Shut down each agent** — use `SendMessage` type `"shutdown_request"` to each teammate
2. **Wait for responses** — agents respond with `"shutdown_response"` (approve or reject). If rejected, address the reason before retrying.
3. **Clean up team resources** — use `TeamDelete` after all teammates have shut down

---

## Common Pitfalls

1. **File conflicts** — Two agents editing the same file → assign clear ownership
2. **Lead over-implementing** — You start coding → stay in Delegate Mode
3. **Parallel spawn without contracts** — Agents diverge on interfaces → define all contracts before spawning
4. **Vague contracts** — Prose descriptions instead of concrete shapes → require exact specifications
5. **Orphaned cross-cutting concerns** — Nobody owns shared behaviors → explicitly assign each one
6. **Agents don't communicate** — Issues discovered but not relayed → require explicit handoffs via lead
7. **Missing project context** — Agents ignore existing patterns → include CLAUDE.md conventions in spawn prompts

---

## Collaboration Patterns

**Anti-pattern: Parallel spawn without contracts**
```
Lead spawns all agents without defining interfaces → each builds to own assumptions → integration fails
```

**Anti-pattern: Fully sequential spawning**
```
Lead spawns agent A → waits → spawns B → waits → spawns C → no parallelism
```

**Anti-pattern: Broadcasting everything**
```
Lead uses broadcast for every message → all agents get interrupted → use targeted SendMessage instead
```

**Good pattern: Lead-authored contracts, parallel spawn**
```
Lead reads project + plan → defines all contracts upfront → spawns all agents with contracts → parallel work → minimal integration issues
```

**Good pattern: Active mediation during parallel work**
```
Agent A: (SendMessage to lead) "I need to change the response shape"
Lead: (SendMessage to Agent B) "The interface changed. Here's the update."
Agent B: (SendMessage to lead) "Got it, adapting."
```

**Good pattern: Resume over re-spawn**
```
Agent hits an issue → Lead resumes agent with Task resume parameter → agent continues with full context preserved
```

---

## Definition of Done

The build is complete when:
1. All agents have marked their tasks complete (`TaskList` shows all completed)
2. Each agent has validated their own domain
3. Integration points have been tested
4. Cross-review feedback has been addressed
5. The plan's acceptance criteria are met
6. Lead has run end-to-end validation
7. All agents gracefully shut down via `shutdown_request`/`shutdown_response`
8. `TeamDelete` called for cleanup

---

## Execute

Now begin:

1. Read `CLAUDE.md` and `docs/index.md` (if they exist) to understand the project
2. Read the plan at `$ARGUMENTS[0]`
3. Assess whether agent teams are needed (Step 2)
4. Determine team structure (use `$ARGUMENTS[1]` if provided)
5. Define agent roles, ownership, and contracts — derived from the actual project architecture
6. Use `TeamCreate` to create the team
7. Use `TaskCreate` for each deliverable, with `addBlockedBy` for integration tasks
8. Enter Delegate Mode
9. Spawn all agents in parallel with `Task` (using `team_name`, `name`, `subagent_type`) with contracts and validation checklists
10. Assign tasks to agents with `TaskUpdate` `owner`
11. Monitor via `TaskList`, relay messages with `SendMessage`, mediate contract changes
12. Run contract diff before integration
13. When all tasks show completed, run end-to-end validation
14. If validation fails, `SendMessage` to the relevant agent and `resume` them
15. Shut down agents with `shutdown_request`, then `TeamDelete`
16. Confirm the build meets the plan's requirements
