# 13 — Production Deployment

## Celery Integration

```python
from celery import Celery
from celery.exceptions import SoftTimeLimitExceeded
from langfuse import get_client, propagate_attributes
from langfuse.langchain import CallbackHandler as LangfuseCallbackHandler

celery_app = Celery("refinement", broker="redis://localhost:6379/0")
langfuse = get_client()  # Singleton, safe to share across tasks

@celery_app.task(
    bind=True,
    max_retries=2,
    acks_late=True,           # Re-queue if worker dies mid-execution
    time_limit=600,           # Hard kill after 10 min
    soft_time_limit=540,      # Raise SoftTimeLimitExceeded at 9 min
    rate_limit="5/m",         # Max 5 pipeline starts per minute
)
def refine_document_task(self, draft, document_id=None, max_iterations=2):
    if document_id is None:
        document_id = uuid.uuid4().hex[:12]
    try:
        state = {
            "current_draft": draft,
            "latest_rationale": "Initial draft. No prior reviews.",
            "iteration_count": 0,
            "max_iterations": max_iterations,
            "document_id": document_id,
        }

        # Langfuse: CallbackHandler per-task (not shared across workers)
        langfuse_handler = LangfuseCallbackHandler()

        with langfuse.start_as_current_observation(
            as_type="span", name="celery-document-refinement",
        ):
            with propagate_attributes(session_id=document_id):
                config = {
                    "configurable": {"thread_id": document_id},
                    "callbacks": [langfuse_handler],
                }
                final_state = app.invoke(state, config=config)

        langfuse.flush()  # Ensure spans exported before task returns

        return {
            "status": "success",
            "document_id": document_id,
            "final_draft": final_state["current_draft"],
            "rounds_completed": final_state["iteration_count"],
        }
    except SoftTimeLimitExceeded:
        raise self.retry(countdown=60)
    except Exception as exc:
        raise self.retry(exc=exc, countdown=30)
```

### Worker Configuration

```bash
celery -A tasks worker \
    --pool=prefork \         # NOT eventlet/gevent (conflicts with CrewAI threads)
    --concurrency=2 \        # Low: each pipeline runs for minutes
    --prefetch-multiplier=1  # Don't prefetch (long-running tasks)
```

### Checkpointer + Celery

| Strategy | Use When | Notes |
|----------|----------|-------|
| `checkpointer=None` | Stateless, simplest | No time-travel, no thread_id needed |
| `PostgresSaver` | Crash recovery needed | Another worker can resume from checkpoint |
| `RedisSaver` | Fast, durable | Alternative to Postgres |
| `MemorySaver` | ❌ Never in Celery | In-process memory, useless across workers |

### Memory + Celery

| Scenario | Safe? | Notes |
|----------|-------|-------|
| Different documents in parallel | ✅ | Scoping by doc_id → complete isolation |
| Same document in parallel | ⚠️ | Use Redis SETNX lock for 1 worker/doc |

For shared storage: use NFS/EFS mount so all workers access the same LanceDB store.

### Langfuse + Celery

- `langfuse` client is thread-safe singleton — share across tasks
- `CallbackHandler` should be created per-task (lightweight, no state)
- `flush()` after each task ensures spans exported before ack
- `CrewAIInstrumentor` is global — initialized once at module load

---

## Cost Model

### Per-Round Breakdown

| Component | Calls/Round | Notes |
|-----------|------------|-------|
| Expert A/B/C LLM | 1-3 each | Agent reasoning loop |
| Moderator LLM | 1-2 | +1 if Pydantic retry |
| Writer LLM | 1-2 | Usually single-shot |
| **Agent LLM subtotal** | **5-13** | **Typical: ~7-8** |
| Memory: recall (embedding) | ~5 | 1/task, shallow = no LLM |
| Memory: save (embedding) | ~5 | Non-blocking background |
| Memory: save analysis (LLM) | ~3-5 | gpt-4o-mini: scope/importance |
| Memory: consolidation (LLM) | ~1-3 | Only when duplicates found |
| Memory: extract_memories (LLM) | ~5 | Break outputs → atomic facts |
| **Memory subtotal** | **~15-23** | **Mostly gpt-4o-mini (cheap)** |
| Langfuse tracing | ~10-15 spans | Async, zero LLM cost |
| **TOTAL per round** | **~20-36** | **Typical: ~25** |

### Per-Pipeline (3 rounds)

| Component | Cost |
|-----------|------|
| Agent LLM (GPT-4o / Claude Sonnet) | $0.40-1.50 |
| Memory LLM (gpt-4o-mini) | $0.05-0.15 |
| Embeddings (text-embedding-3-small) | $0.01-0.03 |
| Langfuse tracing | $0.00 |
| **TOTAL** | **$0.50-1.70** |

### Optimization Levers

- `gpt-4o-mini` for experts (structured critique doesn't need GPT-4o)
- `gpt-4o` / `claude-sonnet` for moderator + writer (quality matters)
- `max_iter=5` on agents to cap reasoning loops
- `max_iterations=2` in most cases (round 3 is usually marginal)
- `consolidation_threshold=1.0` to disable consolidation (saves LLM calls)
- Force `depth="shallow"` on recall to skip LLM query analysis

---

## Docker Configuration

```dockerfile
FROM python:3.11-slim

WORKDIR /app
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .
RUN pip install --no-cache-dir .

COPY src/ src/
COPY main.py .

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

CMD ["python", "main.py"]
```

---

## CrewAI Flows Alternative (No LangGraph)

CrewAI Flows (v1.10+) have built-in memory (`self.remember`/`recall`). Can replace LangGraph for simpler deployments.

**Use Flows when**: no checkpointing needed, single-framework preferred.
**Keep LangGraph when**: checkpointing, HITL interrupts, graph composition.

```python
from crewai.flow.flow import Flow, start, listen

class DocumentRefinementFlow(Flow):
    @start()
    def begin(self):
        self.state["iteration"] = 0
        self.state["document_id"] = uuid.uuid4().hex[:12]
        return self.state["draft"]

    @listen(begin)
    def refine(self, draft):
        doc_id = self.state["document_id"]
        # Langfuse still works via OTel (no LangGraph callback though)
        with langfuse.start_as_current_observation(
            as_type="span", name=f"flow-round-{self.state['iteration'] + 1}",
        ):
            with propagate_attributes(session_id=doc_id):
                memory = create_pipeline_memory(doc_id)
                agents = create_scoped_agents(memory, doc_id)
                # ... build tasks, run crew
```

**Langfuse note**: With Flows, you lose the LangChain CallbackHandler (no graph-level node/routing visibility). CrewAI OTel instrumentation still captures all agent/LLM calls.
