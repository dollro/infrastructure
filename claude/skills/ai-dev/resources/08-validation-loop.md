# 08 — The Validation Loop Pattern

## Validator Node Topology

**Critical Design**: Separate generation and validation into distinct nodes.

```
Generator → Validator → Router → Fixer (if error) → Generator
```

## Validator Node

```python
# src/nodes/validators.py
from pydantic import ValidationError


def validator_node(state: PipelineState) -> dict:
    """Validates outputs from the previous node.

    IMPORTANT: Modern LLM "Structured Output" modes guarantee JSON syntax
    but NOT semantic validity against Pydantic constraints.
    Client-side validation is MANDATORY.
    """
    current_step = state.get("current_step", "unknown")
    validation_errors = []

    if current_step == "research":
        for raw in state.get("artifacts", [])[-1:]:  # Only validate latest
            if isinstance(raw, dict):
                try:
                    ResearchArtifact.model_validate(raw)
                except ValidationError as e:
                    validation_errors.append(
                        f"Artifact validation failed: {_format_validation_error(e)}"
                    )

    elif current_step == "analyzer":
        for raw in state.get("task_results", [])[-1:]:
            if isinstance(raw, dict):
                try:
                    TaskResult.model_validate(raw)
                except ValidationError as e:
                    validation_errors.append(
                        f"TaskResult validation failed: {_format_validation_error(e)}"
                    )

    elif current_step == "content_crew":
        for raw in state.get("crew_outputs", [])[-1:]:
            if isinstance(raw, dict):
                try:
                    CrewOutput.model_validate(raw)
                except ValidationError as e:
                    validation_errors.append(
                        f"CrewOutput validation failed: {_format_validation_error(e)}"
                    )

    if validation_errors:
        return {
            "last_error": "\n".join(validation_errors),
            "retry_count": state.get("retry_count", 0) + 1,
        }

    return {"last_error": None}
```

## Formatting Validation Errors for LLMs

Granular feedback drastically reduces retry cycles. Instead of "validation failed", say "The first dependency of the third task is invalid."

```python
def _format_validation_error(e: ValidationError) -> str:
    """Format Pydantic ValidationError for LLM consumption."""
    error_messages = []
    for error in e.errors():
        loc = " -> ".join(str(l) for l in error["loc"])
        msg = error["msg"]
        error_messages.append(f"  • {loc}: {msg}")
    return "\n".join(error_messages)
```

### Human-Readable Nested Paths

```python
def get_granular_error_path(error: ValidationError) -> list[str]:
    """Convert loc=('tasks', 2, 'dependencies', 0) to
    'The first dependency of the third task'
    """
    messages = []
    for err in error.errors():
        path_parts = []
        loc = err["loc"]
        for i, part in enumerate(loc):
            if isinstance(part, int):
                ordinal = _to_ordinal(part + 1)
                if i > 0 and isinstance(loc[i-1], str):
                    path_parts.append(f"the {ordinal} {loc[i-1].rstrip('s')}")
            else:
                if i == len(loc) - 1:
                    path_parts.append(f"field '{part}'")
        path_str = " in ".join(reversed(path_parts))
        messages.append(f"{path_str}: {err['msg']}")
    return messages


def _to_ordinal(n: int) -> str:
    if 10 <= n % 100 <= 20:
        suffix = 'th'
    else:
        suffix = {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th')
    return f"{n}{suffix}"
```

## Fixer Node

Constructs a specific correction prompt from validation errors:

```python
def fixer_node(state: PipelineState) -> dict:
    """Provides correction guidance for failed validations."""
    from langchain_core.messages import HumanMessage

    error = state.get("last_error", "Unknown validation error")

    correction_message = HumanMessage(
        content=f"""Your previous response failed validation:

{error}

Please regenerate your response, strictly correcting these specific issues.
Do not change anything else — only fix the validation errors listed above.

Remember:
- All required fields must be present
- Numeric constraints (ge, le, gt, lt) must be respected
- String patterns must match exactly
- URLs must be valid format
"""
    )

    return {
        "messages": [correction_message],
        "current_step": state.get("current_step"),  # Maintain for routing back
    }
```

## Monitoring Validation Health

Alert thresholds for production:
- `validation_failure_rate > 0.3` → Model drift warning
- `avg_retry_depth > 1.5` → Cost efficiency degradation

Track these per-node to identify which agents produce the most invalid output.
