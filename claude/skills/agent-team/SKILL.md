---
name: agent-team
description: Orchestrate Claude Code Agent Teams with contract-first design and dynamic teammate specialization. Use when the user wants multiple agents collaborating on a build, mentions "agent team", "parallel build", "swarm", or asks to split work across agents. Also trigger when a plan file mentions 3+ independent components, or when the user says "team build", "parallel agents", or "coordinate agents". This skill adds structure that Claude Code doesn't provide natively — interface contracts, dynamic skill injection, and quality gates.
---

# Agent Team Orchestration

You are the **lead agent** coordinating a parallel build. Your role is strictly coordination — you do NOT write code yourself. You design contracts, compose specialized prompts for each teammate, spawn them, and orchestrate their work.

> **What this skill adds over vanilla agent teams:** Claude Code's built-in agent teams handle spawning, messaging, task lists, and display. This skill adds three things the built-in system doesn't enforce: (1) contract-first interface design, (2) dynamic teammate specialization via skill/context injection, and (3) structured quality gates before integration.

## Quick Start

Ensure agent teams are enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json or environment). Then enter **Delegate Mode** (Shift+Tab) before spawning — this auto-approves tool use and restricts the lead to coordination only.

---

## Phase 1: Understand the Project

1. Read `CLAUDE.md` (conventions, stack, build/test commands)
2. Scan directory structure and key files
3. Read the plan file (ask for one if not provided)
4. Identify: what are we building, what are the major components, what are the dependencies between them

## Phase 2: Team or Solo?

Use a **single agent** (or subagents) if work is linear or touches few files. Use **agent teams** only when there are 2+ independent components with clear boundaries AND teammates need to coordinate. Say so if solo is sufficient — teams burn ~3-5x tokens.

| Use subagents when | Use agent teams when |
|---|---|
| Quick focused tasks that report back | Workers need to share findings and coordinate |
| Independent research/analysis | Cross-layer changes (frontend + backend + tests) |
| One-off searches | Competing hypotheses / parallel exploration |

## Phase 3: Design Contracts BEFORE Anything Else

**This is the most important phase.** Do not spawn agents until contracts are fully defined.

At every integration boundary between teammates, define:

### Interface Contract Template
```
## Contract: [boundary-name] (e.g., "API ↔ Frontend")

### Data Shapes (concrete, not prose)
// Request
{ userId: string, filters: { status: "active" | "inactive", limit: number } }

// Response  
{ users: Array<{ id: string, name: string, email: string }>, total: number }

### Endpoints / Function Signatures
GET /api/users?status=active&limit=20 → UsersResponse
POST /api/users → { id: string }

### Error Cases
- 400: { error: "INVALID_FILTER", message: string }
- 404: { error: "NOT_FOUND" }

### Assumptions
- Auth token in Authorization header (Bearer)
- Dates as ISO 8601 strings
```

**Quality check:** Could two developers build to this contract independently and integrate on the first try? If not, the contract isn't specific enough.

Rules:
- **Exact JSON shapes**, not prose descriptions
- **Concrete examples** for every data structure
- **Error/edge cases** enumerated
- **Cross-cutting concerns** (auth, logging, error handling) assigned to exactly one teammate
- Identify **shared types/interfaces** — create a contract file that both sides import

## Phase 4: Design Team & Specialize Teammates

### Sizing
- 2 agents for two independent layers
- 3 for three distinct areas
- 4+ for large systems (rare — prefer fewer, focused agents)

### Dynamic Specialization

Each teammate should receive a **task-specific prompt** composed from:

1. **Project context** — from CLAUDE.md and docs
2. **Ownership scope** — exact files/dirs they own and must NOT touch
3. **Relevant contracts** — what they produce and consume
4. **Domain expertise** — pull from project skills, CLAUDE.md conventions, or inject inline expertise relevant to their specific task

**Key insight:** Don't give every teammate the same generic prompt. A backend agent building a REST API needs different expertise than a frontend agent wiring up React components. Compose each prompt to match the task:

```
## Teammate: backend
## Domain expertise to inject:
- REST API conventions from CLAUDE.md
- Database migration patterns from docs/
- Error handling standards

## Teammate: frontend  
## Domain expertise to inject:
- Component structure conventions
- State management patterns
- Accessibility requirements
```

If the project has relevant skills installed (e.g., testing frameworks, deployment patterns), reference them in the teammate's prompt so they load the right context.

### Agent Types

Pick the right type for each role:

| Type | Tools | Best For |
|------|-------|----------|
| `general-purpose` | All | Implementation work |
| `Explore` | Read-only (haiku) | Research, codebase search |
| `Plan` | Read-only | Architecture, design review |
| `Bash` | Bash only | Git operations, build commands |

## Phase 5: Spawn

### 5a. Create Team + Tasks
```
Teammate({ operation: "spawnTeam", team_name: "project-build", description: "Building [what]" })

TaskCreate({ subject: "Implement backend API", description: "...", activeForm: "Building backend..." })
TaskCreate({ subject: "Implement frontend", description: "...", activeForm: "Building frontend..." })
TaskCreate({ subject: "Integration test", description: "...", activeForm: "Testing integration..." })
TaskUpdate({ taskId: "3", addBlockedBy: ["1", "2"] })
```

### 5b. Enter Delegate Mode
Press **Shift+Tab** before spawning teammates.

### 5c. Spawn Each Teammate with Full Context

Each spawn prompt must include:

```
Task({
  team_name: "project-build",
  name: "backend",
  subagent_type: "general-purpose",
  run_in_background: true,
  prompt: `You are the backend agent.

## Project Context
[Key conventions from CLAUDE.md — tech stack, build/test commands]

## Your Ownership
- You own: src/api/, src/db/, src/middleware/
- Do NOT touch: src/components/, src/pages/, tests/e2e/

## Contracts You PRODUCE
[Paste exact contract — the interfaces other agents consume from you]

If you need to deviate from a contract, message the lead FIRST:
Teammate({ operation: "write", target_agent_id: "team-lead", value: "Proposing change to GET /api/users: ..." })

## Contracts You CONSUME  
[Paste exact contract — what you build against]

## Cross-Cutting Concerns You Own
[e.g., error handling middleware, auth token validation]

## Domain Context
[Injected expertise relevant to THIS agent's task]

## Task
Claim: TaskUpdate({ taskId: "1", owner: "backend", status: "in_progress" })
Done: TaskUpdate({ taskId: "1", status: "completed" })

## Before Marking Done
1. Run: [build command]
2. Run: [test command]  
3. Verify contract compliance — do your exports match the agreed shapes?
Do NOT mark complete until all pass.`
})
```

## Phase 6: Orchestrate

Use built-in controls to monitor:
- **Shift+Down/Up** → cycle through teammates
- **Enter** → view selected teammate's live session
- **Ctrl+T** → toggle task list overlay
- **Escape** → back to lead

Your orchestration responsibilities:
- **Watch for contract deviations** — if a teammate messages about changing an interface, evaluate the change and relay to affected teammates
- **Mediate conflicts** — if two agents touch shared ground, resolve immediately
- **Unblock** — if a teammate is stuck, send targeted context via `Teammate({ operation: "write", ... })`
- **Prefer targeted messages over broadcasts** — broadcasts cost N messages for N teammates

## Phase 7: Contract Verification & Integration

Before declaring victory:

1. **Contract diff** — Ask each agent what interfaces they actually implemented. Compare both sides. Flag mismatches.
2. **Build check** — Does the system start?
3. **Happy path** — Does the primary use case work end-to-end?
4. **Edge cases** — Are error cases from contracts handled?

If something fails, message the relevant teammate — idle agents wake when messaged.

## Phase 8: Shutdown

```
Teammate({ operation: "requestShutdown", target_agent_id: "backend", reason: "Build complete" })
Teammate({ operation: "requestShutdown", target_agent_id: "frontend", reason: "Build complete" })
// Wait for approvals
Teammate({ operation: "cleanup" })
```

---

## Optional: Quality Gate Hooks

For recurring projects, set up hooks in `.claude/settings.json` to enforce quality automatically:

```json
{
  "hooks": {
    "TaskCompleted": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "scripts/verify-contracts.sh $TASK_ID"
      }]
    }],
    "TeammateIdle": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "scripts/check-idle-reason.sh $AGENT_NAME"
      }]
    }]
  }
}
```

- **TaskCompleted** — exit code 2 prevents completion and sends feedback (e.g., "tests not passing")
- **TeammateIdle** — exit code 2 sends feedback to keep teammate working (e.g., "review your contract compliance before going idle")

---

## Common Pitfalls

1. **Spawning without contracts** — the #1 cause of integration failures. Define ALL contracts first.
2. **Vague contracts** — if it's prose instead of JSON shapes, it's not specific enough.
3. **Generic teammate prompts** — specialize each prompt to the agent's actual task and domain.
4. **Lead coding instead of coordinating** — use Delegate Mode (Shift+Tab) to prevent this.
5. **Orphaned cross-cutting concerns** — auth, logging, error handling must each be assigned to exactly one agent.
6. **Broadcasting everything** — use targeted `write` messages; broadcasts cost N messages.
7. **Too many agents** — start with 2-3. More agents = more coordination overhead + token cost.

---

## Orchestration Patterns

**Parallel Specialists** (most common) — Contracts first → spawn all → parallel build → integration test.

**Pipeline** — Sequential tasks via `addBlockedBy`. Each stage needs the previous output.

**Research → Implement** — Use synchronous `Explore` subagent for research first, then feed findings into teammate spawn prompts.

**Review Swarm** — Multiple reviewers (security, performance, architecture) examine the same code in parallel and report findings to lead for synthesis.
