# 07 — Inter-Agent Contracts

## The Moderator Shield Pattern

Experts never talk directly to downstream consumers (e.g., Writer). A Moderator agent filters, harmonizes, and prioritizes their feedback.

```
Expert A ──┐
Expert B ──┤──► Moderator ──► Writer
Expert C ──┘
```

**Why**: Without the shield, the Writer receives contradictory instructions and hedges. The Moderator makes editorial calls, producing a single coherent plan.

## Pydantic Output Contracts

Inter-agent communication uses strict Pydantic schemas, not free text. This is the "semantic firewall" between opinionated expert feedback and clean instructions.

```python
from pydantic import BaseModel, Field


class ModerationResult(BaseModel):
    """Strict output schema the Moderator MUST produce.

    Two fields intentionally separated for context fencing:
    the Writer receives revision_plan but NOT the rationale.
    """
    conflict_resolution_rationale: str = Field(
        description=(
            "Explain how you resolved contradictions between experts. "
            "Reference specific expert points."
        )
    )
    consolidated_revision_plan: str = Field(
        description=(
            "Final, harmonized, step-by-step instructions for the writer. "
            "Must be actionable and self-contained — the writer will ONLY see this."
        )
    )
```

Applied via `output_pydantic=` on CrewAI tasks:

```python
moderation_task = Task(
    description="Harmonize expert feedback into a revision plan...",
    expected_output="JSON with conflict_resolution_rationale and consolidated_revision_plan",
    agent=agents["moderator"],
    context=[task_a, task_b, task_c],
    output_pydantic=ModerationResult,  # Forces valid JSON; retries on parse failure
)
```

On parse failure, CrewAI automatically retries the LLM call (adds ~1 extra call, rare).

## Context Fencing (Dual Layer)

The Writer should only see the Moderator's harmonized plan, never raw expert critiques. This is enforced at **two layers**:

### Layer 1: Prompt-Level Fencing

```python
revision_task = Task(
    description=(
        "Rewrite the draft based on the Editorial Chief's instructions.\n\n"
        "You will receive a JSON object from the Editorial Chief.\n"
        "IGNORE the 'conflict_resolution_rationale' field entirely.\n"
        "Follow ONLY the 'consolidated_revision_plan' field, step by step.\n"
        "Produce the complete updated document — not a summary of changes."
    ),
    agent=agents["writer"],
    context=[moderation_task],
)
```

### Layer 2: Memory-Level Fencing

The Writer's memory slice only reads from `/moderator` scope. Even if recall fires, it only returns moderator rulings — never raw expert opinions.

```python
writer_slice = memory.slice(
    scopes=[f"{base}/moderator"],
    read_only=True,  # Cannot write to moderator scope
)
```

**Why dual fencing**: LLMs sometimes ignore "ignore X" instructions. Memory-layer enforcement is more reliable than prompt instructions alone.

## Task Design for Expert Panels

Expert tasks should produce structured, bounded output to give the Moderator clear signals:

```python
task_a = Task(
    description=(
        f"Review this draft for technical soundness:\n\n"
        f"---\n{draft}\n---\n\n"
        f"Provide exactly 3 technical strengths and 3 technical weaknesses.\n\n"
        f"{prior_context}"  # Nudge: latest rationale from prior round
    ),
    expected_output="A structured list of 3 pros and 3 cons.",
    agent=agents["expert_a"],
    async_execution=True,
)
```

**Key design choices**:
- "Exactly 3 strengths and 3 weaknesses" — bounded output prevents rambling
- `prior_context` nudge — deterministic loop-breaker
- `async_execution=True` — experts run in parallel

## Moderator Task: Panoramic View + Escalation

The Moderator's memory slice reads ALL expert scopes, enabling pattern detection:

```python
moderation_task = Task(
    description=(
        "You have received feedback from three domain experts.\n\n"
        "Your job:\n"
        "1. Identify contradictions between experts' recommendations.\n"
        "2. Decide how to resolve each contradiction (explain reasoning).\n"
        "3. Produce a unified, step-by-step revision plan for the writer.\n\n"
        "Your memory contains findings and rulings from prior rounds. "
        "Check whether any recurring issues have been flagged multiple times — "
        "these should be escalated in priority.\n\n"
        "Output MUST be valid JSON matching the ModerationResult schema."
    ),
    expected_output="JSON with conflict_resolution_rationale and consolidated_revision_plan",
    agent=agents["moderator"],
    context=[task_a, task_b, task_c],
    output_pydantic=ModerationResult,
)
```

**Pattern**: The Moderator can detect "Expert A has flagged encryption 3 times → escalate priority" through consolidated memory records.

## Contract Validation and Fallback

Always validate the Pydantic contract output and have a fallback:

```python
moderator_output: ModerationResult | None = tasks["moderator"].output.pydantic
new_draft: str = tasks["writer"].output.raw

if moderator_output is None:
    logger.warning("Moderator Pydantic parse failed. Falling back to raw output.")
    rationale = tasks["moderator"].output.raw or "Moderator output unavailable."
else:
    rationale = moderator_output.conflict_resolution_rationale
```

**Rule**: Modern LLM "Structured Output" modes guarantee JSON syntax but NOT semantic validity against Pydantic constraints. Client-side validation is MANDATORY.
