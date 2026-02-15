# Agentic AI Development Skill

## Overview
This guide establishes the engineering standard for building **production-grade agentic AI systems** by fusing three best-of-breed frameworks:

| Framework | Role | Responsibility |
|-----------|------|----------------|
| **LangGraph** | Orchestrator | Stateful workflow control, cyclic graphs, persistence, HITL |
| **Pydantic AI** | Single-Agent Executor | Type-safe agents with dependency injection, structured outputs |
| **CrewAI** | Multi-Agent Teams | Role-based collaborative agents for complex, delegated tasks |

## When to Use This Skill
- Building multi-agent orchestration systems
- Implementing type-safe AI agents
- Designing LangGraph workflows
- CrewAI team configurations

---

## 1. Architectural Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    LangGraph (Control Plane)                    │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Router  │───▶│ Pydantic │───▶│  CrewAI  │───▶│ Validator│  │
│  │   Node   │    │ AI Node  │    │   Node   │    │   Node   │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│        │              │               │               │         │
│        └──────────────┴───────────────┴───────────────┘         │
│                    Shared Typed State (Pydantic)                │
└─────────────────────────────────────────────────────────────────┘
```

- **LangGraph** handles the *how*: workflow orchestration, conditional routing, persistence
- **Pydantic AI** handles *type-safe execution*: single agents with validation guarantees
- **CrewAI** handles the *who*: multi-agent teams with role-based collaboration



### 1.1 The Paradigm: Deterministic Harness Around Probabilistic Engines

The fundamental challenge in agentic AI is building **reliable, deterministic applications** using **inherently non-deterministic LLMs**. This architecture solves it through:

1. **LangGraph**: The "nervous system" - models cognitive architecture as a Directed Cyclic Graph (DCG)
2. **Pydantic**: The "immune system" - enforces data integrity, rejects hallucinations
3. **CrewAI**: The "team dynamics" - coordinates specialized agents with clear roles

### 1.2 Component Responsibilities

```python
# Table 1: Architectural Roles in the Unified Stack
"""
┌─────────────────┬─────────────┬────────────────────────────────────────┬─────────────────────────┐
│ Arch. Layer     │ Component   │ Responsibility                         │ Failure Mode Handling   │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Control Flow    │ LangGraph   │ Orchestrates sequence, manages loops,  │ Routes to retry/end     │
│                 │             │ branches, persistence                  │ based on edge logic     │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Data Integrity  │ Pydantic    │ Defines state structure, validates     │ Raises ValidationError  │
│                 │             │ inputs/outputs, serializes data        │ to trigger retry loop   │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Single-Agent    │ Pydantic AI │ Type-safe agent execution with DI,     │ Structured output       │
│ Execution       │             │ tool handling, structured outputs      │ validation              │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Multi-Agent     │ CrewAI      │ Role-based teams, task delegation,     │ Crew-level retry,       │
│ Collaboration   │             │ collaborative problem solving          │ manager escalation      │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Cognition       │ LLM         │ Generates content, reasoning traces,   │ Raw material shaped     │
│                 │             │ tool calls                             │ by Pydantic validation  │
├─────────────────┼─────────────┼────────────────────────────────────────┼─────────────────────────┤
│ Persistence     │ Checkpointer│ Saves graph state at every step,       │ Ensures state recovery  │
│                 │             │ enables time-travel and HITL           │ (handle serialization)  │
└─────────────────┴─────────────┴────────────────────────────────────────┴─────────────────────────┘
"""
```

---

## 2. The Three-Framework Integration Pattern

### 2.1 Core Integration Philosophy

The integration follows the **Adapter Pattern**: LangGraph manages the workflow while Pydantic AI and CrewAI agents are wrapped as specialized nodes.

```python
"""
Integration Pattern Overview:

LangGraph Node Types:
├── Standard Nodes      → Pure functions for routing, validation, preprocessing
├── Pydantic AI Nodes   → Single-agent tasks requiring type safety
└── CrewAI Nodes        → Multi-agent collaborative tasks

Node Selection Criteria:
┌─────────────────────────────────────────────────────────────────────────┐
│ Task Characteristic              │ Recommended Node Type               │
├──────────────────────────────────┼─────────────────────────────────────┤
│ Simple validation/routing        │ Standard LangGraph function         │
│ Single-agent with structured out │ Pydantic AI Adapter Node            │
│ Multi-agent collaboration        │ CrewAI Adapter Node                 │
│ Human approval required          │ LangGraph interrupt + validation    │
└─────────────────────────────────────────────────────────────────────────┘
"""
```

### 2.2 Typical Project Structure

```
project/
├── pyproject.toml
├── src/
│   ├── __init__.py
│   ├── state/
│   │   ├── __init__.py
│   │   ├── models.py          # Pydantic domain models
│   │   └── graph_state.py     # TypedDict graph state
│   ├── nodes/
│   │   ├── __init__.py
│   │   ├── router.py          # Routing/conditional logic
│   │   ├── validators.py      # Validation nodes
│   │   ├── pydantic_ai/       # Pydantic AI adapter nodes
│   │   │   ├── __init__.py
│   │   │   ├── research_agent.py
│   │   │   └── analyzer_agent.py
│   │   └── crewai/            # CrewAI adapter nodes
│   │       ├── __init__.py
│   │       ├── agents.py      # Agent definitions
│   │       ├── tasks.py       # Task definitions
│   │       └── crews.py       # Crew compositions
│   ├── graph/
│   │   ├── __init__.py
│   │   └── workflow.py        # LangGraph definition
│   └── utils/
│       ├── __init__.py
│       └── serialization.py   # Inflate/deflate helpers
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
└── main.py
```

### 2.3 Dependencies

```toml
# pyproject.toml
[project]
dependencies = [
    "langgraph>=0.2.0",
    "langchain-core>=0.3.0",
    "langchain-openai>=0.2.0",
    "pydantic>=2.0",
    "pydantic-ai>=0.0.50",
    "crewai>=0.76.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23",
    "dirty-equals>=0.8",
]
```

---

## 3. State Management with Pydantic

### 3.1 The Hybrid State Pattern (CRITICAL)

**Best Practice**: Use `TypedDict` for the graph envelope and `Pydantic BaseModel` for complex payloads.

```python
# src/state/models.py
"""
Domain entities as strict Pydantic models.
These represent the business objects flowing through the graph.
"""
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
        json_encoders = {
            UUID: str,
            datetime: lambda v: v.isoformat()
        }


class AgentMemory(BaseModel):
    """Persistent memory context for agents."""
    short_term_context: str = Field(default="", max_length=5000)
    long_term_goals: List[str] = Field(default_factory=list)
    learned_preferences: dict = Field(default_factory=dict)


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

```python
# src/state/graph_state.py
"""
The Graph State using TypedDict as the envelope.
This maintains maximum compatibility with LangGraph's internal mechanisms.
"""
from typing import Annotated, List, Optional, Union, Literal
from typing_extensions import TypedDict
import operator
from langchain_core.messages import BaseMessage

from .models import ResearchArtifact, AgentMemory, TaskResult, CrewOutput


class AgentState(TypedDict):
    """
    The central state object passed between all LangGraph nodes.
    
    Design Principles:
    1. Use TypedDict for the envelope (LangGraph compatibility)
    2. Use Pydantic models for complex values (validation)
    3. Use Annotated with reducer for append-only fields
    """
    
    # === Message History (Standard LangChain pattern) ===
    # Append-only: new messages are added, never replaced
    messages: Annotated[List[BaseMessage], operator.add]
    
    # === Domain Objects (Pydantic-validated) ===
    # Append-only: artifacts accumulate through the workflow
    artifacts: Annotated[List[Union[ResearchArtifact, dict]], operator.add]
    
    # Task results from various agents
    task_results: Annotated[List[Union[TaskResult, dict]], operator.add]
    
    # CrewAI outputs
    crew_outputs: Annotated[List[Union[CrewOutput, dict]], operator.add]
    
    # === Singleton State Objects (Overwrite on update) ===
    # Current memory context (replaced, not appended)
    memory: Optional[Union[AgentMemory, dict]]
    
    # === Operational Metadata ===
    current_step: str  # Which node is currently executing
    retry_count: int
    max_retries: int
    last_error: Optional[str]
    
    # === Routing Control ===
    next_action: Optional[Literal["research", "analyze", "crew_task", "validate", "human_review", "end"]]
    requires_human_approval: bool
```

### 3.2 State Initialization Helper

```python
# src/state/graph_state.py (continued)

def create_initial_state(
    user_message: str,
    max_retries: int = 3
) -> AgentState:
    """
    Factory function for creating properly initialized state.
    Ensures all fields have valid defaults.
    """
    from langchain_core.messages import HumanMessage
    
    return AgentState(
        messages=[HumanMessage(content=user_message)],
        artifacts=[],
        task_results=[],
        crew_outputs=[],
        memory=None,
        current_step="entry",
        retry_count=0,
        max_retries=max_retries,
        last_error=None,
        next_action=None,
        requires_human_approval=False,
    )
```

---

## 4. LangGraph Orchestration Layer

### 4.1 Graph Definition

```python
# src/graph/workflow.py
"""
The LangGraph workflow definition.
This is the control plane that orchestrates all agents.
"""
from typing import Literal
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer

from src.state.graph_state import AgentState
from src.nodes import (
    router_node,
    pydantic_ai_research_node,
    pydantic_ai_analyzer_node,
    crewai_content_crew_node,
    validator_node,
    fixer_node,
    human_approval_node,
)


def create_workflow(checkpointer=None) -> StateGraph:
    """
    Creates the LangGraph workflow with all nodes and edges.
    
    Graph Topology:
    
    [Entry] ──► [Router] ──┬──► [PydanticAI Research] ──► [Validator] ──┬──► [Router]
                           │                                            │
                           ├──► [PydanticAI Analyzer] ──► [Validator] ──┤
                           │                                            │
                           ├──► [CrewAI Content Team] ──► [Validator] ──┤
                           │                                            │
                           ├──► [Human Approval] ─────────────────────►─┤
                           │                                            │
                           └──► [END]                    [Fixer] ◄──────┘
                                                             │
                                                             ▼
                                                    (loops back to source)
    """
    
    # Initialize the graph with our typed state
    workflow = StateGraph(AgentState)
    
    # === Add Nodes ===
    workflow.add_node("router", router_node)
    workflow.add_node("research", pydantic_ai_research_node)
    workflow.add_node("analyzer", pydantic_ai_analyzer_node)
    workflow.add_node("content_crew", crewai_content_crew_node)
    workflow.add_node("validator", validator_node)
    workflow.add_node("fixer", fixer_node)
    workflow.add_node("human_approval", human_approval_node)
    
    # === Set Entry Point ===
    workflow.set_entry_point("router")
    
    # === Add Conditional Edges from Router ===
    workflow.add_conditional_edges(
        "router",
        route_after_router,
        {
            "research": "research",
            "analyze": "analyzer",
            "crew_task": "content_crew",
            "human_review": "human_approval",
            "end": END,
        }
    )
    
    # === Add Edges from Agent Nodes to Validator ===
    workflow.add_edge("research", "validator")
    workflow.add_edge("analyzer", "validator")
    workflow.add_edge("content_crew", "validator")
    
    # === Add Conditional Edges from Validator ===
    workflow.add_conditional_edges(
        "validator",
        route_after_validation,
        {
            "success": "router",
            "retry": "fixer",
            "fatal": END,
        }
    )
    
    # === Fixer loops back to appropriate node ===
    workflow.add_conditional_edges(
        "fixer",
        route_after_fixer,
        {
            "research": "research",
            "analyze": "analyzer",
            "crew_task": "content_crew",
        }
    )
    
    # === Human Approval routes back to router ===
    workflow.add_edge("human_approval", "router")
    
    return workflow


def route_after_router(state: AgentState) -> str:
    """Determines which node to execute based on state."""
    return state.get("next_action", "end")


def route_after_validation(state: AgentState) -> Literal["success", "retry", "fatal"]:
    """Routes based on validation results."""
    if state.get("last_error") is None:
        return "success"
    
    if state.get("retry_count", 0) >= state.get("max_retries", 3):
        return "fatal"
    
    return "retry"


def route_after_fixer(state: AgentState) -> str:
    """Routes fixer output back to the appropriate agent."""
    return state.get("current_step", "research")


def compile_graph(use_persistence: bool = True):
    """
    Compiles the graph with optional persistence.
    
    SECURITY NOTE: Always disable pickle fallback in production.
    """
    workflow = create_workflow()
    
    if use_persistence:
        # CRITICAL: Disable pickle for security
        strict_serializer = JsonPlusSerializer(pickle_fallback=False)
        checkpointer = InMemorySaver(serde=strict_serializer)
        return workflow.compile(checkpointer=checkpointer)
    
    return workflow.compile()
```

### 4.2 Router Node Implementation

```python
# src/nodes/router.py
"""
The Router Node: Determines workflow direction based on state analysis.
Uses Pydantic for type-safe routing decisions.
"""
from typing import Literal
from pydantic import BaseModel
from langchain_openai import ChatOpenAI

from src.state.graph_state import AgentState


class RouterDecision(BaseModel):
    """
    Type-safe routing decision.
    Using Literal constrains choices to valid graph nodes.
    """
    next_action: Literal["research", "analyze", "crew_task", "human_review", "end"]
    reasoning: str
    requires_human_approval: bool = False


def router_node(state: AgentState) -> dict:
    """
    Analyzes current state and determines next action.
    
    This node demonstrates type-safe routing using Pydantic.
    The LLM's output is constrained to valid node names.
    """
    llm = ChatOpenAI(model="gpt-4o", temperature=0)
    
    # Build context from state
    messages = state.get("messages", [])
    artifacts = state.get("artifacts", [])
    task_results = state.get("task_results", [])
    
    # Check if we have enough artifacts
    if len(artifacts) >= 3 and not any(r.get("status") == "completed" for r in task_results):
        # We have research, need analysis
        decision = RouterDecision(
            next_action="analyze",
            reasoning="Sufficient research artifacts collected, proceeding to analysis"
        )
    elif len(task_results) > 0 and all(r.get("status") == "completed" for r in task_results):
        # All tasks complete
        decision = RouterDecision(
            next_action="end",
            reasoning="All tasks completed successfully"
        )
    else:
        # Use LLM to decide
        decision = llm.with_structured_output(RouterDecision).invoke([
            {"role": "system", "content": """You are a workflow router. Analyze the current state and decide the next action:
            - "research": Need more information gathering
            - "analyze": Have enough data, need analysis
            - "crew_task": Need multi-agent collaboration (complex content creation, team tasks)
            - "human_review": High-stakes decision requiring approval
            - "end": Task is complete
            """},
            {"role": "user", "content": f"""
            Current messages: {len(messages)}
            Artifacts collected: {len(artifacts)}
            Task results: {task_results}
            Last message: {messages[-1].content if messages else 'None'}
            
            What should be the next action?
            """}
        ])
    
    return {
        "next_action": decision.next_action,
        "requires_human_approval": decision.requires_human_approval,
        "current_step": "router",
    }
```

---

## 5. Pydantic AI Node Implementation

### 5.1 The Adapter Pattern

```python
# src/nodes/pydantic_ai/research_agent.py
"""
Pydantic AI Research Agent wrapped as a LangGraph node.

This demonstrates the Adapter Pattern:
- LangGraph manages workflow and state
- Pydantic AI manages agent execution with type safety
"""
from uuid import uuid4
from datetime import datetime
from pydantic_ai import Agent, RunContext
from pydantic import BaseModel, Field
from dataclasses import dataclass

from src.state.graph_state import AgentState
from src.state.models import ResearchArtifact
from src.utils.serialization import inflate_model, deflate_model


# === Pydantic AI Agent Definition ===

@dataclass
class ResearchDependencies:
    """
    Dependencies injected into the Pydantic AI agent.
    This enables testability and configuration.
    """
    search_api_key: str
    max_results: int = 10


class ResearchOutput(BaseModel):
    """Structured output from the research agent."""
    findings: list[str] = Field(..., min_length=1)
    sources: list[str]
    confidence: float = Field(ge=0.0, le=1.0)
    suggested_followup: str | None = None


# Create the Pydantic AI agent
research_agent = Agent(
    'openai:gpt-4o',
    deps_type=ResearchDependencies,
    result_type=ResearchOutput,
    system_prompt="""You are a senior research analyst. Your task is to:
    1. Analyze the user's query
    2. Search for relevant information
    3. Synthesize findings with source attribution
    4. Provide confidence scores for your findings
    
    Always cite your sources and be explicit about uncertainty.
    """
)


@research_agent.tool
async def web_search(ctx: RunContext[ResearchDependencies], query: str) -> str:
    """Search the web for information."""
    # In production, this would call an actual search API
    # Here we demonstrate the pattern
    return f"Search results for: {query} (using key: {ctx.deps.search_api_key[:4]}...)"


# === LangGraph Adapter Node ===

async def pydantic_ai_research_node(state: AgentState) -> dict:
    """
    Adapts LangGraph state to Pydantic AI context and back.
    
    This node:
    1. Extracts context from LangGraph state
    2. Runs the Pydantic AI agent
    3. Maps results back to LangGraph state format
    
    CRITICAL: Implements Inflate/Deflate pattern for serialization safety.
    """
    
    # === EXTRACT CONTEXT FROM STATE ===
    messages = state.get("messages", [])
    last_message = messages[-1].content if messages else ""
    
    # Inflate existing memory if present
    raw_memory = state.get("memory")
    if raw_memory and isinstance(raw_memory, dict):
        from src.state.models import AgentMemory
        memory = AgentMemory.model_validate(raw_memory)
    else:
        memory = None
    
    # Build query with context
    query = last_message
    if memory and memory.short_term_context:
        query = f"Context: {memory.short_term_context}\n\nQuery: {last_message}"
    
    # === RUN PYDANTIC AI AGENT ===
    deps = ResearchDependencies(
        search_api_key="sk-xxx",  # In production, from config
        max_results=10
    )
    
    try:
        result = await research_agent.run(query, deps=deps)
        
        # Create structured artifact
        artifact = ResearchArtifact(
            artifact_id=uuid4(),
            url="https://research.example.com/result",  # Would come from actual search
            summary="\n".join(result.data.findings),
            relevance_score=result.data.confidence,
            source_type="web",
            timestamp=datetime.now(),
        )
        
        # === DEFLATE FOR SAFE SERIALIZATION ===
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

### 5.2 Analyzer Agent (Second Pydantic AI Node)

```python
# src/nodes/pydantic_ai/analyzer_agent.py
"""
Pydantic AI Analyzer Agent - demonstrates processing artifacts from previous nodes.
"""
from uuid import uuid4
from pydantic_ai import Agent
from pydantic import BaseModel, Field

from src.state.graph_state import AgentState
from src.state.models import ResearchArtifact, TaskResult


class AnalysisOutput(BaseModel):
    """Structured analysis output."""
    key_insights: list[str] = Field(..., min_length=1)
    risk_factors: list[str] = Field(default_factory=list)
    recommendations: list[str] = Field(..., min_length=1)
    confidence: float = Field(ge=0.0, le=1.0)
    executive_summary: str = Field(..., min_length=100)


analyzer_agent = Agent(
    'openai:gpt-4o',
    result_type=AnalysisOutput,
    system_prompt="""You are a senior analyst. Given research artifacts:
    1. Synthesize key insights
    2. Identify risk factors
    3. Provide actionable recommendations
    4. Write an executive summary
    """
)


async def pydantic_ai_analyzer_node(state: AgentState) -> dict:
    """
    Analyzes accumulated research artifacts.
    
    Demonstrates:
    - Inflating Pydantic models from state
    - Processing multiple artifacts
    - Creating validated task results
    """
    
    # === INFLATE ARTIFACTS ===
    raw_artifacts = state.get("artifacts", [])
    artifacts = []
    for raw in raw_artifacts:
        if isinstance(raw, dict):
            artifacts.append(ResearchArtifact.model_validate(raw))
        elif isinstance(raw, ResearchArtifact):
            artifacts.append(raw)
    
    if not artifacts:
        return {
            "last_error": "No artifacts to analyze",
            "current_step": "analyzer",
        }
    
    # Build analysis prompt
    artifact_summaries = "\n\n".join([
        f"Source: {a.url}\nRelevance: {a.relevance_score}\nSummary: {a.summary}"
        for a in artifacts
    ])
    
    try:
        result = await analyzer_agent.run(
            f"Analyze the following research:\n\n{artifact_summaries}"
        )
        
        # Create task result
        task_result = TaskResult(
            task_id=uuid4(),
            status="completed",
            output=result.data.executive_summary,
            confidence=result.data.confidence,
            metadata={
                "insights_count": len(result.data.key_insights),
                "risks_count": len(result.data.risk_factors),
                "recommendations": result.data.recommendations,
            }
        )
        
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

---

## 6. CrewAI Node Implementation

### 6.1 CrewAI Agents Definition

```python
# src/nodes/crewai/agents.py
"""
CrewAI Agent Definitions.
Each agent has a distinct role, goal, and backstory.
"""
from crewai import Agent
from langchain_openai import ChatOpenAI


def create_content_agents(llm=None):
    """
    Factory function to create a team of content creation agents.
    
    Design Principles:
    - Each agent has a clear, distinct role
    - Backstories provide context for behavior
    - Goals are specific and measurable
    """
    if llm is None:
        llm = ChatOpenAI(model="gpt-4o", temperature=0.7)
    
    research_lead = Agent(
        role="Research Lead",
        goal="Gather comprehensive, accurate information on the topic",
        backstory="""You are a veteran researcher with 15 years of experience 
        in investigative journalism. You're known for finding obscure but 
        valuable sources and connecting disparate pieces of information.""",
        llm=llm,
        verbose=True,
        allow_delegation=True,
    )
    
    content_strategist = Agent(
        role="Content Strategist",
        goal="Create an engaging content structure that resonates with the target audience",
        backstory="""You've led content strategy for Fortune 500 companies. 
        You understand what makes content shareable and valuable. You think 
        in terms of user journeys and content funnels.""",
        llm=llm,
        verbose=True,
        allow_delegation=False,
    )
    
    senior_writer = Agent(
        role="Senior Writer",
        goal="Transform research and strategy into compelling, polished content",
        backstory="""You're an award-winning writer who has authored bestselling 
        books and viral articles. Your writing is known for being clear, 
        engaging, and memorable.""",
        llm=llm,
        verbose=True,
        allow_delegation=False,
    )
    
    editor = Agent(
        role="Senior Editor",
        goal="Ensure content quality, accuracy, and consistency",
        backstory="""You've been an editor at The New York Times and The Economist. 
        You have an eagle eye for errors and an instinct for what makes 
        content publishable.""",
        llm=llm,
        verbose=True,
        allow_delegation=False,
    )
    
    return {
        "research_lead": research_lead,
        "content_strategist": content_strategist,
        "senior_writer": senior_writer,
        "editor": editor,
    }
```

### 6.2 CrewAI Tasks Definition

```python
# src/nodes/crewai/tasks.py
"""
CrewAI Task Definitions.
Tasks define what each agent should accomplish.
"""
from crewai import Task


def create_content_tasks(agents: dict, topic: str, context: str = ""):
    """
    Creates the task workflow for content creation.
    
    Task dependencies create a pipeline:
    Research → Strategy → Writing → Editing
    """
    
    research_task = Task(
        description=f"""Research the topic: {topic}
        
        Context from previous work: {context}
        
        Your deliverables:
        1. Key facts and statistics (with sources)
        2. Expert opinions and quotes
        3. Current trends and developments
        4. Potential angles for the content
        
        Be thorough but focused on actionable insights.""",
        expected_output="A comprehensive research brief with cited sources",
        agent=agents["research_lead"],
    )
    
    strategy_task = Task(
        description=f"""Based on the research, create a content strategy for: {topic}
        
        Your deliverables:
        1. Target audience definition
        2. Key messages (3-5)
        3. Content structure/outline
        4. Hook/angle that will capture attention
        5. Call-to-action""",
        expected_output="A detailed content strategy document",
        agent=agents["content_strategist"],
        context=[research_task],  # Depends on research
    )
    
    writing_task = Task(
        description=f"""Write the content piece about: {topic}
        
        Follow the strategy provided. Your writing should be:
        - Engaging from the first sentence
        - Well-structured with clear sections
        - Supported by research and data
        - Actionable and valuable to readers
        
        Target length: 1500-2000 words""",
        expected_output="A complete, polished content piece",
        agent=agents["senior_writer"],
        context=[research_task, strategy_task],  # Depends on both
    )
    
    editing_task = Task(
        description=f"""Edit and finalize the content about: {topic}
        
        Your review should check for:
        1. Factual accuracy (cross-reference with research)
        2. Grammar and style consistency
        3. Flow and readability
        4. Alignment with strategy
        5. SEO considerations
        
        Provide the final, publish-ready version.""",
        expected_output="A publication-ready content piece with editor notes",
        agent=agents["editor"],
        context=[writing_task],
    )
    
    return [research_task, strategy_task, writing_task, editing_task]
```

### 6.3 CrewAI LangGraph Adapter Node

```python
# src/nodes/crewai/crews.py
"""
CrewAI Crews wrapped as LangGraph nodes.

CRITICAL PATTERN: The kickoff() method is adapted to work with LangGraph state.
"""
from uuid import uuid4
from datetime import datetime
import time
from crewai import Crew, Process

from src.state.graph_state import AgentState
from src.state.models import CrewOutput, TaskResult
from .agents import create_content_agents
from .tasks import create_content_tasks


class ContentCreationCrew:
    """
    Encapsulates a CrewAI crew for content creation.
    
    This class provides the adapter interface between
    LangGraph state and CrewAI execution.
    """
    
    def __init__(self):
        self.agents = create_content_agents()
    
    def kickoff(self, state: AgentState) -> dict:
        """
        Main entry point called by LangGraph.
        
        This method:
        1. Extracts context from LangGraph state
        2. Creates and executes the CrewAI crew
        3. Returns updates in LangGraph state format
        
        IMPORTANT: CrewAI's kickoff() is synchronous.
        For async LangGraph, wrap in asyncio.to_thread().
        """
        
        # === EXTRACT CONTEXT FROM STATE ===
        messages = state.get("messages", [])
        last_message = messages[-1].content if messages else "Create content"
        
        # Get existing artifacts for context
        artifacts = state.get("artifacts", [])
        context = ""
        if artifacts:
            context = "\n\n".join([
                f"Previous research: {a.get('summary', a.summary if hasattr(a, 'summary') else str(a))}"
                for a in artifacts[:3]  # Limit context size
            ])
        
        # === CREATE TASKS ===
        tasks = create_content_tasks(
            agents=self.agents,
            topic=last_message,
            context=context
        )
        
        # === CREATE AND RUN CREW ===
        crew = Crew(
            agents=list(self.agents.values()),
            tasks=tasks,
            process=Process.sequential,  # Tasks run in order
            verbose=True,
        )
        
        start_time = time.time()
        
        try:
            # Execute the crew
            result = crew.kickoff()
            
            execution_time = time.time() - start_time
            
            # === CREATE STRUCTURED OUTPUT ===
            crew_output = CrewOutput(
                crew_name="content_creation",
                tasks_completed=len(tasks),
                final_output=str(result),
                agent_contributions=[
                    {"role": agent.role, "completed": True}
                    for agent in self.agents.values()
                ],
                execution_time_seconds=execution_time,
            )
            
            # Also create a task result for the validation pipeline
            task_result = TaskResult(
                task_id=uuid4(),
                status="completed",
                output=str(result),
                confidence=0.85,  # Could be derived from crew metrics
                metadata={
                    "crew_name": "content_creation",
                    "tasks_count": len(tasks),
                }
            )
            
            # === DEFLATE FOR SERIALIZATION ===
            return {
                "crew_outputs": [crew_output.model_dump(mode='json')],
                "task_results": [task_result.model_dump(mode='json')],
                "current_step": "content_crew",
                "last_error": None,
            }
            
        except Exception as e:
            return {
                "last_error": f"CrewAI execution failed: {str(e)}",
                "current_step": "content_crew",
                "retry_count": state.get("retry_count", 0) + 1,
            }


# Create singleton instance for the node
_content_crew = ContentCreationCrew()


def crewai_content_crew_node(state: AgentState) -> dict:
    """
    LangGraph node function that invokes the CrewAI crew.
    
    Usage in graph:
        workflow.add_node("content_crew", crewai_content_crew_node)
    """
    return _content_crew.kickoff(state)


# === ASYNC VARIANT ===
import asyncio

async def crewai_content_crew_node_async(state: AgentState) -> dict:
    """
    Async version for use with async LangGraph.
    Wraps the synchronous CrewAI execution in a thread.
    """
    return await asyncio.to_thread(_content_crew.kickoff, state)
```

---

## 7. The Validation Loop Pattern

### 7.1 Validator Node Topology

**Critical Design**: Separate generation and validation into distinct nodes.

```python
# src/nodes/validators.py
"""
Validation Nodes - The "Immune System" of the agentic workflow.

This module implements the Validator Node Topology:
1. Generator Node produces output
2. Validator Node attempts to parse into Pydantic
3. Router decides: success, retry, or fatal
4. Fixer Node provides correction guidance if retry
"""
from typing import Literal
from pydantic import ValidationError

from src.state.graph_state import AgentState
from src.state.models import ResearchArtifact, TaskResult, CrewOutput


def validator_node(state: AgentState) -> dict:
    """
    Validates all outputs from the previous node.
    
    This node:
    1. Identifies which type of output to validate
    2. Attempts Pydantic validation
    3. Returns validation status for routing
    
    IMPORTANT: Modern LLM "Structured Output" modes guarantee JSON syntax
    but NOT semantic validity against Pydantic constraints.
    Client-side validation is MANDATORY.
    """
    
    current_step = state.get("current_step", "unknown")
    validation_errors = []
    
    # === VALIDATE BASED ON CURRENT STEP ===
    
    if current_step == "research":
        # Validate artifacts
        raw_artifacts = state.get("artifacts", [])
        for i, raw in enumerate(raw_artifacts[-1:]):  # Only validate latest
            if isinstance(raw, dict):
                try:
                    ResearchArtifact.model_validate(raw)
                except ValidationError as e:
                    validation_errors.append(
                        f"Artifact {i} validation failed: {_format_validation_error(e)}"
                    )
    
    elif current_step == "analyzer":
        # Validate task results
        raw_results = state.get("task_results", [])
        for i, raw in enumerate(raw_results[-1:]):
            if isinstance(raw, dict):
                try:
                    TaskResult.model_validate(raw)
                except ValidationError as e:
                    validation_errors.append(
                        f"TaskResult {i} validation failed: {_format_validation_error(e)}"
                    )
    
    elif current_step == "content_crew":
        # Validate crew outputs
        raw_outputs = state.get("crew_outputs", [])
        for i, raw in enumerate(raw_outputs[-1:]):
            if isinstance(raw, dict):
                try:
                    CrewOutput.model_validate(raw)
                except ValidationError as e:
                    validation_errors.append(
                        f"CrewOutput {i} validation failed: {_format_validation_error(e)}"
                    )
    
    # === RETURN VALIDATION STATUS ===
    if validation_errors:
        return {
            "last_error": "\n".join(validation_errors),
            "retry_count": state.get("retry_count", 0) + 1,
        }
    
    return {
        "last_error": None,
        # Don't reset retry_count here - only on successful completion
    }


def _format_validation_error(e: ValidationError) -> str:
    """
    Formats Pydantic ValidationError for LLM consumption.
    
    Provides granular feedback like:
    "The first dependency of the third task is invalid"
    
    This specificity drastically reduces retry cycles.
    """
    error_messages = []
    for error in e.errors():
        loc = " -> ".join(str(l) for l in error["loc"])
        msg = error["msg"]
        error_messages.append(f"  • {loc}: {msg}")
    return "\n".join(error_messages)


def fixer_node(state: AgentState) -> dict:
    """
    Provides correction guidance for failed validations.
    
    This node constructs a specific prompt explaining
    what went wrong and how to fix it.
    """
    from langchain_core.messages import HumanMessage
    
    error = state.get("last_error", "Unknown validation error")
    current_step = state.get("current_step", "unknown")
    
    correction_message = HumanMessage(
        content=f"""Your previous response failed validation with the following errors:

{error}

Please regenerate your response, strictly correcting these specific issues.
Do not change anything else - only fix the validation errors listed above.

Remember:
- All required fields must be present
- Numeric constraints (ge, le, gt, lt) must be respected
- String patterns must match exactly
- URLs must be valid format
"""
    )
    
    return {
        "messages": [correction_message],
        "current_step": current_step,  # Maintain for routing back
    }
```

### 7.2 Handling Nested Validation Errors

```python
# src/utils/validation_helpers.py
"""
Advanced validation utilities for nested structures.
"""
from pydantic import ValidationError
from typing import Any


def get_granular_error_path(error: ValidationError) -> list[str]:
    """
    Extracts human-readable paths from nested validation errors.
    
    Example:
        Input: loc=('tasks', 2, 'dependencies', 0)
        Output: "The first dependency of the third task"
    """
    messages = []
    
    for err in error.errors():
        path_parts = []
        loc = err["loc"]
        
        for i, part in enumerate(loc):
            if isinstance(part, int):
                # Convert index to ordinal
                ordinal = _to_ordinal(part + 1)
                if i > 0 and isinstance(loc[i-1], str):
                    path_parts.append(f"the {ordinal} {loc[i-1][:-1] if loc[i-1].endswith('s') else loc[i-1]}")
                else:
                    path_parts.append(f"item {part}")
            else:
                if i == len(loc) - 1:
                    path_parts.append(f"field '{part}'")
        
        path_str = " in ".join(reversed(path_parts))
        messages.append(f"{path_str}: {err['msg']}")
    
    return messages


def _to_ordinal(n: int) -> str:
    """Convert integer to ordinal string."""
    if 10 <= n % 100 <= 20:
        suffix = 'th'
    else:
        suffix = {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th')
    return f"{n}{suffix}"
```

---

## 8. Serialization and Persistence

### 8.1 The Inflate/Deflate Pattern (CRITICAL)

```python
# src/utils/serialization.py
"""
Serialization utilities implementing the Inflate/Deflate pattern.

PROBLEM: LangGraph's persistence layer serializes state to JSON.
When a Pydantic model containing UUID/datetime is serialized,
these become strings. Upon deserialization, they remain strings,
causing validation failures.

SOLUTION: Explicitly deflate to JSON-safe types before yielding,
and inflate back to Pydantic at node entry.
"""
from typing import TypeVar, Type, Optional, Union
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel

T = TypeVar('T', bound=BaseModel)


def deflate_model(model: BaseModel) -> dict:
    """
    Converts a Pydantic model to a JSON-safe dictionary.
    
    CRITICAL: Always use mode='json' to ensure UUID, datetime, etc.
    are converted to their string representations.
    
    Usage:
        return {"artifact": deflate_model(my_artifact)}
    """
    return model.model_dump(mode='json')


def inflate_model(
    data: Union[dict, BaseModel, None],
    model_class: Type[T]
) -> Optional[T]:
    """
    Reconstructs a Pydantic model from a dictionary.
    
    Handles three cases:
    1. data is None -> returns None
    2. data is already the model type -> returns as-is
    3. data is a dict -> validates and returns model instance
    
    Usage:
        artifact = inflate_model(state.get("artifact"), ResearchArtifact)
    """
    if data is None:
        return None
    
    if isinstance(data, model_class):
        return data
    
    if isinstance(data, dict):
        return model_class.model_validate(data)
    
    raise TypeError(f"Cannot inflate {type(data)} to {model_class}")


def inflate_model_list(
    data: list[Union[dict, BaseModel]],
    model_class: Type[T]
) -> list[T]:
    """
    Inflates a list of dictionaries to model instances.
    
    Usage:
        artifacts = inflate_model_list(state.get("artifacts", []), ResearchArtifact)
    """
    return [
        inflate_model(item, model_class)
        for item in data
        if item is not None
    ]
```

### 8.2 Secure Checkpointer Configuration

```python
# src/graph/persistence.py
"""
Persistence configuration with security best practices.

SECURITY WARNING: Default serializers may fall back to pickle,
which is a severe RCE vulnerability if checkpoints are accessible
from untrusted sources.
"""
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.checkpoint.postgres import PostgresSaver
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer


def create_secure_checkpointer(backend: str = "memory", **kwargs):
    """
    Creates a checkpointer with security hardening.
    
    Args:
        backend: One of "memory", "sqlite", "postgres"
        **kwargs: Backend-specific configuration
    
    Returns:
        Configured checkpointer with pickle disabled
    """
    # CRITICAL: Disable pickle fallback
    strict_serializer = JsonPlusSerializer(pickle_fallback=False)
    
    if backend == "memory":
        return InMemorySaver(serde=strict_serializer)
    
    elif backend == "sqlite":
        conn_string = kwargs.get("conn_string", ":memory:")
        return SqliteSaver.from_conn_string(conn_string, serde=strict_serializer)
    
    elif backend == "postgres":
        conn_string = kwargs.get("conn_string")
        if not conn_string:
            raise ValueError("PostgresSaver requires conn_string")
        return PostgresSaver.from_conn_string(conn_string, serde=strict_serializer)
    
    else:
        raise ValueError(f"Unknown backend: {backend}")


# Example for storing exceptions safely
from pydantic import BaseModel
import traceback


class ErrorSnapshot(BaseModel):
    """
    Safe representation of an exception for persistence.
    
    NEVER store Exception objects directly - they are not JSON serializable
    and would trigger pickle fallback.
    """
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

---

## 9. Human-in-the-Loop Patterns
### 9.1 The Pause and Validate Protocol

```python
# src/nodes/human_approval.py
"""
Human-in-the-Loop implementation using LangGraph interrupt.

This demonstrates the "Double Loop" pattern:
- Outer Loop: LangGraph graph execution
- Inner Loop: Python while loop for input validation

The node cannot complete until it receives valid human input.
"""
from typing import Literal, Optional
from pydantic import BaseModel, Field, ValidationError
from langgraph.types import interrupt

from src.state.graph_state import AgentState


class HumanFeedback(BaseModel):
    """
    Validated schema for human input.
    
    The human/frontend MUST provide data matching this schema.
    """
    action: Literal["approve", "reject", "revise"]
    comments: Optional[str] = Field(default=None, max_length=1000)
    revised_content: Optional[str] = Field(default=None)
    
    def model_post_init(self, __context):
        """Validation: revise action requires revised_content."""
        if self.action == "revise" and not self.revised_content:
            raise ValueError("Revision requires revised_content")


def human_approval_node(state: AgentState) -> dict:
    """
    Node that pauses for human approval and validates input.
    
    CRITICAL: This implements a validation loop that ONLY exits
    when valid HumanFeedback is received.
    
    The interrupt() call:
    1. Saves current state via checkpointer
    2. Returns control to the caller
    3. Resumes here when graph.invoke() is called with Command(resume=payload)
    """
    
    # Prepare context for the human reviewer
    task_results = state.get("task_results", [])
    crew_outputs = state.get("crew_outputs", [])
    
    review_context = {
        "task_results_count": len(task_results),
        "crew_outputs_count": len(crew_outputs),
        "latest_output": task_results[-1] if task_results else crew_outputs[-1] if crew_outputs else None,
    }
    
    # === VALIDATION LOOP ===
    while True:
        # Interrupt and wait for human input
        user_input = interrupt({
            "message": "Human review required",
            "context": review_context,
            "expected_schema": HumanFeedback.model_json_schema(),
        })
        
        # Validate the resume payload
        try:
            feedback = HumanFeedback.model_validate(user_input)
            
            # Valid input received - process and return
            if feedback.action == "approve":
                return {
                    "next_action": "end",  # Proceed to completion
                    "requires_human_approval": False,
                }
            
            elif feedback.action == "reject":
                return {
                    "next_action": "end",  # Abort workflow
                    "last_error": f"Human rejected: {feedback.comments}",
                    "requires_human_approval": False,
                }
            
            elif feedback.action == "revise":
                # Human provided revised content - inject it
                from langchain_core.messages import HumanMessage
                return {
                    "messages": [HumanMessage(content=feedback.revised_content)],
                    "next_action": "router",  # Re-route with new content
                    "requires_human_approval": False,
                }
        
        except ValidationError as e:
            # Invalid input - log and loop again
            print(f"Invalid human feedback: {e}")
            # The interrupt will be called again, waiting for valid input
            continue


# === RESUMING THE GRAPH ===
"""
To resume a graph paused at human_approval_node:

from langgraph.types import Command

# Get the paused graph
config = {"configurable": {"thread_id": "my-thread"}}

# Resume with valid feedback
app.invoke(
    Command(resume={"action": "approve", "comments": "Looks good!"}),
    config=config
)
"""
```

### 9.2 Time Travel and State Editing

```python
# src/utils/state_editing.py
"""
Utilities for safe state editing (Time Travel).

WARNING: Manual state edits can corrupt the schema.
Always validate before submitting to update_state().
"""
from typing import Any
from pydantic import ValidationError

from src.state.graph_state import AgentState
from src.state.models import ResearchArtifact, TaskResult, CrewOutput


def validate_state_edit(proposed_state: dict) -> tuple[bool, str]:
    """
    Validates a proposed state edit before applying.
    
    Usage in a UI backend:
        is_valid, error = validate_state_edit(user_proposed_changes)
        if not is_valid:
            return {"error": error}
        app.update_state(config, proposed_state)
    """
    errors = []
    
    # Validate artifacts
    for i, artifact in enumerate(proposed_state.get("artifacts", [])):
        if isinstance(artifact, dict):
            try:
                ResearchArtifact.model_validate(artifact)
            except ValidationError as e:
                errors.append(f"Artifact {i}: {e}")
    
    # Validate task results
    for i, result in enumerate(proposed_state.get("task_results", [])):
        if isinstance(result, dict):
            try:
                TaskResult.model_validate(result)
            except ValidationError as e:
                errors.append(f"TaskResult {i}: {e}")
    
    # Validate crew outputs
    for i, output in enumerate(proposed_state.get("crew_outputs", [])):
        if isinstance(output, dict):
            try:
                CrewOutput.model_validate(output)
            except ValidationError as e:
                errors.append(f"CrewOutput {i}: {e}")
    
    if errors:
        return False, "\n".join(errors)
    
    return True, ""
```

---

## 10. Testing Strategies

### 10.1 Unit Testing with TestModel

```python
# tests/unit/test_pydantic_ai_nodes.py
"""
Unit tests for Pydantic AI nodes using TestModel.

TestModel replaces the real LLM with a deterministic simulator,
allowing testing of node logic without network calls or costs.
"""
import pytest
from pydantic_ai.models.test import TestModel
from uuid import uuid4

from src.nodes.pydantic_ai.research_agent import (
    research_agent,
    pydantic_ai_research_node,
    ResearchOutput,
)
from src.state.graph_state import create_initial_state


@pytest.mark.asyncio
async def test_research_node_produces_valid_artifact():
    """
    Tests that the research node produces structurally valid output.
    
    Note: We test STRUCTURE, not content (which is non-deterministic).
    """
    # Setup mock state
    state = create_initial_state("Research AI safety best practices")
    
    # Create deterministic mock output
    mock_output = ResearchOutput(
        findings=["Finding 1: AI safety is important", "Finding 2: Testing is crucial"],
        sources=["https://example.com/source1"],
        confidence=0.85,
        suggested_followup="Investigate alignment techniques",
    )
    
    # Override agent's model with TestModel
    mock_model = TestModel(
        custom_result_args=mock_output.model_dump()
    )
    
    with research_agent.override(model=mock_model):
        result = await pydantic_ai_research_node(state)
    
    # Assert structure
    assert "artifacts" in result
    assert len(result["artifacts"]) == 1
    assert result["last_error"] is None
    
    # Validate the artifact can be parsed
    from src.state.models import ResearchArtifact
    artifact = ResearchArtifact.model_validate(result["artifacts"][0])
    assert artifact.relevance_score == 0.85


@pytest.mark.asyncio
async def test_research_node_handles_llm_error():
    """Tests that the node gracefully handles LLM failures."""
    state = create_initial_state("Test query")
    
    # Create a TestModel that raises an error
    mock_model = TestModel(custom_result_text="invalid json{{{")
    
    with research_agent.override(model=mock_model):
        result = await pydantic_ai_research_node(state)
    
    # Should capture error without crashing
    assert result.get("last_error") is not None
    assert result.get("retry_count", 0) > 0
```

### 10.2 Integration Testing with InMemorySaver

```python
# tests/integration/test_full_workflow.py
"""
Integration tests for the complete graph workflow.
"""
import pytest
from langgraph.checkpoint.memory import InMemorySaver

from src.graph.workflow import compile_graph
from src.state.graph_state import create_initial_state


@pytest.fixture
def app():
    """Creates a compiled graph with in-memory persistence."""
    return compile_graph(use_persistence=True)


def test_full_workflow_completes(app):
    """Tests that a simple workflow runs to completion."""
    initial_state = create_initial_state(
        "Write a brief analysis of renewable energy trends"
    )
    
    config = {"configurable": {"thread_id": "test-thread-1"}}
    
    # Run the graph
    result = app.invoke(initial_state, config=config)
    
    # Assert completion
    assert result.get("next_action") == "end" or result.get("last_error") is None


def test_workflow_persists_state(app):
    """Tests that state is persisted and recoverable."""
    initial_state = create_initial_state("Test persistence")
    config = {"configurable": {"thread_id": "test-thread-2"}}
    
    # Run graph
    app.invoke(initial_state, config=config)
    
    # Retrieve persisted state
    snapshot = app.get_state(config)
    
    assert snapshot is not None
    assert len(snapshot.values.get("messages", [])) > 0


def test_workflow_handles_retry(app):
    """Tests the retry loop on validation failure."""
    # This test would require mocking to inject a validation failure
    # Demonstrating the pattern:
    pass
```

### 10.3 Snapshot Testing

```python
# tests/unit/test_state_snapshots.py
"""
Snapshot testing for complex state objects.
"""
import pytest
from dirty_equals import IsInt, IsStr, IsNow, IsUUID

from src.state.graph_state import create_initial_state


def test_initial_state_structure():
    """Verifies initial state matches expected structure."""
    state = create_initial_state("Test message")
    
    # Use dirty_equals for flexible matching
    assert state == {
        "messages": [{"content": "Test message", "type": IsStr()}],  # Simplified
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

---

## 11. Observability and Production Engineering

### 11.1 Unified Distributed Tracing

```python
# src/observability/tracing.py
"""
Unified tracing configuration for LangGraph + Pydantic AI.

PROBLEM: LangGraph traces and Pydantic AI traces appear as
separate operations without proper context propagation.

SOLUTION: Configure a shared OpenTelemetry TracerProvider.
"""
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

# For LangSmith integration
from langsmith.integrations.otel import configure as configure_langsmith

# For Pydantic AI
from pydantic_ai import Agent


def setup_unified_tracing(
    service_name: str = "agentic-system",
    langsmith_project: str = "production",
    otlp_endpoint: str = "http://localhost:4317",
):
    """
    Configures unified tracing across all frameworks.
    
    After calling this, traces will show:
    Graph Run -> Node Execution -> Pydantic Agent Run -> LLM Call -> Tool Call
    """
    
    # Option 1: LangSmith (includes LangGraph + Pydantic AI support)
    configure_langsmith(project_name=langsmith_project)
    
    # Instrument Pydantic AI to use the same tracer
    Agent.instrument_all()
    
    # Option 2: Generic OTLP (for Jaeger, Datadog, etc.)
    # provider = TracerProvider()
    # processor = BatchSpanProcessor(OTLPSpanExporter(endpoint=otlp_endpoint))
    # provider.add_span_processor(processor)
    # trace.set_tracer_provider(provider)
    
    print(f"Tracing configured for service: {service_name}")
```

### 11.2 Semantic Metrics

```python
# src/observability/metrics.py
"""
Custom metrics for agentic system health monitoring.
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime


@dataclass
class AgentMetrics:
    """Tracks key performance indicators."""
    
    # Validation metrics
    validation_attempts: int = 0
    validation_failures: int = 0
    
    # Retry metrics
    total_retries: int = 0
    max_retry_depth: int = 0
    
    # Timing metrics
    avg_node_latency_ms: float = 0.0
    total_execution_time_ms: float = 0.0
    
    @property
    def validation_failure_rate(self) -> float:
        """Percentage of LLM responses that fail Pydantic validation."""
        if self.validation_attempts == 0:
            return 0.0
        return self.validation_failures / self.validation_attempts
    
    @property
    def avg_retry_depth(self) -> float:
        """Average loops required for valid response."""
        if self.validation_attempts == 0:
            return 0.0
        return self.total_retries / self.validation_attempts


def log_validation_event(
    success: bool,
    retry_count: int,
    node_name: str,
    latency_ms: float,
):
    """
    Logs validation events for monitoring.
    
    Alert thresholds:
    - validation_failure_rate > 0.3 → Model drift warning
    - avg_retry_depth > 1.5 → Cost efficiency degradation
    """
    # In production, send to your metrics backend
    # (Prometheus, Datadog, CloudWatch, etc.)
    pass
```

### 11.3 Security Best Practices

```python
# src/security/sanitization.py
"""
Security utilities for input/output sanitization.

Pydantic is your PRIMARY security firewall.
"""
from pydantic import BaseModel, Field, field_validator
import re


class SanitizedUserInput(BaseModel):
    """
    Validates and sanitizes user input before processing.
    
    NEVER pass raw user input to tools or LLM prompts.
    """
    content: str = Field(..., min_length=1, max_length=10000)
    
    @field_validator('content')
    @classmethod
    def sanitize_content(cls, v: str) -> str:
        # Strip whitespace
        v = v.strip()
        
        # Remove potential prompt injection patterns
        # (This is defense in depth - not a complete solution)
        dangerous_patterns = [
            r'ignore\s+previous\s+instructions',
            r'disregard\s+all\s+prior',
            r'system\s*:\s*',
        ]
        
        for pattern in dangerous_patterns:
            v = re.sub(pattern, '[FILTERED]', v, flags=re.IGNORECASE)
        
        return v


class CodeExecutionRequest(BaseModel):
    """
    Validates code execution requests against an allowlist.
    
    NEVER blindly execute LLM-generated code.
    """
    command: str
    arguments: list[str] = Field(default_factory=list)
    
    # Allowlist of safe commands
    ALLOWED_COMMANDS = {'ls', 'cat', 'echo', 'grep', 'find'}
    
    @field_validator('command')
    @classmethod
    def validate_command(cls, v: str) -> str:
        if v not in cls.ALLOWED_COMMANDS:
            raise ValueError(f"Command '{v}' not in allowlist")
        return v
```

---

## 12. Complete Reference Implementation

### 12.1 Main Entry Point

```python
# main.py
"""
Main entry point for the agentic system.
"""
import asyncio
from src.graph.workflow import compile_graph
from src.state.graph_state import create_initial_state
from src.observability.tracing import setup_unified_tracing


async def main():
    # Setup observability
    setup_unified_tracing(
        service_name="hybrid-agent-system",
        langsmith_project="production"
    )
    
    # Compile the graph
    app = compile_graph(use_persistence=True)
    
    # Create initial state
    initial_state = create_initial_state(
        user_message="Create a comprehensive analysis of AI agent frameworks, "
                     "comparing LangGraph, Pydantic AI, and CrewAI. "
                     "Include code examples and best practices."
    )
    
    # Run the graph
    config = {"configurable": {"thread_id": "demo-thread-001"}}
    
    print("Starting agentic workflow...")
    
    # Stream events for visibility
    async for event in app.astream_events(initial_state, config=config, version="v2"):
        kind = event["event"]
        
        if kind == "on_chain_start":
            print(f"\n→ Starting: {event['name']}")
        elif kind == "on_chain_end":
            print(f"✓ Completed: {event['name']}")
        elif kind == "on_tool_start":
            print(f"  🔧 Tool: {event['name']}")
    
    # Get final state
    final_state = app.get_state(config)
    
    print("\n" + "="*50)
    print("WORKFLOW COMPLETE")
    print("="*50)
    print(f"Artifacts collected: {len(final_state.values.get('artifacts', []))}")
    print(f"Tasks completed: {len(final_state.values.get('task_results', []))}")
    print(f"Crew outputs: {len(final_state.values.get('crew_outputs', []))}")
    
    # Print final output
    if final_state.values.get("task_results"):
        latest = final_state.values["task_results"][-1]
        print(f"\nLatest output:\n{latest.get('output', 'N/A')[:500]}...")


if __name__ == "__main__":
    asyncio.run(main())
```

### 12.2 Docker Configuration

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY pyproject.toml .
RUN pip install --no-cache-dir .

# Copy application code
COPY src/ src/
COPY main.py .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

CMD ["python", "main.py"]
```

---

## 13. Anti-Patterns and Common Pitfalls

### 13.1 Common Mistakes

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Using `TypedDict` for complex values | No runtime validation | Use Pydantic models for domain objects |
| Storing `Exception` objects in state | Pickle fallback, security risk | Store `ErrorSnapshot` Pydantic model |
| Validating inside generator node | Conflated concerns, harder to debug | Separate Validator Node Topology |
| Trusting LLM "Structured Output" | Only guarantees JSON syntax, not semantics | Always validate client-side with Pydantic |
| Forgetting `mode='json'` in `model_dump()` | UUID/datetime serialization breaks checkpoints | Always use `model_dump(mode='json')` |
| Manual pickle serialization | Security vulnerability (RCE) | Use `JsonPlusSerializer(pickle_fallback=False)` |
| No retry limit | Infinite loops on persistent errors | Always set `max_retries` in state |
| Modifying state in place | Graph integrity issues | Return new state dict from nodes |

### 13.2 Performance Considerations

```python
"""
Performance Optimization Guidelines:

1. Minimize State Size
   - Don't store full conversation history indefinitely
   - Summarize/compress older context
   - Use references (IDs) instead of full objects where possible

2. Parallel Execution
   - Use LangGraph's parallel branches for independent tasks
   - CrewAI supports parallel task execution within crews
   
3. Caching
   - Cache expensive LLM calls with semantic similarity
   - Use LangGraph's built-in caching where available

4. Batching
   - Batch multiple validation checks in single Pydantic call
   - Batch LLM requests where API supports it
"""
```

---

## Appendix A: Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LANGGRAPH + PYDANTIC AI + CREWAI                     │
│                         Quick Reference Card                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  STATE DEFINITION:                                                      │
│    TypedDict (envelope) + Pydantic BaseModel (payload)                  │
│                                                                         │
│  SERIALIZATION:                                                         │
│    Deflate: model.model_dump(mode='json')                              │
│    Inflate: ModelClass.model_validate(data)                            │
│                                                                         │
│  SECURITY:                                                              │
│    JsonPlusSerializer(pickle_fallback=False)                           │
│                                                                         │
│  NODE TYPES:                                                            │
│    Standard:    def node(state: AgentState) -> dict                    │
│    Pydantic AI: Wrap agent.run() in adapter function                   │
│    CrewAI:      crew.kickoff() returns state dict                      │
│                                                                         │
│  VALIDATION LOOP:                                                       │
│    Generator → Validator → Router → Fixer (if error) → Generator       │
│                                                                         │
│  HUMAN-IN-THE-LOOP:                                                     │
│    interrupt(payload) + while True validation loop                     │
│                                                                         │
│  TESTING:                                                               │
│    Unit: pydantic_ai.models.test.TestModel                             │
│    Integration: InMemorySaver                                          │
│    Snapshot: dirty_equals                                              │
│                                                                         │
│  TRACING:                                                               │
│    configure_langsmith() + Agent.instrument_all()                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Appendix B: Version Compatibility

| Component | Minimum Version | Recommended | Notes |
|-----------|-----------------|-------------|-------|
| Python | 3.10 | 3.11+ | Required for TypedDict + Annotated |
| LangGraph | 0.2.0 | Latest | 1.0 API stability |
| Pydantic | 2.0 | 2.5+ | v2 required for model_dump(mode='json') |
| Pydantic AI | 0.0.50 | Latest | Rapid development, check releases |
| CrewAI | 0.76.0 | Latest | Flows architecture recommended |
| langchain-core | 0.3.0 | Latest | Message format compatibility |

---

*This guide represents typical patterns. Implementations should be adapted to specific organizational requirements and security policies.*
