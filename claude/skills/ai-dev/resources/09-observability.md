# 09 — Observability

## Three Integration Mechanisms

All three frameworks bridge to OpenTelemetry differently. Understanding this is critical for debugging trace gaps.

| Framework | Mechanism | How spans reach your backend |
|-|-|-|
| Pydantic AI | `Agent.instrument_all()` | OTel auto-instruments all `.run()` / `.run_sync()` calls. No per-agent wiring needed. |
| CrewAI | `CrewAIInstrumentor().instrument()` | OpenInference wraps CrewAI's LLM calls → emits OTel spans → your exporter picks them up. |
| LangGraph | `CallbackHandler` | Langfuse/LangSmith LangChain callback passed to `graph.invoke(config={"callbacks": [h]})`. |

### Idempotent Initialization

Call `init_tracing()` once at pipeline entry point. The `@lru_cache` ensures it's safe to call repeatedly.

```python
# src/observability/tracing.py
import logging
from functools import lru_cache

from pydantic_ai import Agent
from openinference.instrumentation.crewai import CrewAIInstrumentor

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def init_tracing() -> bool:
    """Idempotent tracing setup. Call once at pipeline entry point.

    Returns True if tracing was enabled, False if credentials are missing.
    """
    from django.conf import settings  # Or your config system

    if not settings.LANGFUSE_PUBLIC_KEY or not settings.LANGFUSE_SECRET_KEY:
        logger.info("Tracing credentials not set — tracing disabled")
        return False

    # Backend setup: Langfuse v3+ auto-registers OTel exporter
    from langfuse import get_client
    get_client()

    # Framework instrumentation (always do both)
    Agent.instrument_all()                                # Pydantic AI → OTel spans
    CrewAIInstrumentor().instrument(skip_dep_check=True)  # CrewAI → OTel spans

    logger.info("Tracing initialized (Pydantic AI + CrewAI)")
    return True
```

### LangGraph Callback Handler

LangGraph uses LangChain's callback system, not OTel directly. Create a handler per pipeline invocation (not shared across threads).

**DEPENDENCY NOTE**: `from langfuse.langchain import CallbackHandler` requires the **full `langchain` package** — not just `langchain-core`. The module does `import langchain` at load time to version-check. See `resources/15-dependencies.md` for details.

```python
def get_tracing_callback():
    """Return a CallbackHandler for LangGraph, or None if disabled.

    CRITICAL: Must be called INSIDE a propagate_attributes() context
    so the handler inherits session_id automatically.
    """
    from django.conf import settings

    if not settings.LANGFUSE_PUBLIC_KEY or not settings.LANGFUSE_SECRET_KEY:
        return None

    from langfuse.langchain import CallbackHandler
    return CallbackHandler()
```

### Session Glue: `propagate_attributes`

The key mechanism that ties both paths together. Every span emitted inside the context manager — whether from CrewAI's OTel or LangGraph's callbacks — inherits the same `session_id`.

```python
from langfuse import get_client, propagate_attributes

langfuse = get_client()  # Singleton, reads from env vars

with langfuse.start_as_current_observation(
    as_type="span",
    name="document-refinement-pipeline",
):
    with propagate_attributes(
        session_id=document_id,
        tags=["pipeline", "document-refinement"],
    ):
        config = {
            "configurable": {"thread_id": document_id},
            "callbacks": [langfuse_handler],
        }
        final_state = app.invoke(initial_state, config=config)

# CRITICAL for short-lived scripts — flush pending spans
langfuse.flush()
```

## Langfuse v4 Breaking Changes (v4.0+)

### `update_trace()` removed from spans

In Langfuse v3, you could call `span.update_trace(name=, input=, output=)` to set trace-level metadata from a span. **This method was removed in v4.**

**v3 (broken in v4):**
```python
root_span.update(name=trace_name)
root_span.update_trace(name=trace_name, input={...}, output={...})
```

**v4 migration:**
```python
root_span.update(name=trace_name, input={...}, output={...})
```

- `root_span.update()` sets I/O on the root span — functionally equivalent in the Langfuse UI
- For trace-level name: use `propagate_attributes(trace_name=...)` context manager
- `set_trace_io(input=, output=)` exists but is deprecated and will be removed

### Available span methods in v4
- `update(name=, input=, output=, metadata=, ...)` — update the span
- `propagate_attributes(trace_name=, session_id=, tags=, ...)` — set trace-level attributes
- `set_trace_io(input=, output=)` — deprecated, use `update()` on root span instead

## Trace Hierarchy (What You See in Langfuse Dashboard)

```
Session: {document_id}
└─ document-refinement-pipeline          (manual span — top-level)
   ├─ LangGraph: refine_document         (CallbackHandler — node)
   │  ├─ refinement-round-1              (manual span — per round)
   │  │  └─ crewai.crew_kickoff          (OTel auto-captured)
   │  │     ├─ crewai.agent_execute_task  (Expert A + LLM calls)
   │  │     ├─ crewai.agent_execute_task  (Expert B + LLM calls)
   │  │     ├─ crewai.agent_execute_task  (Expert C + LLM calls)
   │  │     ├─ crewai.agent_execute_task  (Moderator + LLM calls)
   │  │     └─ crewai.agent_execute_task  (Writer + LLM calls)
   │  ├─ LangGraph: should_continue      (routing decision)
   │  ├─ refinement-round-2
   │  │  └─ ...
   │  └─ LangGraph: should_continue → END
```

## Per-Round Tracing

Wrap each iteration round in a span to get clean nesting. Use `start_as_current_span` (v4 preferred API — `start_as_current_observation` still works but `start_as_current_span` is the v4 way):

```python
def run_crewai_refinement_round(state: DocumentRefinementState) -> dict:
    current_iter = state["iteration_count"] + 1
    langfuse = get_client()

    # Read tracing context from LangGraph state (passed from orchestrator)
    session_id = state.get("langfuse_session_id", "")
    tags = state.get("langfuse_tags", [])

    # ... build crew ...

    with langfuse.start_as_current_span(
        name=f"refinement-round-{current_iter}",
    ):
        with propagate_attributes(
            session_id=session_id,
            tags=tags + [f"round-{current_iter}"],
        ):
            result = crew.kickoff()

    return {... state update ...}
```

Without the manual span, CrewAI's OTel spans would still be captured, but they'd be top-level traces disconnected from the LangGraph flow.

### Passing Tracing Context Through LangGraph State

The orchestrator creates the root span and sets `session_id` via `propagate_attributes`. But subgraph nodes (e.g. refinement rounds) need access to these values to re-establish context for their own spans. **Thread the tracing context explicitly through the graph state:**

```python
# In your TypedDict state:
class RefinementState(TypedDict, total=False):
    langfuse_session_id: str
    langfuse_tags: list[str]
    # ... other fields ...

# Orchestrator passes them in:
graph.invoke({
    "langfuse_session_id": session_id or "",
    "langfuse_tags": [mode, f"request-{request_id}"],
    # ...
})
```

This is necessary because `propagate_attributes` sets OTel context on the **current thread's `contextvars`**, and subgraph nodes may execute in different contexts.

### `async_execution` Breaks Tracing (CRITICAL)

CrewAI's `async_execution=True` runs tasks in `ThreadPoolExecutor` threads that **don't inherit OTel context**. This causes expert task spans to appear as orphan traces with `sessionId: null`. See `05-crewai-integration.md` for details and the fix (`async_execution=False`).

## Environment Variables

```bash
LANGFUSE_PUBLIC_KEY="pk-lf-..."
LANGFUSE_SECRET_KEY="sk-lf-..."
LANGFUSE_BASE_URL="https://cloud.langfuse.com"     # EU region
# LANGFUSE_BASE_URL="https://us.cloud.langfuse.com"  # US region
```

## Cost Overhead

Langfuse tracing adds **zero LLM cost** — it's metadata collection, not extra inference. The overhead is async network I/O shipping spans. For a 3-round pipeline: ~30-50 spans, ~few KB.

## Alternative: LangSmith

LangSmith can coexist with Langfuse. For LangSmith-only setups:

```python
from langsmith.integrations.otel import configure as configure_langsmith
from pydantic_ai import Agent

def setup_unified_tracing(langsmith_project: str = "production"):
    """Configure LangSmith for both LangGraph and Pydantic AI."""
    configure_langsmith(project_name=langsmith_project)
    Agent.instrument_all()  # Pydantic AI uses the same tracer
```

## Semantic Metrics

Track key performance indicators for production monitoring:

```python
from dataclasses import dataclass

@dataclass
class AgentMetrics:
    validation_attempts: int = 0
    validation_failures: int = 0
    total_retries: int = 0
    avg_node_latency_ms: float = 0.0
    total_execution_time_ms: float = 0.0

    @property
    def validation_failure_rate(self) -> float:
        """Alert if > 0.3 → model drift warning."""
        if self.validation_attempts == 0:
            return 0.0
        return self.validation_failures / self.validation_attempts

    @property
    def avg_retry_depth(self) -> float:
        """Alert if > 1.5 → cost efficiency degradation."""
        if self.validation_attempts == 0:
            return 0.0
        return self.total_retries / self.validation_attempts
```

## Langfuse vs LangSmith Decision Guide

| Aspect | Langfuse | LangSmith |
|--------|----------|-----------|
| Self-hostable | ✅ Yes | ❌ SaaS only |
| EU data sovereignty | ✅ EU/self-host | ⚠️ US-based |
| CrewAI native (OTel) | ✅ Zero-config | ⚠️ Needs wrappers |
| Session grouping | ✅ `propagate_attributes` | ✅ Native |
| LangGraph native | ✅ CallbackHandler | ✅ Native (deeper) |
| Cost tracking | ✅ Multi-provider | ✅ Multi-provider |
| Open source | ✅ AGPL | ❌ Proprietary |
| Pricing | Free tier + OSS self-host | Free tier + paid |

**Recommendation**: Use Langfuse for GDPR-sensitive or self-hosted deployments. Use LangSmith for tight LangGraph integration. Both can coexist.
