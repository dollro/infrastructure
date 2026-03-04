# 11 — Testing Strategies

## Unit Testing with TestModel

TestModel replaces the real LLM with a deterministic simulator, allowing testing of node logic without network calls or costs.

```python
# tests/unit/test_pydantic_ai_nodes.py
import pytest
from pydantic_ai.models.test import TestModel


@pytest.mark.asyncio
async def test_research_node_produces_valid_artifact():
    """Test STRUCTURE, not content (which is non-deterministic)."""
    state = create_initial_state("Research AI safety best practices")

    mock_output = ResearchOutput(
        findings=["Finding 1", "Finding 2"],
        sources=["https://example.com/source1"],
        confidence=0.85,
        suggested_followup="Investigate alignment techniques",
    )

    mock_model = TestModel(custom_result_args=mock_output.model_dump())

    with research_agent.override(model=mock_model):
        result = await pydantic_ai_research_node(state)

    assert "artifacts" in result
    assert len(result["artifacts"]) == 1
    assert result["last_error"] is None

    # Validate the artifact can be parsed
    artifact = ResearchArtifact.model_validate(result["artifacts"][0])
    assert artifact.relevance_score == 0.85


@pytest.mark.asyncio
async def test_research_node_handles_llm_error():
    """Gracefully handle LLM failures."""
    state = create_initial_state("Test query")
    mock_model = TestModel(custom_result_text="invalid json{{{")

    with research_agent.override(model=mock_model):
        result = await pydantic_ai_research_node(state)

    assert result.get("last_error") is not None
    assert result.get("retry_count", 0) > 0
```

## Integration Testing with InMemorySaver

```python
# tests/integration/test_full_workflow.py
import pytest
from langgraph.checkpoint.memory import InMemorySaver


@pytest.fixture
def app():
    return compile_graph(use_persistence=True)


def test_full_workflow_completes(app):
    initial_state = create_initial_state("Write analysis of renewable energy")
    config = {"configurable": {"thread_id": "test-thread-1"}}
    result = app.invoke(initial_state, config=config)
    assert result.get("next_action") == "end" or result.get("last_error") is None


def test_workflow_persists_state(app):
    initial_state = create_initial_state("Test persistence")
    config = {"configurable": {"thread_id": "test-thread-2"}}
    app.invoke(initial_state, config=config)
    snapshot = app.get_state(config)
    assert snapshot is not None
    assert len(snapshot.values.get("messages", [])) > 0
```

## Snapshot Testing with dirty_equals

Flexible matching for complex state objects:

```python
from dirty_equals import IsInt, IsStr, IsNow, IsUUID


def test_initial_state_structure():
    state = create_initial_state("Test message")
    assert state == {
        "messages": [{"content": "Test message", "type": IsStr()}],
        "artifacts": [],
        "task_results": [],
        "crew_outputs": [],
        "memory": None,
        "current_step": "entry",
        "retry_count": 0,
        "max_retries": 3,
        "last_error": None,
        "next_action": None,
        "requires_human_approval": False,
    }
```

## Testing CrewAI Nodes

For CrewAI nodes, test the adapter layer (state extraction/deflation), not the crew execution itself. Mock `crew.kickoff()` to return known outputs.

```python
from unittest.mock import patch, MagicMock

def test_crewai_node_deflates_output():
    """Test that the adapter correctly deflates Pydantic models."""
    state = create_initial_state("Test")
    mock_result = MagicMock()
    mock_result.raw = "Final content"

    with patch.object(Crew, 'kickoff', return_value=mock_result):
        result = crewai_content_crew_node(state)

    assert "crew_outputs" in result
    # Verify deflation: all values should be JSON-serializable
    import json
    json.dumps(result)  # Should not raise
```
