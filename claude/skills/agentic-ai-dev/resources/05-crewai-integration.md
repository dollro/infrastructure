# 05 — CrewAI Integration

## Agent Definitions as Templates

Define agents at module level as **templates**. They hold configuration (role, goal, backstory) but NO per-run state. Memory scoping is applied per-run via factory functions.

```python
# src/nodes/crewai/agents.py
from crewai import Agent


# Module-level templates — safe for concurrent access, never mutated
expert_a = Agent(
    role="Senior Systems Architect",
    goal="Identify technical flaws, scalability bottlenecks, and security risks",
    backstory=(
        "You are a cynical senior engineer with 20 years of experience. "
        "You focus relentlessly on what could go wrong."
    ),
    allow_delegation=False,   # Prevents sub-agent spawning (saves LLM calls)
    # max_iter=10,            # Cap reasoning loops to control cost
    # llm="gpt-4o-mini",     # Cheaper model for structured critique
    verbose=True,
)

moderator = Agent(
    role="Editorial Chief",
    goal="Harmonize conflicting expert feedback into a single revision plan",
    backstory=(
        "You are a master of diplomacy and editorial judgment. "
        "When experts contradict each other, you weigh arguments and make a call."
    ),
    allow_delegation=False,
    verbose=True,
    # llm="claude-sonnet-4-20250514",  # Strongest model for the moderator
)

writer = Agent(
    role="Technical Document Specialist",
    goal="Rewrite the document strictly based on the provided revision plan",
    backstory=(
        "You follow revision plans to the letter and never inject your own opinions."
    ),
    allow_delegation=False,
    verbose=True,
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

**Note**: `async_execution=True` uses threads. Generally stable with 3 tasks on separate agents. If flaky (missed/duplicated output), set `False` as fallback.

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

    def kickoff(self, state: AgentState) -> dict:
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

def crewai_content_crew_node(state: AgentState) -> dict:
    return _content_crew.kickoff(state)

# Async variant (CrewAI's kickoff is synchronous)
async def crewai_content_crew_node_async(state: AgentState) -> dict:
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
