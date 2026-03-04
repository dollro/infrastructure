# 06 — Memory Architecture

## CrewAI Unified Memory (v1.10+)

The unified Memory system replaces the old separate short-term/long-term/entity memory types with a single class offering:

- **Hierarchical scope tree**: memories organized like a filesystem
- **Composite scoring**: recall ranked by (semantic + recency + importance)
- **Auto-consolidation**: near-duplicates merged by LLM (similarity > threshold)
- **Non-blocking saves**: background thread, read-barrier on recall()
- **Graceful degradation**: LLM failure → safe defaults, no crash

## Memory Factory (Per-Pipeline)

Each pipeline run uses a unique document_id as its scope root, ensuring complete isolation between concurrent runs.

```python
from crewai import Memory


def create_pipeline_memory(
    document_id: str,
    storage_dir: str | None = None,
) -> Memory:
    """Create a Memory instance for a single pipeline run.

    Args:
        document_id: Unique identifier for this pipeline run.
        storage_dir: Optional custom path. For Celery: use shared NFS/EFS
            so all workers access the same LanceDB store.
    """
    memory_kwargs = dict(
        # ── Composite scoring tuned for fast-running pipelines ──
        recency_weight=0.4,        # Latest round's findings rank highest
        semantic_weight=0.4,        # Topical matching
        importance_weight=0.2,      # LLM-inferred at save time, breaks ties
        recency_half_life_days=0.01,  # ~15 min half-life (pipeline runs in minutes)

        # ── Consolidation — merge duplicate findings across rounds ──
        consolidation_threshold=0.85,  # Only very similar content triggers merge
        consolidation_limit=5,         # Compare against up to 5 existing records

        # ── Recall depth ──
        query_analysis_threshold=200,   # Short queries skip LLM analysis → fast
        confidence_threshold_high=0.8,
        confidence_threshold_low=0.5,
        exploration_budget=1,

        # ── LLM for memory analysis (cheap/fast — metadata work, not reasoning) ──
        llm="gpt-4o-mini",
        # llm="ollama/llama3.2",  # Fully local/private alternative

        # ── Embedder ──
        embedder={
            "provider": "openai",
            "config": {"model_name": "text-embedding-3-small"},
        },
        # Local alternative (no API calls, no cost):
        # embedder={
        #     "provider": "huggingface",
        #     "config": {"model_name": "sentence-transformers/all-MiniLM-L6-v2"},
        # },
    )

    if storage_dir:
        memory_kwargs["storage"] = storage_dir

    return Memory(**memory_kwargs)
```

### Consolidation in Action

```
Round 1: Expert A stores "The draft has no encryption for health data."
Round 2: Expert A stores "Encryption is still missing for health data."
→ Similarity > 0.85 triggers LLM merge → single consolidated record:
  "Encryption for health data flagged in rounds 1 and 2, still unresolved."
```

This prevents memory bloat and gives downstream agents a clearer signal.

## Scoped Agent Factory (Memory-Isolated Instances)

Each agent gets a MemoryScope or MemorySlice that restricts what it can read and write:

```
┌────────────┬────────────────────────────────────────┬───────────────┐
│ Agent      │ Can Read (recall)                      │ Can Write     │
├────────────┼────────────────────────────────────────┼───────────────┤
│ Expert A   │ /expert/technical (own prior findings) │ /expert/      │
│            │                                        │  technical    │
│ Expert B   │ /expert/growth (own prior findings)    │ /expert/growth│
│ Expert C   │ /expert/legal (own prior findings)     │ /expert/legal │
│ Moderator  │ /expert/* + /moderator (panoramic)     │ /moderator    │
│ Writer     │ /moderator ONLY (context-fenced)       │ (read-only)   │
└────────────┴────────────────────────────────────────┴───────────────┘
```

**Why this matters**: Without scoping, the Writer could recall Expert A's raw critique from memory and start hedging. With scoping, the Writer only sees the Moderator's diplomatic revision plan.

```python
def create_scoped_agents(memory: Memory, document_id: str) -> dict[str, Agent]:
    """Create agent instances with scoped memory views."""
    base = f"/pipeline/{document_id}"

    def _clone_with_memory(template: Agent, agent_memory) -> Agent:
        """Clone agent config with scoped memory."""
        return Agent(
            role=template.role,
            goal=template.goal,
            backstory=template.backstory,
            allow_delegation=template.allow_delegation,
            verbose=template.verbose,
            memory=agent_memory,
        )

    # Expert scopes — each reads/writes its own scope only
    scoped_expert_a = _clone_with_memory(
        expert_a, memory.scope(f"{base}/expert/technical"))
    scoped_expert_b = _clone_with_memory(
        expert_b, memory.scope(f"{base}/expert/growth"))
    scoped_expert_c = _clone_with_memory(
        expert_c, memory.scope(f"{base}/expert/legal"))

    # Moderator slice — reads ALL expert scopes + own rulings
    moderator_slice = memory.slice(
        scopes=[
            f"{base}/expert/technical",
            f"{base}/expert/growth",
            f"{base}/expert/legal",
            f"{base}/moderator",
        ],
        read_only=False,  # Needs to write rulings
    )
    scoped_moderator = _clone_with_memory(moderator, moderator_slice)

    # Writer slice — reads ONLY moderator scope, read-only
    writer_slice = memory.slice(
        scopes=[f"{base}/moderator"],
        read_only=True,
    )
    scoped_writer = _clone_with_memory(writer, writer_slice)

    return {
        "expert_a": scoped_expert_a,
        "expert_b": scoped_expert_b,
        "expert_c": scoped_expert_c,
        "moderator": scoped_moderator,
        "writer": scoped_writer,
    }
```

### Memory API Reference

- `memory.scope(path)` → `MemoryScope`: single subtree, read + write
- `memory.slice(scopes, read_only)` → `MemorySlice`: multiple subtrees, optionally read-only

## Dual Context Strategy (Nudge + Memory)

Neither mechanism alone is sufficient. Together they cover all failure modes.

```
┌──────────────┬──────────────────────────┬───────────────────────────┐
│ Mechanism    │ Nudge (prompt injection)  │ Memory (scoped recall)    │
├──────────────┼──────────────────────────┼───────────────────────────┤
│ Type         │ Push (deterministic)      │ Pull (semantic search)    │
│ Purpose      │ Break argument loops      │ Deep historical recall    │
│ Content      │ Latest rationale only     │ All stored facts, ranked  │
│ Reliability  │ 100% — always in prompt   │ Probabilistic — depends   │
│              │                           │ on query/embedding match  │
│ Cost         │ Zero (string interpolation)│ Embedding + LLM calls    │
│ Scales to    │ 1 round of history        │ Unlimited history         │
└──────────────┴──────────────────────────┴───────────────────────────┘
```

The **nudge** is the load-bearing mechanism for loop prevention. **Memory** adds consolidation, scoped access control, and deep recall.

### Nudge Implementation

```python
prior_context = (
    f"**PRIOR RULING (Round {round_number - 1}):** "
    f"The Editorial Chief previously decided: '{latest_rationale}'\n"
    "Do NOT re-argue points that were already settled. "
    "Focus only on issues in the CURRENT draft that still need attention.\n\n"
    "NOTE: Your memory may contain additional context from earlier rounds. "
    "Use it to avoid repeating previously raised concerns."
)
```

String-interpolated into every expert prompt. 100% reliable — always in the prompt.

### Memory Lifecycle Within a Round

1. `create_pipeline_memory()` → root Memory pointing to LanceDB storage
2. `create_scoped_agents()` → agents with MemoryScope/MemorySlice views
3. `build_tasks_for_round()` → tasks with nudge + scoped agents
4. `crew.kickoff()` runs tasks:
   - a. Before each task: `recall()` from agent's scope → inject into prompt
   - b. Agent executes task (LLM calls)
   - c. After each task: `extract_memories()` → `remember()` to agent's scope (non-blocking)
5. `kickoff()` finally block drains all pending saves
6. State update returned to LangGraph

On the **next round**, a new Memory instance pointing to the same storage picks up all persisted records. Agents recall consolidated, recency-ranked context from prior rounds automatically.

## Memory Tuning Guide

| Parameter | Default | Fast Pipeline | Long-Running |
|-----------|---------|---------------|-------------|
| `recency_half_life_days` | 1.0 | 0.01 (~15 min) | 7.0 |
| `recency_weight` | 0.33 | 0.4 | 0.2 |
| `semantic_weight` | 0.33 | 0.4 | 0.5 |
| `importance_weight` | 0.33 | 0.2 | 0.3 |
| `consolidation_threshold` | 0.85 | 0.85 | 0.90 |

**Optimization levers**:
- `consolidation_threshold=1.0` → disable consolidation (saves LLM calls)
- Force `depth="shallow"` on recall → skip all LLM query analysis
- Use local embedder (HuggingFace) → zero API cost for embeddings
