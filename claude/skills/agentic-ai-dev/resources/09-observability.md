# 09 — Observability

## Two Integration Paths (Both Needed for LangGraph + CrewAI)

### Path 1: CrewAI → Langfuse via OpenInference (OTel-Based)

Auto-instruments `crew.kickoff()`, agent tasks, and LLM calls. Zero code changes inside agent/task definitions. Must call `.instrument()` BEFORE any Crew is instantiated.

```python
from openinference.instrumentation.crewai import CrewAIInstrumentor

# One-time global instrumentation — safe to call once at module load
# skip_dep_check=True: avoids version check failures with newer CrewAI releases
CrewAIInstrumentor().instrument(skip_dep_check=True)
```

### Path 2: LangGraph → Langfuse via LangChain CallbackHandler

Captures graph node entry/exit, routing decisions, state transitions. Created fresh per pipeline invocation (not shared across threads).

**DEPENDENCY NOTE**: `from langfuse.langchain import CallbackHandler` requires the **full `langchain` package** — not just `langchain-core`. The module does `import langchain` at load time to version-check. See `resources/15-dependencies.md` for details.

```python
from langfuse.langchain import CallbackHandler as LangfuseCallbackHandler

langfuse_handler = LangfuseCallbackHandler()
config = {
    "configurable": {"thread_id": document_id},
    "callbacks": [langfuse_handler],
}
final_state = app.invoke(initial_state, config=config)
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

Wrap each iteration round in a span to get clean nesting:

```python
def run_crewai_refinement_round(state: DocumentRefinementState) -> dict:
    current_iter = state["iteration_count"] + 1
    document_id = state["document_id"]

    with langfuse.start_as_current_observation(
        as_type="span",
        name=f"refinement-round-{current_iter}",
    ):
        with propagate_attributes(
            session_id=document_id,
            tags=["pipeline", f"round-{current_iter}"],
        ):
            # ... create memory, agents, tasks, run crew
            result = crew.kickoff()

    return {... state update ...}
```

Without the manual span, CrewAI's OTel spans would still be captured, but they'd be top-level traces disconnected from the LangGraph flow.

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
