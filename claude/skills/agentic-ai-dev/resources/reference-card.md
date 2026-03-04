# Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────────┐
│              LANGGRAPH + PYDANTIC AI + CREWAI + LANGFUSE                │
│                         Quick Reference Card                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  STATE DEFINITION:                                                      │
│    TypedDict (envelope) + Pydantic BaseModel (payload)                  │
│                                                                         │
│  SERIALIZATION:                                                         │
│    Deflate: model.model_dump(mode='json')                              │
│    Inflate: ModelClass.model_validate(data)                            │
│                                                                         │
│  SECURITY:                                                              │
│    JsonPlusSerializer(pickle_fallback=False)                           │
│                                                                         │
│  NODE TYPES:                                                            │
│    Standard:    def node(state: AgentState) -> dict                    │
│    Pydantic AI: Wrap agent.run() in adapter function                   │
│    CrewAI:      crew.kickoff() returns state dict                      │
│                                                                         │
│  CREWAI SAFETY:                                                         │
│    Fresh Crew per round — never reuse                                  │
│    Module-level agent templates — clone with scoped memory per run     │
│    output_pydantic= for inter-agent contracts                          │
│                                                                         │
│  MEMORY:                                                                │
│    scope(path)           → single subtree, read + write                │
│    slice(scopes, ro)     → multiple subtrees, optional read-only       │
│    Nudge (push, 100%)    + Memory (pull, semantic) = dual context      │
│                                                                         │
│  VALIDATION LOOP:                                                       │
│    Generator → Validator → Router → Fixer (if error) → Generator       │
│                                                                         │
│  HUMAN-IN-THE-LOOP:                                                     │
│    interrupt(payload) + while True validation loop                     │
│                                                                         │
│  OBSERVABILITY:                                                         │
│    Langfuse: CrewAIInstrumentor (OTel) + CallbackHandler (LangGraph)   │
│    Session: propagate_attributes(session_id=document_id)               │
│    Flush: langfuse.flush() before process exit                         │
│                                                                         │
│  TESTING:                                                               │
│    Unit: pydantic_ai.models.test.TestModel                             │
│    Integration: InMemorySaver                                          │
│    Snapshot: dirty_equals                                              │
│                                                                         │
│  PRODUCTION:                                                            │
│    Celery: prefork pool, concurrency=2, acks_late=True                 │
│    Checkpointer: PostgresSaver (durable) or None (stateless)           │
│    Memory storage: shared NFS/EFS for multi-worker                     │
│                                                                         │
│  COST (3-round pipeline):                                               │
│    Agent LLM: $0.40-1.50 | Memory LLM: $0.05-0.15 | Total: $0.50-1.70│
│                                                                         │
│  DEPENDENCIES (install order matters!):                                 │
│    1. crewai>=1.10     (pins OTel ~=1.34.0 — strictest)                │
│    2. langfuse>=3.0    (OTel >=1.33.1 — satisfied by 1.34.x)          │
│    3. langchain>=1.2   (for langfuse.langchain.CallbackHandler)        │
│                        (also pulls langchain-core + langgraph)          │
│    4. pydantic-ai-slim[openai]  (NOT full pydantic-ai)                 │
│    5. openinference-instrumentation-crewai  (OTel bridge)              │
│    Python >=3.11 required                                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```
