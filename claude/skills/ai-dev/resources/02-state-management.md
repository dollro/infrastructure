# 02 — State Management with Pydantic

## The Hybrid State Pattern (CRITICAL)

**Best Practice**: Use `TypedDict` for the graph envelope and `Pydantic BaseModel` for complex payloads.

**Why**: LangGraph serializes TypedDict internally. Pydantic models inside it give runtime validation for domain objects. This hybrid gives you both LangGraph compatibility and data integrity.

### Domain Models

```python
# src/state/models.py
from typing import List, Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, HttpUrl


class ResearchArtifact(BaseModel):
    """Validated research output from agents."""
    artifact_id: UUID
    url: HttpUrl
    summary: str = Field(..., min_length=50, max_length=2000)
    relevance_score: float = Field(ge=0.0, le=1.0)
    source_type: str = Field(pattern=r"^(web|academic|internal)$")
    timestamp: datetime

    class Config:
        json_encoders = {UUID: str, datetime: lambda v: v.isoformat()}


class TaskResult(BaseModel):
    """Standardized task output from any agent."""
    task_id: UUID
    status: str = Field(pattern=r"^(pending|in_progress|completed|failed)$")
    output: str
    confidence: float = Field(ge=0.0, le=1.0)
    metadata: dict = Field(default_factory=dict)


class CrewOutput(BaseModel):
    """Structured output from a CrewAI execution."""
    crew_name: str
    tasks_completed: int
    final_output: str
    agent_contributions: List[dict] = Field(default_factory=list)
    execution_time_seconds: float
```

### Pydantic Contracts Between Agents

When one agent's output feeds into another, define a strict Pydantic schema. This is the "semantic firewall" — it forces the LLM to produce parseable structured output and prevents raw free-text from leaking between pipeline stages.

```python
class ModerationResult(BaseModel):
    """Strict output schema the Moderator MUST produce.

    Two fields intentionally separated for context fencing:
    the Writer receives revision_plan but NOT the rationale.
    """
    conflict_resolution_rationale: str = Field(
        description="How contradictions between experts were resolved."
    )
    consolidated_revision_plan: str = Field(
        description="Final step-by-step instructions for the writer. "
                    "Must be self-contained — the writer will ONLY see this."
    )
```

Use with CrewAI: `output_pydantic=ModerationResult` on the Task. On parse failure, CrewAI automatically retries the LLM call.

### Graph State (TypedDict Envelope)

```python
# src/state/graph_state.py
from typing import Annotated, List, Optional, Union, Literal
from typing_extensions import TypedDict
import operator


class PipelineState(TypedDict, total=False):
    """Central state object passed between all LangGraph nodes.

    Design Principles:
    1. TypedDict for the envelope (LangGraph compatibility)
    2. Pydantic models for complex values (validation)
    3. Annotated with reducer for append-only fields
    4. total=False — nodes return only the keys they update
    """
    # Append-only domain objects (Pydantic-validated)
    artifacts: Annotated[List[Union[ResearchArtifact, dict]], operator.add]
    task_results: Annotated[List[Union[TaskResult, dict]], operator.add]
    crew_outputs: Annotated[List[Union[CrewOutput, dict]], operator.add]
    # Singleton state (overwrite on update)
    memory: Optional[Union[AgentMemory, dict]]
    # Operational metadata
    current_step: str
    retry_count: int
    max_retries: int
    last_error: Optional[str]
    # Routing control
    next_action: Optional[Literal["research", "analyze", "crew_task", "validate", "human_review", "end"]]
    requires_human_approval: bool
```

**For simpler pipelines** (e.g., iterative document refinement), a flat state suffices:

```python
class DocumentRefinementState(TypedDict):
    """Flat state for iteration-based pipelines.

    IMPORTANT: Every field is serialized between nodes. Keep flat.
    Complex nested objects can cause checkpointing issues.
    """
    current_draft: str
    latest_rationale: str
    iteration_count: int
    max_iterations: int
    document_id: str  # Unique ID for memory scoping & observability session
```

### State Initialization Helper

```python
def create_initial_state(max_retries: int = 3) -> PipelineState:
    """Factory function for properly initialized state."""
    return PipelineState(
        artifacts=[], task_results=[], crew_outputs=[],
        memory=None, current_step="entry",
        retry_count=0, max_retries=max_retries,
        last_error=None, next_action=None,
        requires_human_approval=False,
    )
```

---

## The Inflate/Deflate Pattern (CRITICAL)

**Problem**: LangGraph's persistence layer serializes state to JSON. Pydantic models with UUID/datetime become strings on deserialization, causing validation failures on the next node.

**Solution**: Explicitly deflate to JSON-safe types before yielding, and inflate back at node entry.

```python
# src/utils/serialization.py
from typing import TypeVar, Type, Optional, Union
from pydantic import BaseModel

T = TypeVar('T', bound=BaseModel)


def deflate_model(model: BaseModel) -> dict:
    """Convert Pydantic model to JSON-safe dict.
    CRITICAL: Always use mode='json' for UUID, datetime, etc.
    """
    return model.model_dump(mode='json')


def inflate_model(data: Union[dict, BaseModel, None], model_class: Type[T]) -> Optional[T]:
    """Reconstruct Pydantic model from dict.
    Handles: None → None, already model → as-is, dict → validate.
    """
    if data is None:
        return None
    if isinstance(data, model_class):
        return data
    if isinstance(data, dict):
        return model_class.model_validate(data)
    raise TypeError(f"Cannot inflate {type(data)} to {model_class}")


def inflate_model_list(data: list[Union[dict, BaseModel]], model_class: Type[T]) -> list[T]:
    """Inflate a list of dicts to model instances."""
    return [inflate_model(item, model_class) for item in data if item is not None]
```

**Usage in nodes:**

```python
# At node ENTRY — inflate
artifacts = inflate_model_list(state.get("artifacts", []), ResearchArtifact)

# At node EXIT — deflate
return {"artifacts": [deflate_model(artifact)]}
# Or equivalently:
return {"artifacts": [artifact.model_dump(mode='json')]}
```

---

## Secure Checkpointer Configuration

```python
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer


def create_secure_checkpointer(backend: str = "memory", **kwargs):
    """Create checkpointer with pickle DISABLED (security hardening).

    Backends: "memory" (dev), "sqlite" (local), "postgres" (production)
    """
    # CRITICAL: Disable pickle fallback — prevents RCE vulnerability
    strict_serializer = JsonPlusSerializer(pickle_fallback=False)

    if backend == "memory":
        return InMemorySaver(serde=strict_serializer)
    elif backend == "sqlite":
        from langgraph.checkpoint.sqlite import SqliteSaver
        return SqliteSaver.from_conn_string(
            kwargs.get("conn_string", ":memory:"), serde=strict_serializer
        )
    elif backend == "postgres":
        from langgraph.checkpoint.postgres import PostgresSaver
        return PostgresSaver.from_conn_string(
            kwargs["conn_string"], serde=strict_serializer
        )
```

### Storing Exceptions Safely

**NEVER** store Exception objects in state — they trigger pickle fallback.

```python
import traceback
from pydantic import BaseModel

class ErrorSnapshot(BaseModel):
    """Safe, JSON-serializable representation of an exception."""
    error_type: str
    message: str
    traceback_str: str
    timestamp: str

    @classmethod
    def from_exception(cls, e: Exception) -> "ErrorSnapshot":
        from datetime import datetime
        return cls(
            error_type=type(e).__name__,
            message=str(e),
            traceback_str=traceback.format_exc(),
            timestamp=datetime.now().isoformat(),
        )
```
