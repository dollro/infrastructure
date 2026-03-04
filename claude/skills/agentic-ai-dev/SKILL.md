---
name: agentic-ai-dev
description: >
  Engineering standard for building production-grade agentic AI systems using
  LangGraph + Pydantic AI + CrewAI. ALWAYS use this skill when: designing
  multi-agent orchestration, implementing type-safe AI agents, building
  LangGraph workflows, configuring CrewAI teams with memory, setting up
  observability (Langfuse/LangSmith), deploying agent pipelines to production
  (Celery, Docker), implementing validation loops, or designing inter-agent
  communication contracts. Also trigger when the user mentions: agent
  orchestration, agentic pipeline, multi-agent system, CrewAI crew, LangGraph
  graph, Pydantic AI agent, structured output validation, agent memory scoping,
  HITL (human-in-the-loop), or checkpoint/persistence patterns.
---

# Agentic AI Development Skill

## Overview

This skill covers the engineering standard for **production-grade agentic AI systems** fusing three frameworks:

| Framework | Role | Responsibility |
|-----------|------|----------------|
| **LangGraph** | Orchestrator | Stateful workflow control, cyclic graphs, persistence, HITL |
| **Pydantic AI** | Single-Agent Executor | Type-safe agents with dependency injection, structured outputs |
| **CrewAI** | Multi-Agent Teams | Role-based collaborative agents, scoped memory, task delegation |

### The Core Paradigm

**Deterministic harness around probabilistic engines:**

- **LangGraph** = nervous system → models cognitive architecture as a Directed Cyclic Graph
- **Pydantic** = immune system → enforces data integrity, rejects hallucinations
- **CrewAI** = team dynamics → coordinates specialized agents with clear roles and memory isolation

```
┌─────────────────────────────────────────────────────────────────┐
│                    LangGraph (Control Plane)                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Router  │───▶│ Pydantic │───▶│  CrewAI  │───▶│ Validator│  │
│  │   Node   │    │ AI Node  │    │   Node   │    │   Node   │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│        │              │               │               │         │
│        └──────────────┴───────────────┴───────────────┘         │
│                    Shared Typed State (Pydantic)                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Decision Trees

### Which Node Type?

| Task Characteristic | Recommended Node Type |
|--------------------|-----------------------|
| Simple validation/routing | Standard LangGraph function |
| Single-agent with structured output | Pydantic AI Adapter Node |
| Multi-agent collaboration | CrewAI Adapter Node |
| Human approval required | LangGraph interrupt + validation |

### Which Framework for Orchestration?

| Requirement | Use LangGraph | Use CrewAI Flows |
|------------|---------------|------------------|
| State checkpointing / crash recovery | ✅ | ❌ |
| HITL interrupts (pause/resume) | ✅ | ❌ |
| Graph composition (subgraphs) | ✅ | ❌ |
| Single-framework simplicity | ❌ | ✅ |
| Built-in flow memory (self.remember) | ❌ | ✅ |

### Which Observability Stack?

| Requirement | Langfuse | LangSmith |
|------------|----------|-----------|
| Open-source / self-hostable | ✅ | ❌ |
| EU data sovereignty (GDPR) | ✅ | ❌ |
| Native OTel (CrewAI without wrappers) | ✅ | ❌ |
| Session grouping (multi-round) | ✅ | ✅ |
| Tight LangGraph integration | ✅ (callback) | ✅ (native) |
| Cost tracking across providers | ✅ | ✅ |

---

## Resource Guide

Read the relevant resource file(s) before implementing. Each resource is self-contained.

### Core Architecture & State

| Resource | When to Read | Lines |
|----------|-------------|-------|
| `resources/01-architecture.md` | Starting a new project; understanding component roles | ~120 |
| `resources/02-state-management.md` | Defining graph state; serialization issues | ~180 |

### Framework Integration

| Resource | When to Read | Lines |
|----------|-------------|-------|
| `resources/03-langgraph-orchestration.md` | Building the graph; routing logic; compilation | ~200 |
| `resources/04-pydantic-ai-nodes.md` | Wrapping Pydantic AI agents as LangGraph nodes | ~180 |
| `resources/05-crewai-integration.md` | CrewAI agents/tasks/crews; per-round instantiation; async | ~250 |

### Advanced Patterns

| Resource | When to Read | Lines |
|----------|-------------|-------|
| `resources/06-memory-architecture.md` | Scoped memory; consolidation; dual context (nudge+memory) | ~280 |
| `resources/07-inter-agent-contracts.md` | Moderator Shield; context fencing; Pydantic contracts | ~180 |
| `resources/08-validation-loop.md` | Generator→Validator→Fixer loop; nested errors | ~200 |

### Operations & Quality

| Resource | When to Read | Lines |
|----------|-------------|-------|
| `resources/09-observability.md` | Langfuse/LangSmith setup; OTel; session tracing | ~220 |
| `resources/10-hitl-patterns.md` | Human-in-the-loop; interrupt; time travel | ~180 |
| `resources/11-testing.md` | Unit/integration/snapshot testing; TestModel | ~160 |
| `resources/12-security.md` | Input sanitization; safe serialization; allowlists | ~120 |
| `resources/13-production-deployment.md` | Celery; cost model; Docker; scaling; concurrency | ~250 |
| `resources/14-anti-patterns.md` | Common mistakes; performance optimization | ~100 |

### Quick Reference

| Resource | When to Read | Lines |
|----------|-------------|-------|
| `resources/reference-card.md` | Cheat sheet for all key patterns | ~60 |
| `resources/15-dependencies.md` | Dependency conflicts, install order, version matrix | ~200 |

---

## Project Structure

```
project/
├── pyproject.toml
├── src/
│   ├── __init__.py
│   ├── state/
│   │   ├── models.py          # Pydantic domain models
│   │   └── graph_state.py     # TypedDict graph state
│   ├── nodes/
│   │   ├── router.py          # Routing/conditional logic
│   │   ├── validators.py      # Validation nodes
│   │   ├── pydantic_ai/       # Pydantic AI adapter nodes
│   │   │   ├── research_agent.py
│   │   │   └── analyzer_agent.py
│   │   └── crewai/            # CrewAI adapter nodes
│   │       ├── agents.py      # Agent definitions (templates)
│   │       ├── tasks.py       # Task definitions
│   │       ├── crews.py       # Crew compositions + adapter
│   │       └── memory.py      # Memory factory + scoped agents
│   ├── graph/
│   │   └── workflow.py        # LangGraph definition
│   ├── observability/
│   │   └── tracing.py         # Langfuse/LangSmith setup
│   └── utils/
│       ├── serialization.py   # Inflate/deflate helpers
│       └── validation_helpers.py
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
└── main.py
```

## Dependencies

See `resources/15-dependencies.md` for the full compatibility matrix, install order, and conflict resolution guide.

### Quick Install (Recommended Order)

```bash
# Step 1: CrewAI first — pins OTel to ~=1.34.0 (strictest constraint)
pip install "crewai>=1.10.0"

# Step 2: Langfuse — accepts OTel >=1.33.1, satisfied by 1.34.x
pip install "langfuse>=3.0.0"

# Step 3: Full langchain — required for langfuse.langchain.CallbackHandler
#          Also pulls langchain-core and langgraph automatically
pip install "langchain>=1.2.0"

# Step 4: Pydantic AI — use slim variant with only needed providers
pip install "pydantic-ai-slim[openai]>=0.0.50"

# Step 5: CrewAI OTel instrumentor for Langfuse tracing
pip install "openinference-instrumentation-crewai"

# Dev dependencies
pip install "pytest>=8.0" "pytest-asyncio>=0.23" "dirty-equals>=0.8"
```

### pyproject.toml

```toml
[project]
requires-python = ">=3.11"
dependencies = [
    # Install order matters — see resources/15-dependencies.md
    "crewai>=1.10.0",               # Multi-agent teams, pins OTel ~=1.34.0
    "langfuse>=3.0.0",              # Observability (OTel-based, no langchain in core)
    "langchain>=1.2.0",             # Required for langfuse.langchain.CallbackHandler
                                    # Also pulls langchain-core + langgraph
    "pydantic-ai-slim[openai]>=0.0.50",  # Type-safe agents (slim = no unused providers)
    "pydantic>=2.5",
    "openinference-instrumentation-crewai",  # CrewAI→Langfuse OTel bridge
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23",
    "dirty-equals>=0.8",
]
```

---

*Read the relevant resource files before implementing. Start with `01-architecture.md` for new projects, `15-dependencies.md` for setting up your environment, or jump to the specific pattern you need.*
