# 01 — Architectural Overview

## Component Responsibilities

```
┌─────────────────┬─────────────┬────────────────────────────────────────┬─────────────────────────┐
│ Arch. Layer     │ Component   │ Responsibility                         │ Failure Mode Handling   │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Control Flow    │ LangGraph   │ Orchestrates sequence, manages loops,  │ Routes to retry/end     │
│                 │             │ branches, persistence                  │ based on edge logic     │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Data Integrity  │ Pydantic    │ Defines state structure, validates     │ Raises ValidationError  │
│                 │             │ inputs/outputs, serializes data        │ to trigger retry loop   │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Single-Agent    │ Pydantic AI │ Type-safe agent execution with DI,     │ Structured output       │
│ Execution       │             │ tool handling, structured outputs      │ validation              │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Multi-Agent     │ CrewAI      │ Role-based teams, task delegation,     │ Crew-level retry,       │
│ Collaboration   │             │ collaborative problem solving,         │ manager escalation,     │
│                 │             │ scoped memory                          │ Pydantic parse retry    │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Cognition       │ LLM         │ Generates content, reasoning traces,   │ Raw material shaped     │
│                 │             │ tool calls                             │ by Pydantic validation  │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Persistence     │ Checkpointer│ Saves graph state at every step,       │ Ensures state recovery  │
│                 │             │ enables time-travel and HITL           │ (handle serialization)  │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Memory          │ CrewAI      │ Hierarchical scoped recall, composite  │ Graceful degradation:   │
│                 │ Memory      │ scoring, auto-consolidation            │ LLM failure → defaults  │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Observability   │ Langfuse /  │ Traces, sessions, cost tracking,       │ Async export, no LLM    │
│                 │ LangSmith   │ latency monitoring                     │ cost overhead            │
└─────────────────┴─────────────┴────────────────────────────────────────┴─────────────────────────┘
```

## Integration Pattern

The integration follows the **Adapter Pattern**: LangGraph manages the workflow while Pydantic AI and CrewAI agents are wrapped as specialized nodes.

```
LangGraph Node Types:
├── Standard Nodes      → Pure functions for routing, validation, preprocessing
├── Pydantic AI Nodes   → Single-agent tasks requiring type safety
└── CrewAI Nodes        → Multi-agent collaborative tasks
```

## Observability Architecture (Layered)

When using Langfuse with both LangGraph and CrewAI, two integration paths converge:

```
┌─────────────────────────────────────────────────────────────────────┐
│  Langfuse (Observability Layer)                                     │
│  - Session = document_id → groups all rounds into one replay        │
│  - LangGraph nodes traced via CallbackHandler                       │
│  - CrewAI agent/LLM calls traced via OpenInference (OTel)           │
│  - Cost, latency, token counts rolled up per session                │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  LangGraph (Orchestration Layer)                             │    │
│  │  - Owns the iteration loop & global state                    │    │
│  │  - Routes: continue ↔ end                                    │    │
│  │  - Enables state time-travel via checkpointer                │    │
│  │                                                              │    │
│  │  ┌───────────────────────────────────────────────────────┐   │    │
│  │  │  CrewAI (Execution Layer) — instantiated PER ROUND     │   │    │
│  │  │  Unified Memory with hierarchical scopes per pipeline  │   │    │
│  │  └───────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Design Patterns (Summary)

1. **Hybrid State** — TypedDict envelope + Pydantic BaseModel payload
2. **Adapter Pattern** — Framework agents wrapped as LangGraph node functions
3. **Inflate/Deflate** — Explicit serialization boundaries at node entry/exit
4. **Validator Node Topology** — Separate generation and validation into distinct nodes
5. **Moderator Shield** — Agents never talk directly to downstream consumers; a moderator filters/harmonizes
6. **Pydantic Contracts** — Inter-agent outputs are type-safe JSON, not free text
7. **Dual Context** — Nudge injection (push, deterministic) + Scoped Memory (pull, semantic)
8. **Per-Round Crew** — No shared mutable state; fresh Crew per iteration for concurrency safety
9. **Memory Scoping** — Enforced at memory layer, not just prompt instructions
10. **Session-Grouped Tracing** — All rounds of a pipeline grouped under one observability session
