# 03 — LangGraph Orchestration Layer

## Graph Definition

```python
# src/graph/workflow.py
from typing import Literal
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer


def create_workflow() -> StateGraph:
    """Creates the LangGraph workflow with all nodes and edges.

    Graph Topology:

    [Entry] ──► [Router] ──┬──► [PydanticAI Research] ──► [Validator] ──┬──► [Router]
                            │                                            │
                            ├──► [PydanticAI Analyzer] ──► [Validator] ──┤
                            │                                            │
                            ├──► [CrewAI Content Team] ──► [Validator] ──┤
                            │                                            │
                            ├──► [Human Approval] ─────────────────────►─┤
                            │                                            │
                            └──► [END]                    [Fixer] ◄──────┘
                                                               │
                                                               ▼
                                                      (loops back to source)
    """
    workflow = StateGraph(PipelineState)

    # Add nodes
    workflow.add_node("router", router_node)
    workflow.add_node("research", pydantic_ai_research_node)
    workflow.add_node("analyzer", pydantic_ai_analyzer_node)
    workflow.add_node("content_crew", crewai_content_crew_node)
    workflow.add_node("validator", validator_node)
    workflow.add_node("fixer", fixer_node)
    workflow.add_node("human_approval", human_approval_node)

    workflow.set_entry_point("router")

    # Conditional routing from router
    workflow.add_conditional_edges(
        "router", route_after_router,
        {"research": "research", "analyze": "analyzer",
         "crew_task": "content_crew", "human_review": "human_approval", "end": END}
    )

    # Agent nodes → validator
    workflow.add_edge("research", "validator")
    workflow.add_edge("analyzer", "validator")
    workflow.add_edge("content_crew", "validator")

    # Validator → router (success) or fixer (retry) or END (fatal)
    workflow.add_conditional_edges(
        "validator", route_after_validation,
        {"success": "router", "retry": "fixer", "fatal": END}
    )

    # Fixer loops back to appropriate agent
    workflow.add_conditional_edges(
        "fixer", route_after_fixer,
        {"research": "research", "analyze": "analyzer", "crew_task": "content_crew"}
    )

    workflow.add_edge("human_approval", "router")
    return workflow
```

## Simpler Iterative Loop Pattern

For pipelines that iterate a single action (e.g., multi-round document refinement), a single-node loop is simpler:

```python
def build_graph(checkpointer=None) -> StateGraph:
    """Single-node iterative loop with conditional exit.

    [Entry] ──► [refine_document] ──► should_continue?
                       ▲                    │
                       │   "continue"       │ "end"
                       └────────────────────┘──────► [END]
    """
    workflow = StateGraph(DocumentRefinementState)
    workflow.add_node("refine_document", run_refinement_round)
    workflow.set_entry_point("refine_document")
    workflow.add_conditional_edges(
        "refine_document", should_continue,
        {"continue": "refine_document", "end": END},
    )
    return workflow.compile(checkpointer=checkpointer)
```

## Routing Functions

```python
def route_after_router(state: PipelineState) -> str:
    """Determines next node based on state."""
    return state.get("next_action", "end")


def route_after_validation(state: PipelineState) -> Literal["success", "retry", "fatal"]:
    """Routes based on validation results."""
    if state.get("last_error") is None:
        return "success"
    if state.get("retry_count", 0) >= state.get("max_retries", 3):
        return "fatal"
    return "retry"


def route_after_fixer(state: PipelineState) -> str:
    """Routes fixer output back to the appropriate agent."""
    return state.get("current_step", "research")
```

### Routing Extension Points

Beyond simple max-iteration gates, consider:

- **Quality-based**: scoring agent rates draft 1-10, stop at threshold
- **Delta-based**: embedding similarity between consecutive drafts
- **Memory-based**: check if moderator's latest ruling has no new issues
- **Token budget**: track cumulative usage, stop when exhausted
- **Human-in-the-loop**: LangGraph interrupt_before/interrupt_after

```python
def should_continue(state: DocumentRefinementState) -> str:
    """Simple max-iteration gate. Extend with quality/delta checks."""
    if state["iteration_count"] >= state["max_iterations"]:
        return "end"
    return "continue"
```

## Router Node with Type-Safe Decisions

```python
from pydantic import BaseModel
from langchain_openai import ChatOpenAI


class RouterDecision(BaseModel):
    """Type-safe routing decision. Literal constrains to valid node names."""
    next_action: Literal["research", "analyze", "crew_task", "human_review", "end"]
    reasoning: str
    requires_human_approval: bool = False


def router_node(state: PipelineState) -> dict:
    """Analyzes state and determines next action.

    Uses heuristics first (fast, deterministic), falls back to LLM
    for ambiguous cases. LLM output is constrained to valid node names.
    """
    messages = state.get("messages", [])
    artifacts = state.get("artifacts", [])
    task_results = state.get("task_results", [])

    # Heuristic routing (fast, no LLM cost)
    if len(artifacts) >= 3 and not any(r.get("status") == "completed" for r in task_results):
        decision = RouterDecision(next_action="analyze", reasoning="Research complete, need analysis")
    elif task_results and all(r.get("status") == "completed" for r in task_results):
        decision = RouterDecision(next_action="end", reasoning="All tasks completed")
    else:
        # LLM-based routing for ambiguous cases
        llm = ChatOpenAI(model="gpt-4o", temperature=0)
        decision = llm.with_structured_output(RouterDecision).invoke([...])

    return {
        "next_action": decision.next_action,
        "requires_human_approval": decision.requires_human_approval,
        "current_step": "router",
    }
```

## Graph Compilation

```python
def compile_graph(use_persistence: bool = True):
    """Compile with optional persistence.
    SECURITY: Always disable pickle fallback in production.
    """
    workflow = create_workflow()
    if use_persistence:
        strict_serializer = JsonPlusSerializer(pickle_fallback=False)
        checkpointer = InMemorySaver(serde=strict_serializer)
        return workflow.compile(checkpointer=checkpointer)
    return workflow.compile()
```

### Checkpointer Selection Guide

| Environment | Checkpointer | Notes |
|------------|-------------|-------|
| Local dev | `MemorySaver()` | In-memory, lost on restart |
| Production | `PostgresSaver(conn)` | Durable, multi-worker |
| Production alt | `RedisSaver(conn)` | Durable, fast |
| Celery (stateless) | `None` | No time-travel, simplest |

**IMPORTANT**: With a checkpointer, you MUST pass `thread_id` in config:
```python
config = {"configurable": {"thread_id": "doc-123"}}
app.invoke(state, config=config)
```
