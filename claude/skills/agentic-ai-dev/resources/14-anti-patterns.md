# 14 — Anti-Patterns and Common Pitfalls

## Common Mistakes

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| `TypedDict` for complex values | No runtime validation | Use Pydantic models for domain objects |
| Storing `Exception` in state | Pickle fallback, security risk | Store `ErrorSnapshot` Pydantic model |
| Validating inside generator node | Conflated concerns, harder to debug | Separate Validator Node Topology |
| Trusting LLM "Structured Output" | Only guarantees JSON syntax, not semantics | Always validate client-side with Pydantic |
| Forgetting `mode='json'` in `model_dump()` | UUID/datetime serialization breaks checkpoints | Always use `model_dump(mode='json')` |
| Manual pickle serialization | Security vulnerability (RCE) | Use `JsonPlusSerializer(pickle_fallback=False)` |
| No retry limit | Infinite loops on persistent errors | Always set `max_retries` in state |
| Modifying state in place | Graph integrity issues | Return new state dict from nodes |
| Reusing Crew across rounds | CrewAI mutates Crew during execution | Instantiate fresh Crew per round |
| Shared mutable agents | Race conditions in concurrent execution | Module-level templates, per-run clones |
| Writer reading expert critiques | Hedging, apologetic language | Memory scoping + prompt fencing (dual layer) |
| Nudge-only context | 1 round of history, loses early rulings | Nudge + Memory (dual context strategy) |
| Memory-only context | Probabilistic recall, may miss critical rulings | Nudge + Memory (dual context strategy) |
| Shared LangfuseCallbackHandler | Cross-contamination in concurrent environments | Create per-task/request handler |
| `MemorySaver` in Celery | In-process memory, useless across workers | Use `PostgresSaver` or `None` |
| `eventlet`/`gevent` pool with CrewAI | Conflicts with CrewAI's threading | Use `prefork` pool |
| Installing `langchain-core` only for Langfuse | `CallbackHandler` does `import langchain` | Install full `langchain>=1.2` |
| Using `pydantic-ai` (full) | Pulls ALL provider SDKs (~500MB) | Use `pydantic-ai-slim[openai]` |
| Installing Langfuse before CrewAI | OTel resolves to 1.39.x, breaks CrewAI's ~=1.34.0 | Install CrewAI first or use lockfile |
| Listing `langgraph` separately | `langchain>=1.2` already bundles langgraph | Let langchain pull it |
| `span.update_trace(...)` in Langfuse v4 | Removed — `AttributeError` at runtime | Use `span.update(input=, output=)` + `propagate_attributes(trace_name=)` |

## Performance Optimization Guidelines

1. **Minimize State Size** — Don't store full conversation history indefinitely. Summarize/compress older context. Use references (IDs) instead of full objects where possible.

2. **Parallel Execution** — Use LangGraph's parallel branches for independent tasks. Use `async_execution=True` on CrewAI expert tasks.

3. **Caching** — Cache expensive LLM calls with semantic similarity. Use LangGraph's built-in caching where available.

4. **Batching** — Batch multiple validation checks in single Pydantic call. Batch LLM requests where API supports it.

5. **Model Tiering** — Cheaper models for experts and memory analysis. Strongest model for moderator and writer.

6. **Memory Tuning** — Adjust `recency_half_life_days` for pipeline duration. Disable consolidation (`threshold=1.0`) if not needed. Use local embedder for zero API cost.

7. **Agent Reasoning Caps** — Set `max_iter=5-10` on agents to control costs. Default ~25 is usually too high.
