# 12 — Security Best Practices

## Pydantic as Primary Security Firewall

### Input Sanitization

```python
from pydantic import BaseModel, Field, field_validator
import re


class SanitizedUserInput(BaseModel):
    """Validate and sanitize user input before processing.
    NEVER pass raw user input to tools or LLM prompts.
    """
    content: str = Field(..., min_length=1, max_length=10000)

    @field_validator('content')
    @classmethod
    def sanitize_content(cls, v: str) -> str:
        v = v.strip()
        # Defense in depth — not a complete solution
        dangerous_patterns = [
            r'ignore\s+previous\s+instructions',
            r'disregard\s+all\s+prior',
            r'system\s*:\s*',
        ]
        for pattern in dangerous_patterns:
            v = re.sub(pattern, '[FILTERED]', v, flags=re.IGNORECASE)
        return v
```

### Code Execution Allowlist

```python
class CodeExecutionRequest(BaseModel):
    """Validate code execution requests against an allowlist.
    NEVER blindly execute LLM-generated code.
    """
    command: str
    arguments: list[str] = Field(default_factory=list)
    ALLOWED_COMMANDS = {'ls', 'cat', 'echo', 'grep', 'find'}

    @field_validator('command')
    @classmethod
    def validate_command(cls, v: str) -> str:
        if v not in cls.ALLOWED_COMMANDS:
            raise ValueError(f"Command '{v}' not in allowlist")
        return v
```

## Serialization Security

**CRITICAL**: Disable pickle fallback on all checkpointers.

```python
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer

# Default serializers may fall back to pickle — severe RCE vulnerability
strict_serializer = JsonPlusSerializer(pickle_fallback=False)
checkpointer = InMemorySaver(serde=strict_serializer)
```

**NEVER** store Exception objects in state — they trigger pickle fallback. Use `ErrorSnapshot` (see `02-state-management.md`).

## Memory Security

When using scoped memory, enforce access control at the memory layer, not just prompt instructions:

- Writer should **never** have a memory scope that includes raw expert critiques
- Use `read_only=True` on slices where agents should not write
- Scope paths include `document_id` to prevent cross-document memory leakage

## API Key Management

- Never hardcode API keys in agent definitions
- Use dependency injection (Pydantic AI's `deps_type`) for config
- In production, load from environment or secrets manager
- Memory LLM (`gpt-4o-mini`) credentials are separate from agent LLM credentials
