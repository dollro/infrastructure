# Quick Reference Card

```
LANGGRAPH + PYDANTIC AI + CREWAI + LANGFUSE — Quick Reference Card

STATE DEFINITION:
  TypedDict(total=False) envelope + Pydantic BaseModel payload
  Task pipeline (default): pure domain fields, no LangChain messages
  Conversational: add messages: Annotated[list[BaseMessage], operator.add]
  Reducers: operator.add for ints/lists, custom _merge_dicts for dicts

SERIALIZATION:
  Deflate: model.model_dump(mode='json')
  Inflate: ModelClass.model_validate(data)

SECURITY:
  JsonPlusSerializer(pickle_fallback=False)

MODEL INJECTION:
  Agent defined WITHOUT model → model passed at .run(model=get_model("tier"))
  get_model(role) → OpenAIChatModel via OpenAIProvider (Pydantic AI)
  get_crewai_llm(role) → crewai.LLM with OpenRouter config
  Never hardcode model identifiers in Agent constructors

NODE TYPES:
  Standard:    def node(state: PipelineState) -> dict
  Pydantic AI: Wrap agent.run(model=...) in adapter function
  CrewAI:      Fresh Crew per round → crew.kickoff() → result.pydantic
  Subgraph:    compiled StateGraph invoked inside a parent node
  Handler:     BaseHandler.extract() → graph → handler.apply()

CREWAI SAFETY:
  AgentTemplate (frozen dataclass) → _clone_agent() per round
  Never reuse Crew or Agent across iterations (they mutate)
  output_pydantic= on Task enforces structured output
  Module-level templates — clone with scoped memory per run

MEMORY:
  scope(path)           → single subtree, read + write
  slice(scopes, ro)     → multiple subtrees, optional read-only
  Nudge (push, 100%)    + Memory (pull, semantic) = dual context

VALIDATION:
  Generator → Validator → Router → Fixer (if error) → Generator
  Soft (prompt) + Hard (code) enforcement for output constraints

HANDLER PATTERN (Domain I/O):
  BaseHandler ABC: extract() → AI pipeline → apply()
  Section/SectionOptimized = stable contract between handlers and graph
  metadata field is opaque — stripped before LLM, carried through for apply()

HUMAN-IN-THE-LOOP:
  interrupt(payload) + while True validation loop

OBSERVABILITY (three mechanisms):
  init_tracing() once at startup (idempotent via @lru_cache)
  Pydantic AI:  Agent.instrument_all()              → OTel auto-instrumentation
  CrewAI:       CrewAIInstrumentor().instrument()    → OpenInference → OTel
  LangGraph:    CallbackHandler passed to graph.invoke(config={"callbacks": [h]})
  Session:      propagate_attributes(session_id=...) groups all spans
  IMPORTANT:    Create CallbackHandler INSIDE propagate_attributes context
  v4: span.update(input=,output=) — update_trace() REMOVED
  Flush: langfuse.flush() before process exit

TESTING:
  Unit: pydantic_ai.models.test.TestModel
  Integration: InMemorySaver
  Snapshot: dirty_equals

PRODUCTION:
  Celery: prefork pool, concurrency=2, acks_late=True
  Checkpointer: PostgresSaver (durable) or None (stateless)
  Memory storage: shared NFS/EFS for multi-worker

COST (3-round pipeline):
  Agent LLM: $0.40-1.50 | Memory LLM: $0.05-0.15 | Total: $0.50-1.70

DEPENDENCIES (install order matters!):
  1. crewai>=1.10     (pins OTel ~=1.34.0 — strictest)
  2. langfuse>=3.0    (OTel >=1.33.1 — satisfied by 1.34.x)
  3. langchain>=1.2   (for langfuse.langchain.CallbackHandler)
                       (also pulls langchain-core + langgraph)
  4. pydantic-ai-slim[openrouter]>=1.0.0  (or pydantic-ai for all providers)
  5. openinference-instrumentation-crewai  (OTel bridge)
  Python >=3.11 required
```
