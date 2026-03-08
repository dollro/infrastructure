---
name: ai-dev
description: >
  Production-grade agentic AI patterns using LangGraph + Pydantic AI + CrewAI. ALWAYS use
  when building, designing, or debugging: multi-agent systems, LangGraph workflows, Pydantic AI
  agents, CrewAI teams, agent orchestration, graph-based pipelines, wrapping agents as LangGraph
  nodes, validation loops, human-in-the-loop patterns, Langfuse/OTel observability, typed state
  with Pydantic in LangGraph, serialization/persistence, inter-agent contracts, testing agentic
  systems, or resolving CrewAI/Langfuse/LangChain/OTel dependency conflicts. Keywords: LangGraph,
  Pydantic AI, CrewAI, multi-agent, orchestration, state graph, adapter pattern, HITL,
  checkpointer, subgraph, Langfuse, OTel, structured output, dependency injection, crew kickoff.
---

# Agentic AI Development Skill

## Architecture at a Glance

| Framework      | Role                  | Responsibility                                            |
|----------------|-----------------------|-----------------------------------------------------------|
| **LangGraph**  | Orchestrator          | Stateful workflow control, cyclic graphs, persistence, HITL |
| **Pydantic AI**| Single-Agent Executor | Type-safe agents with dependency injection, structured outputs |
| **CrewAI**     | Multi-Agent Teams     | Role-based collaborative agents, scoped memory, delegation |

```
┌─────────────────────────────────────────────────────────────────┐
│                    LangGraph (Control Plane)                    │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Router  │───▶│ Pydantic │───▶│  CrewAI  │───▶│ Validator│  │
│  │   Node   │    │ AI Node  │    │   Node   │    │   Node   │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│        │              │               │               │         │
│        └──────────────┴───────────────┴───────────────┘         │
│                    Shared Typed State (Pydantic)                │
└─────────────────────────────────────────────────────────────────┘
```

**Core paradigm**: Deterministic harness (LangGraph + Pydantic) around probabilistic engines (LLMs). LangGraph is the "nervous system" (workflow control), Pydantic the "immune system" (data integrity), CrewAI the "team dynamics" (multi-agent collaboration).

> **For full architectural details** → read `resources/01-architecture.md`

---

## Node Selection Decision Framework

| Task Characteristic                | Recommended Node Type        |
|------------------------------------|------------------------------|
| Simple validation / routing        | Standard LangGraph function  |
| Single-agent with structured output| Pydantic AI Adapter Node     |
| Multi-agent collaboration          | CrewAI Adapter Node          |
| Human approval required            | LangGraph interrupt + validation |
| Iterative refinement subflow       | LangGraph Subgraph           |

---

## Resource Guide — When to Read What

Read resources on-demand based on what you're building. **Do not read all files upfront.**

| Resource File | Read when... |
|---|---|
| `resources/01-architecture.md` | Understanding component responsibilities, failure modes |
| `resources/02-state-management.md` | Defining graph state, TypedDict vs Pydantic hybrid pattern |
| `resources/03-langgraph-orchestration.md` | Building graph topology, routing, conditional edges |
| `resources/04-pydantic-ai-nodes.md` | Wrapping Pydantic AI agents as LangGraph nodes |
| `resources/05-crewai-integration.md` | Building CrewAI teams, agent templates, crew-as-node |
| `resources/06-memory-architecture.md` | CrewAI scoped memory, dual context strategy |
| `resources/07-inter-agent-contracts.md` | Pydantic contracts between agents, moderator shield |
| `resources/08-validation-loop.md` | Generator → Validator → Fixer cycle |
| `resources/09-observability.md` | Langfuse, OTel, tracing setup, session grouping |
| `resources/10-hitl-patterns.md` | Human-in-the-loop with `interrupt()` |
| `resources/11-testing.md` | TestModel, InMemorySaver, dirty_equals |
| `resources/12-security.md` | Pickle-free serialization, input sanitization |
| `resources/13-production-deployment.md` | Docker, deployment, complete reference implementation |
| `resources/14-anti-patterns.md` | Common mistakes and their fixes |
| `resources/15-dependencies.md` | Version pins, install order, OTel conflicts |
| `resources/reference-card.md` | Quick-reference cheat sheet for all patterns |

---

## Critical Patterns Summary

These are the patterns you'll use most often. Each section gives the essential rule; detailed code is in the resource files.

### 1. Hybrid State: TypedDict Envelope + Pydantic Payload

```python
from typing import Annotated
from typing_extensions import TypedDict
import operator
from pydantic import BaseModel, Field

# Domain model (validated)
class ResearchOutput(BaseModel):
    summary: str = Field(..., min_length=50)
    confidence: float = Field(ge=0.0, le=1.0)

# Graph state (TypedDict envelope, total=False)
class PipelineState(TypedDict, total=False):
    mode: str
    input_data: str | None
    sections: list[dict]                          # Pydantic models serialized as dicts
    cumulative_tokens: Annotated[int, operator.add]  # Reducer for parallel branches
```

**Rules**:
- `total=False` — nodes return only fields they touch
- Pydantic `BaseModel` for domain objects; `TypedDict` for graph envelope
- `Annotated` with reducer for fields written by parallel branches
- Always `model_dump(mode='json')` when storing Pydantic models in state
- Task pipelines: pure domain fields, NO LangChain messages
- Conversational flows only: add `messages: Annotated[list[BaseMessage], operator.add]`

> **Full details** → `resources/02-state-management.md`

### 2. Pydantic AI Adapter Node

```python
from pydantic_ai import Agent, RunContext
from dataclasses import dataclass

@dataclass
class ResearchDeps:
    context: str
    max_tokens: int = 2000

research_agent = Agent(
    output_type=ResearchOutput,  # No model= here! Injected at runtime.
    instructions="You are a research analyst...",
    deps_type=ResearchDeps,
)

# LangGraph adapter — bridges Pydantic AI into graph
async def research_node(state: PipelineState) -> dict:
    deps = ResearchDeps(context=state.get("input_data", ""))
    result = await research_agent.run(
        user_prompt=state["query"],
        model=get_model("workhorse"),  # Model factory injection
        deps=deps,
    )
    return {"research": result.output.model_dump(mode="json")}
```

**Rules**:
- Never hardcode model in `Agent()`; inject via `model=get_model("tier")` at `.run()` time
- Use `deps_type` dataclass for dependency injection (testability)
- Adapter node: LangGraph state in → agent.run() → state dict out

> **Full details** → `resources/04-pydantic-ai-nodes.md`

### 3. CrewAI as LangGraph Node

```python
from dataclasses import dataclass
from crewai import Agent, Task, Crew, Process

@dataclass(frozen=True)
class AgentTemplate:
    role: str; goal: str; backstory: str

def _clone_agent(template: AgentTemplate, llm) -> Agent:
    return Agent(role=template.role, goal=template.goal,
                 backstory=template.backstory, llm=llm)

# LangGraph adapter for CrewAI
async def crew_node(state: PipelineState) -> dict:
    agents = [_clone_agent(t, get_crewai_llm("brain")) for t in TEMPLATES]
    tasks = [Task(description=..., agent=a, expected_output=...) for a in agents]
    crew = Crew(agents=agents, tasks=tasks, process=Process.sequential)
    result = crew.kickoff()  # Fresh crew every time!
    return {"crew_output": result.pydantic.model_dump(mode="json")}
```

**Rules**:
- **Never reuse** `Crew` or `Agent` objects across rounds — they mutate on `kickoff()`
- Frozen dataclass `AgentTemplate` → `_clone_agent()` per round
- `output_pydantic=` on Task enforces structured output
- Fresh crew instantiation per invocation

> **Full details** → `resources/05-crewai-integration.md`

### 4. Model Factory (Never Hardcode Models)

```python
MODEL_TIERS = {
    "brain": "anthropic/claude-opus-4-6",
    "workhorse": "anthropic/claude-sonnet-4-6",
    "bolt": "anthropic/claude-haiku-4-5-20251001",
}

def get_model(role: str = "workhorse") -> OpenAIChatModel:
    model_name = MODEL_TIERS.get(role, MODEL_TIERS["workhorse"])
    return OpenAIChatModel(model_name, provider=_get_provider())

def get_crewai_llm(role: str = "brain") -> LLM:
    return LLM(model=f"openai/{MODEL_TIERS[role]}", api_key=..., base_url=...)
```

### 5. Validation Loop Topology

```
Generator Node → Validator Node → Router
                                    ├─ success → next phase
                                    ├─ retry   → Fixer Node → Generator (loop)
                                    └─ fatal   → END
```

- Separate generation from validation (never validate inside generator)
- Always set `max_retries` in state to prevent infinite loops
- Soft (prompt) + Hard (Pydantic code) enforcement — never rely on prompts alone

> **Full details** → `resources/08-validation-loop.md`

### 6. Observability (Langfuse + OTel)

Three tracing mechanisms, initialized once at startup:

| Framework   | Mechanism                              |
|-------------|----------------------------------------|
| Pydantic AI | `Agent.instrument_all()` → OTel auto   |
| CrewAI      | `CrewAIInstrumentor().instrument()` → OpenInference → OTel |
| LangGraph   | `CallbackHandler` passed in `config={"callbacks": [h]}` |

**Critical**: Create `CallbackHandler` INSIDE `propagate_attributes(session_id=...)` context to ensure session grouping.

> **Full details** → `resources/09-observability.md`

### 7. Serialization & Security

```python
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer
strict_serializer = JsonPlusSerializer(pickle_fallback=False)  # ALWAYS
```

- Always `model_dump(mode='json')` — never store raw Pydantic objects in state
- `model_validate()` to inflate back
- Never use pickle; disable fallback explicitly

> **Full details** → `resources/12-security.md`

---

## Project Structure

```
project/
├── pyproject.toml
├── pipeline/
│   ├── orchestrator.py        # Entry point — run_pipeline()
│   ├── graph.py               # LangGraph StateGraph builder + node adapters
│   ├── state.py               # TypedDict graph state
│   ├── schemas.py             # Pydantic output models
│   ├── models.py              # LLM factory (get_model, get_crewai_llm)
│   ├── research.py            # Pydantic AI research agents + adapters
│   ├── tracing.py             # Langfuse/OTel init
│   ├── handlers/              # Domain I/O adapters (extract/apply)
│   │   ├── base.py            # BaseHandler ABC
│   │   └── pdf.py             # Format-specific handler
│   ├── interview/             # Multi-agent refinement subpackage
│   │   ├── schemas.py         # Inter-agent Pydantic contracts
│   │   ├── prompts.py         # Prompt builders
│   │   ├── crews.py           # CrewAI crew builders + agent templates
│   │   ├── memory.py          # CrewAI scoped memory factory
│   │   └── loop.py            # LangGraph refinement subgraph
│   └── prompts/
│       └── research.py        # System prompts
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
└── main.py
```

Organize by **pipeline phase**, not by framework.

---

## Dependencies (Critical Install Order)

CrewAI pins `opentelemetry-api~=1.34.0`. If Langfuse installs first, pip resolves OTel to 1.39.x, breaking CrewAI. Use a lockfile or install in order:

```bash
pip install crewai        # Pins OTel ~=1.34.0
pip install langfuse      # Accepts >=1.33.1, uses 1.34.x
pip install langchain     # Full package (not langchain-core!)
pip install "pydantic-ai-slim[openrouter]"  # or: pip install pydantic-ai (all providers)
pip install openinference-instrumentation-crewai
```

| Component | Min Version | Notes |
|---|---|---|
| Python | 3.11 | 3.10 has Langfuse+LangGraph issues |
| LangGraph | 1.0.0 | 1.0 API stability |
| Pydantic | 2.5 | v2 required for `model_dump(mode='json')` |
| Pydantic AI | 1.0.0 | `pydantic-ai-slim[openrouter]` for lean install, or `pydantic-ai` for all providers |
| CrewAI | 1.10.0 | 1.10+ for Unified Memory API |
| langchain | 1.2.0 | Full package for Langfuse CallbackHandler |
| Langfuse | 3.0.0 | v3 = OTel rewrite |

> **Full dependency details** → `resources/15-dependencies.md`

---

## Top Anti-Patterns (Quick Reference)

| Anti-Pattern | Fix |
|---|---|
| Hardcoding model in `Agent(...)` | Model factory; inject at `.run()` |
| `TypedDict` for complex values | Pydantic `BaseModel` for domain objects |
| Storing `Exception` in state | Store `ErrorSnapshot` Pydantic model |
| Validating inside generator node | Separate Validator Node topology |
| Trusting LLM structured output | Always validate client-side with Pydantic |
| Forgetting `mode='json'` in `model_dump()` | Always `model_dump(mode='json')` |
| Reusing `Crew`/`Agent` across rounds | Fresh instantiation per round |
| `langchain-core` alone for Langfuse | Install full `langchain>=1.2` |
| Installing Langfuse before CrewAI | Install CrewAI first (OTel pin) |
| Prompt-only constraint enforcement | Soft (prompt) + Hard (code) |

> **Full list** → `resources/14-anti-patterns.md`

---

## Quick Reference Card

```
STATE:       TypedDict(total=False) envelope + Pydantic BaseModel payload
SERIALIZE:   model.model_dump(mode='json')  |  ModelClass.model_validate(data)
SECURITY:    JsonPlusSerializer(pickle_fallback=False)
MODEL:       Agent defined WITHOUT model → model passed at .run(model=get_model("tier"))

NODE TYPES:
  Standard:    def node(state) -> dict
  Pydantic AI: agent.run(model=...) wrapped in adapter
  CrewAI:      Fresh Crew per round → crew.kickoff() → result.pydantic
  Subgraph:    Compiled StateGraph invoked inside parent node

CREWAI:      AgentTemplate (frozen) → _clone_agent() per round
VALIDATION:  Generator → Validator → Router → Fixer (if error) → back
HITL:        interrupt(payload) + while True validation loop
TESTING:     TestModel (unit) | InMemorySaver (integration) | dirty_equals (snapshot)

TRACING:
  Pydantic AI → Agent.instrument_all()
  CrewAI      → CrewAIInstrumentor().instrument()
  LangGraph   → CallbackHandler in config={"callbacks": [h]}
  Session     → propagate_attributes(session_id=...) groups spans
  CRITICAL    → Create CallbackHandler INSIDE propagate_attributes context
```
