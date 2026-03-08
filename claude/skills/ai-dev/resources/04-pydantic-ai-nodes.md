# 04 — Pydantic AI Node Implementation

## The Adapter Pattern

LangGraph manages workflow and state; Pydantic AI manages agent execution with type safety. The adapter node bridges the two.

```python
# src/nodes/pydantic_ai/research_agent.py
from uuid import uuid4
from datetime import datetime
from pydantic_ai import Agent, RunContext
from pydantic import BaseModel, Field
from dataclasses import dataclass


# === Dependencies (enables testability and configuration) ===

@dataclass
class ResearchDependencies:
    search_api_key: str
    max_results: int = 10


# === Structured Output Schema ===

class ResearchOutput(BaseModel):
    findings: list[str] = Field(..., min_length=1)
    sources: list[str]
    confidence: float = Field(ge=0.0, le=1.0)
    suggested_followup: str | None = None


# === Agent Definition ===
# Model is NOT specified here — passed at .run() time for flexibility and testability.

research_agent = Agent(
    deps_type=ResearchDependencies,
    output_type=ResearchOutput,
    instructions="""You are a senior research analyst. Your task is to:
    1. Analyze the user's query
    2. Search for relevant information
    3. Synthesize findings with source attribution
    4. Provide confidence scores for your findings
    Always cite your sources and be explicit about uncertainty."""
)


@research_agent.tool
async def web_search(ctx: RunContext[ResearchDependencies], query: str) -> str:
    """Search the web for information."""
    # In production, call an actual search API
    return f"Search results for: {query}"
```

## LangGraph Adapter Node

The adapter function bridges LangGraph state ↔ Pydantic AI context:

1. **Extract** context from LangGraph state (inflate Pydantic models)
2. **Run** the Pydantic AI agent
3. **Map** results back to LangGraph state format (deflate)

```python
async def pydantic_ai_research_node(state: PipelineState) -> dict:
    """Adapts LangGraph state to Pydantic AI context and back.
    CRITICAL: Implements Inflate/Deflate for serialization safety.
    """
    # === EXTRACT (inflate) ===
    messages = state.get("messages", [])
    last_message = messages[-1].content if messages else ""

    raw_memory = state.get("memory")
    if raw_memory and isinstance(raw_memory, dict):
        memory = AgentMemory.model_validate(raw_memory)
    else:
        memory = None

    query = last_message
    if memory and memory.short_term_context:
        query = f"Context: {memory.short_term_context}\n\nQuery: {last_message}"

    # === RUN AGENT ===
    deps = ResearchDependencies(search_api_key="sk-xxx", max_results=10)

    try:
        # Model passed at invocation — enables env-driven selection and testing
        result = await research_agent.run(
            query,
            model=get_model("research"),  # From your model factory
            deps=deps,
        )

        artifact = ResearchArtifact(
            artifact_id=uuid4(),
            url="https://research.example.com/result",
            summary="\n".join(result.output.findings),
            relevance_score=result.output.confidence,
            source_type="web",
            timestamp=datetime.now(),
        )

        # === DEFLATE for safe serialization ===
        return {
            "artifacts": [artifact.model_dump(mode='json')],
            "current_step": "research",
            "last_error": None,
        }

    except Exception as e:
        return {
            "last_error": str(e),
            "current_step": "research",
            "retry_count": state.get("retry_count", 0) + 1,
        }
```

## Analyzer Node (Processing Prior Artifacts)

Demonstrates inflating artifacts from previous nodes and creating validated task results:

```python
class AnalysisOutput(BaseModel):
    key_insights: list[str] = Field(..., min_length=1)
    risk_factors: list[str] = Field(default_factory=list)
    recommendations: list[str] = Field(..., min_length=1)
    confidence: float = Field(ge=0.0, le=1.0)
    executive_summary: str = Field(..., min_length=100)


analyzer_agent = Agent(
    output_type=AnalysisOutput,
    instructions="You are a senior analyst. Synthesize insights, identify risks, recommend actions."
)


async def pydantic_ai_analyzer_node(state: PipelineState) -> dict:
    # INFLATE artifacts from state
    raw_artifacts = state.get("artifacts", [])
    artifacts = []
    for raw in raw_artifacts:
        if isinstance(raw, dict):
            artifacts.append(ResearchArtifact.model_validate(raw))
        elif isinstance(raw, ResearchArtifact):
            artifacts.append(raw)

    if not artifacts:
        return {"last_error": "No artifacts to analyze", "current_step": "analyzer"}

    artifact_summaries = "\n\n".join([
        f"Source: {a.url}\nRelevance: {a.relevance_score}\nSummary: {a.summary}"
        for a in artifacts
    ])

    try:
        result = await analyzer_agent.run(
            f"Analyze:\n\n{artifact_summaries}",
            model=get_model("analysis"),
        )

        task_result = TaskResult(
            task_id=uuid4(), status="completed",
            output=result.output.executive_summary,
            confidence=result.output.confidence,
            metadata={
                "insights_count": len(result.output.key_insights),
                "risks_count": len(result.output.risk_factors),
                "recommendations": result.output.recommendations,
            }
        )
        # DEFLATE
        return {
            "task_results": [task_result.model_dump(mode='json')],
            "current_step": "analyzer",
            "last_error": None,
        }
    except Exception as e:
        return {
            "last_error": str(e),
            "current_step": "analyzer",
            "retry_count": state.get("retry_count", 0) + 1,
        }
```

## Key Rules for Pydantic AI Adapter Nodes

1. **Always inflate** Pydantic models from state at node entry (they may be dicts after deserialization)
2. **Always deflate** with `model_dump(mode='json')` at node exit
3. **Catch exceptions** and store as `last_error` string (never store Exception objects)
4. **Increment retry_count** on failure for the validation loop to track
5. **Set current_step** so the fixer/validator knows which node produced the output
