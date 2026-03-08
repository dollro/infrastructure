# 05 — CrewAI Integration

## Agent Templates (Frozen Dataclass Pattern)

**CRITICAL**: CrewAI `Agent` objects mutate internal state during `kickoff()`. Never reuse agents across rounds. Define immutable templates as frozen dataclasses and clone fresh agents per round.

```python
# pipeline/interview/crews.py
from dataclasses import dataclass
from crewai import Agent
from pipeline.models import get_crewai_llm


@dataclass(frozen=True)
class AgentTemplate:
    """Immutable agent definition. No LLM coupling, no per-run state."""
    role: str
    goal: str
    backstory: str


# Module-level templates — safe for concurrent access, truly immutable
expert_ats = AgentTemplate(
    role="ATS & Compliance Specialist",
    goal="Ensure keyword density, formatting compliance, and employment gap handling",
    backstory="You review thousands of CVs annually for ATS optimization...",
)

expert_impact = AgentTemplate(
    role="Technical Impact Assessor",
    goal="Maximize quantified achievements using STAR method, technical depth",
    backstory="You evaluate technical contributions for impact and specificity...",
)

expert_clarity = AgentTemplate(
    role="Communication & Authenticity Auditor",
    goal="Ensure readability, authentic voice, jargon-free clarity",
    backstory="You audit professional documents for clear communication...",
)

moderator = AgentTemplate(
    role="Editorial Chief",
    goal="Resolve conflicting expert feedback into a single coherent revision plan",
    backstory="You synthesize competing perspectives and make editorial decisions...",
)

writer = AgentTemplate(
    role="Professional CV Writer",
    goal="Execute revision instructions with precision and consistency",
    backstory="You apply targeted text revisions while preserving voice...",
)

EXPERT_AGENTS = [expert_ats, expert_impact, expert_clarity]


def _clone_agent(template: AgentTemplate, llm, memory=None) -> Agent:
    """Create a fresh CrewAI Agent from an immutable template."""
    return Agent(
        role=template.role,
        goal=template.goal,
        backstory=template.backstory,
        llm=llm,
        memory=memory,
        verbose=False,
        allow_delegation=False,
    )
```

### Agent Tuning Guide

- `backstory` strongly influences the agent's personality. Make them specific and opinionated for diverse feedback.
- `allow_delegation=False` prevents sub-agent spawning (saves LLM calls).
- `max_iter` (default ~25) caps the agent reasoning loop. Lower to 5-10 for cost control.
- `llm` can be set per-agent. Cheaper models for experts, stronger for moderator/writer.

## Task Definitions

Tasks define what each agent should accomplish. Use `context=` to express dependencies.

```python
from crewai import Task


def create_content_tasks(agents: dict, topic: str, context: str = ""):
    """Task pipeline: Research → Strategy → Writing → Editing"""

    research_task = Task(
        description=f"Research the topic: {topic}\n\nContext: {context}",
        expected_output="Comprehensive research brief with cited sources",
        agent=agents["research_lead"],
    )

    strategy_task = Task(
        description=f"Create content strategy for: {topic}",
        expected_output="Detailed content strategy document",
        agent=agents["content_strategist"],
        context=[research_task],  # Depends on research
    )

    writing_task = Task(
        description=f"Write the content piece about: {topic}",
        expected_output="Complete, polished content piece",
        agent=agents["senior_writer"],
        context=[research_task, strategy_task],
    )

    editing_task = Task(
        description=f"Edit and finalize the content about: {topic}",
        expected_output="Publication-ready content with editor notes",
        agent=agents["editor"],
        context=[writing_task],
    )

    return [research_task, strategy_task, writing_task, editing_task]
```

### Async Execution for Parallel Tasks

Expert tasks that don't depend on each other can run concurrently:

```python
task_a = Task(
    description="Technical review of the draft...",
    agent=agents["expert_a"],
    async_execution=True,   # Runs in a thread
)
task_b = Task(
    description="Growth review of the draft...",
    agent=agents["expert_b"],
    async_execution=True,
)
# Moderator waits for all experts via context=
moderation_task = Task(
    description="Harmonize expert feedback...",
    agent=agents["moderator"],
    context=[task_a, task_b],          # Waits for both
    output_pydantic=ModerationResult,  # Forces valid JSON output
)
```

**⚠️ `async_execution=True` breaks OTel/Langfuse context propagation.**

CrewAI's `async_execution=True` uses `ThreadPoolExecutor`. Python's `ThreadPoolExecutor` reuses worker threads that **do not inherit the calling thread's `contextvars`** (OTel context). Consequence: spans from async tasks lose `session_id`, `tags`, and parent trace — they appear as orphan top-level traces in Langfuse.

**Symptoms**: Multiple disconnected `*._execute_core` traces per run instead of one unified trace. Async tasks have `sessionId: null` and no tags. Synchronous tasks (moderator, writer) trace correctly.

**Recommendation**: Use `async_execution=False` when observability matters. The sequential overhead is small (~20-30s per round for 3 experts) compared to the debugging cost of orphaned traces. If parallel execution is critical, you'd need manual OTel context propagation into worker threads, which CrewAI doesn't support natively.

```python
# WRONG — breaks OTel context
task = Task(description="...", agent=expert, async_execution=True)

# CORRECT — preserves OTel context
task = Task(description="...", agent=expert, async_execution=False)
```

**Legacy note**: `async_execution=True` is generally stable for output correctness with 3 tasks on separate agents. The issue is purely observability — if you don't use OTel/Langfuse tracing, async is fine.

## Per-Round Crew Instantiation (CRITICAL)

**Rule**: Crew MUST be instantiated per-round. CrewAI mutates the Crew object during execution, so reusing it across rounds is unsafe.

```python
# src/nodes/crewai/crews.py
from crewai import Crew, Process


def run_crewai_refinement_round(state: DocumentRefinementState) -> dict:
    """Execute one full expert→moderator→writer cycle.

    CONCURRENCY RULES:
    1. Crew MUST be instantiated per-round (CrewAI mutates it)
    2. Memory is created per-round pointing to SAME storage path
    3. Agents are created per-round with fresh scoped memory views
    """
    current_iter = state["iteration_count"] + 1
    document_id = state["document_id"]

    # Fresh memory, agents, tasks per round
    memory = create_pipeline_memory(document_id)
    agents = create_scoped_agents(memory, document_id)
    tasks = build_tasks_for_round(
        draft=state["current_draft"],
        latest_rationale=state["latest_rationale"],
        round_number=current_iter,
        agents=agents,
    )

    # NEW Crew per round — never reuse
    crew = Crew(
        agents=list(agents.values()),
        tasks=list(tasks.values()),
        process=Process.sequential,
        memory=memory,
        verbose=True,
        # max_rpm=30,  # Rate-limit API calls (prevents 429s)
    )

    try:
        result = crew.kickoff()
    except Exception as e:
        return {
            "last_error": f"CrewAI execution failed: {str(e)}",
            "current_step": "content_crew",
            "retry_count": state.get("retry_count", 0) + 1,
        }

    # Extract structured outputs using dict keys (stable across agent changes)
    moderator_output = tasks["moderator"].output.pydantic
    new_draft = tasks["writer"].output.raw

    # Validation & fallback
    if moderator_output is None:
        rationale = tasks["moderator"].output.raw or "Moderator output unavailable."
    else:
        rationale = moderator_output.conflict_resolution_rationale

    return {
        "current_draft": new_draft,
        "latest_rationale": rationale,
        "iteration_count": current_iter,
    }
```

## Wrapping CrewAI as a LangGraph Node

For more complex graphs where CrewAI is one of several node types:

```python
class ContentCreationCrew:
    """Adapter between LangGraph state and CrewAI execution."""

    def __init__(self):
        self.agents = create_content_agents()

    def kickoff(self, state: PipelineState) -> dict:
        """Extract state → run crew → return state update."""
        # ... (extract context, create tasks, run crew)
        # DEFLATE outputs
        return {
            "crew_outputs": [crew_output.model_dump(mode='json')],
            "task_results": [task_result.model_dump(mode='json')],
            "current_step": "content_crew",
            "last_error": None,
        }

# Singleton adapter
_content_crew = ContentCreationCrew()

def crewai_content_crew_node(state: PipelineState) -> dict:
    return _content_crew.kickoff(state)

# Async variant (CrewAI's kickoff is synchronous)
async def crewai_content_crew_node_async(state: PipelineState) -> dict:
    import asyncio
    return await asyncio.to_thread(_content_crew.kickoff, state)
```

## Concurrency Safety Summary

| Scenario | Safe? | Notes |
|----------|-------|-------|
| Parallel workers, DIFFERENT documents | ✅ | Scoping by document_id ensures isolation |
| Parallel workers, SAME document | ⚠️ | Use distributed lock (Redis SETNX) |
| Reusing Crew across rounds | ❌ | CrewAI mutates Crew — always instantiate fresh |
| Module-level Agent templates | ✅ | Read-only config, never mutated |
