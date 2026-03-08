# 10 — Human-in-the-Loop Patterns

## The Pause and Validate Protocol

Uses LangGraph `interrupt()` with a **Double Loop** pattern:
- **Outer Loop**: LangGraph graph execution
- **Inner Loop**: Python while loop for input validation

The node cannot complete until it receives valid human input.

```python
from typing import Literal, Optional
from pydantic import BaseModel, Field, ValidationError
from langgraph.types import interrupt


class HumanFeedback(BaseModel):
    """Validated schema for human input."""
    action: Literal["approve", "reject", "revise"]
    comments: Optional[str] = Field(default=None, max_length=1000)
    revised_content: Optional[str] = Field(default=None)

    def model_post_init(self, __context):
        if self.action == "revise" and not self.revised_content:
            raise ValueError("Revision requires revised_content")


def human_approval_node(state: PipelineState) -> dict:
    """Node that pauses for human approval and validates input.

    The interrupt() call:
    1. Saves current state via checkpointer
    2. Returns control to the caller
    3. Resumes when graph.invoke() is called with Command(resume=payload)
    """
    review_context = {
        "task_results_count": len(state.get("task_results", [])),
        "latest_output": state.get("task_results", [None])[-1],
    }

    while True:
        user_input = interrupt({
            "message": "Human review required",
            "context": review_context,
            "expected_schema": HumanFeedback.model_json_schema(),
        })

        try:
            feedback = HumanFeedback.model_validate(user_input)

            if feedback.action == "approve":
                return {"next_action": "end", "requires_human_approval": False}
            elif feedback.action == "reject":
                return {
                    "next_action": "end",
                    "last_error": f"Human rejected: {feedback.comments}",
                    "requires_human_approval": False,
                }
            elif feedback.action == "revise":
                from langchain_core.messages import HumanMessage
                return {
                    "messages": [HumanMessage(content=feedback.revised_content)],
                    "next_action": "router",
                    "requires_human_approval": False,
                }

        except ValidationError as e:
            print(f"Invalid human feedback: {e}")
            continue  # Loop again — interrupt will be called again
```

## Resuming Paused Graphs

```python
from langgraph.types import Command

config = {"configurable": {"thread_id": "my-thread"}}

# Resume with valid feedback
app.invoke(
    Command(resume={"action": "approve", "comments": "Looks good!"}),
    config=config,
)
```

## Time Travel and State Editing

Manual state edits can corrupt the schema. Always validate before applying.

```python
def validate_state_edit(proposed_state: dict) -> tuple[bool, str]:
    """Validate a proposed state edit before applying.

    Usage:
        is_valid, error = validate_state_edit(user_changes)
        if not is_valid:
            return {"error": error}
        app.update_state(config, proposed_state)
    """
    errors = []
    for i, artifact in enumerate(proposed_state.get("artifacts", [])):
        if isinstance(artifact, dict):
            try:
                ResearchArtifact.model_validate(artifact)
            except ValidationError as e:
                errors.append(f"Artifact {i}: {e}")
    # ... validate task_results, crew_outputs similarly
    if errors:
        return False, "\n".join(errors)
    return True, ""
```

## State Inspection

```python
config = {"configurable": {"thread_id": "my-thread"}}

# Get current state
snapshot = app.get_state(config)
print(snapshot.values)

# Get state history
for state in app.get_state_history(config):
    print(f"Step: {state.metadata.get('step')}, Created: {state.created_at}")
```
