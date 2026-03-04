# 15 — Dependencies & Compatibility

## Dependency Map

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Your Project (pyproject.toml)                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  crewai >=1.10.0                                                             │
│  ├── opentelemetry-api ~=1.34.0     ← STRICTEST OTel pin, install first!    │
│  ├── opentelemetry-sdk ~=1.34.0                                              │
│  ├── opentelemetry-exporter-otlp-proto-http ~=1.34.0                         │
│  ├── openai >=1.83.0                                                         │
│  ├── pydantic ~=2.11.9                                                       │
│  ├── lancedb >=0.29.2               ← vector storage for Memory             │
│  ├── chromadb ~=1.1.0               ← also uses OTel                        │
│  ├── instructor >=1.3.3             ← structured output parsing             │
│  ├── mcp ~=1.26.0                   ← Model Context Protocol                │
│  └── (NO langchain dependency)      ← confirmed standalone since v0.80+     │
│                                                                              │
│  langfuse >=3.0.0                                                            │
│  ├── opentelemetry-api >=1.33.1,<2.0   ← satisfied by 1.34.x from crewai   │
│  ├── opentelemetry-sdk >=1.33.1,<2.0                                         │
│  ├── opentelemetry-exporter-otlp-proto-http >=1.33.1,<2.0                    │
│  ├── openai >=0.27.8                ← compatible with crewai's pin          │
│  ├── pydantic >=1.10.7,<3.0                                                  │
│  ├── httpx >=0.15.4,<1.0                                                     │
│  ├── wrapt >=1.14,<2.0                                                       │
│  └── (NO langchain in core)         ← OTel-based since v3                   │
│      BUT: langfuse.langchain.CallbackHandler does `import langchain`         │
│      at module level → requires full `langchain` package installed           │
│                                                                              │
│  langchain >=1.2.0                                                           │
│  ├── langchain-core >=1.2.0,<2.0    ← message types, callbacks              │
│  │   ├── langsmith                  ← tracing (LangSmith native)             │
│  │   └── pydantic >=2.7.4,<3.0                                               │
│  ├── langgraph >=1.0.8,<1.1.0       ← bundled since langchain 1.2!          │
│  │   ├── langchain-core >=0.1                                                 │
│  │   ├── langgraph-checkpoint                                                 │
│  │   └── langgraph-sdk                                                        │
│  └── pydantic >=2.7.4,<3.0                                                   │
│                                                                              │
│  pydantic-ai-slim[openai] >=0.0.50  ← slim = no unused provider SDKs        │
│  ├── pydantic-graph                                                           │
│  ├── genai-prices                                                             │
│  ├── openai (via [openai] extra)                                              │
│  └── (NO langchain, NO OTel)                                                 │
│                                                                              │
│  openinference-instrumentation-crewai                                        │
│  ├── openinference-instrumentation                                            │
│  ├── openinference-semantic-conventions                                       │
│  └── opentelemetry-instrumentation  ← compatible with OTel 1.34.x           │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Install Order (CRITICAL)

pip/uv resolve constraints, but **install order affects which version is picked** for transitive deps. Install from strictest to loosest OTel constraint:

```bash
# 1. CrewAI first — pins OTel to narrow range ~=1.34.0
pip install "crewai>=1.10.0"

# 2. Langfuse — accepts OTel >=1.33.1, already satisfied by 1.34.x
pip install "langfuse>=3.0.0"

# 3. langchain (full package) — needed for langfuse.langchain.CallbackHandler
#    Also pulls langchain-core + langgraph (since langchain >=1.2)
pip install "langchain>=1.2.0"

# 4. Pydantic AI slim — no OTel/langchain deps
pip install "pydantic-ai-slim[openai]>=0.0.50"

# 5. OTel bridge for CrewAI → Langfuse
pip install "openinference-instrumentation-crewai"
```

With `uv` (recommended for speed and deterministic resolution):
```bash
uv add crewai langfuse langchain "pydantic-ai-slim[openai]" openinference-instrumentation-crewai
```

## Version Compatibility Matrix

| Component | Minimum | Recommended | Pin Style | Notes |
|-----------|---------|-------------|-----------|-------|
| **Python** | 3.11 | 3.12 | `>=3.11` | 3.10 has known issues with Langfuse+LangGraph |
| **CrewAI** | 1.10.0 | Latest | `>=1.10.0` | Unified Memory with scopes |
| **Langfuse** | 3.0.0 | Latest | `>=3.0.0` | v3 = OTel rewrite (June 2025) |
| **langchain** | 1.2.0 | Latest | `>=1.2.0` | Required for `langfuse.langchain.CallbackHandler` |
| **LangGraph** | 1.0.8 | Latest | (via langchain) | Auto-installed as langchain dep since 1.2 |
| **langchain-core** | 1.2.0 | Latest | (via langchain) | Message types, callbacks |
| **Pydantic** | 2.5 | 2.11+ | `>=2.5` | v2 required for `model_dump(mode='json')` |
| **Pydantic AI** | 0.0.50 | Latest | `>=0.0.50` | Use `-slim[openai]` variant |
| **OTel API** | 1.33.1 | 1.34.x | (via crewai) | CrewAI pins ~=1.34.0 |

## Known Compatibility Issues

### 1. OTel Version Pinning (CrewAI ↔ Langfuse)

**Issue**: CrewAI pins `opentelemetry-api~=1.34.0` (narrow range). Langfuse accepts `>=1.33.1,<2.0.0` (wide range). If Langfuse installs first, it picks 1.39.x which violates CrewAI's pin.

**Solution**: Install CrewAI first, or use a lockfile (uv.lock / poetry.lock).

### 2. Langfuse CallbackHandler Requires Full `langchain`

**Issue**: `from langfuse.langchain import CallbackHandler` does `import langchain` (the full package, not `langchain-core`) at module level to check the version string. Installing only `langchain-core` raises `ModuleNotFoundError`.

**Source**: `langfuse/langchain/CallbackHandler.py` line 37:
```python
import langchain  # ← requires full langchain package
if langchain.__version__.startswith("1"):
    from langchain_core.agents import ...  # then uses langchain-core
```

**Impact**: You cannot use `langchain-core` alone for LangGraph + Langfuse. You need the full `langchain` package.

**Workaround if you want Langfuse without langchain**: Use Langfuse's `@observe` decorator and `propagate_attributes()` directly — no CallbackHandler needed. You lose automatic LangGraph node/routing tracing but retain all manual spans and CrewAI OTel auto-instrumentation.

### 3. `langchain` v1.2+ Bundles `langgraph`

**Implication**: `pip install langchain>=1.2.0` automatically installs `langgraph`. You do NOT need to list `langgraph` separately in your dependencies.

### 4. `pydantic-ai` vs `pydantic-ai-slim`

**Issue**: `pydantic-ai` (full) installs ALL provider SDKs: anthropic, boto3, cohere, google-genai, groq, mistralai, etc. This is ~500MB+ of dependencies you likely don't need.

**Solution**: Use `pydantic-ai-slim[openai]` (or `[anthropic]`, `[groq]`, etc.) to install only the provider(s) you use.

### 5. Python 3.10 vs 3.11+

**Issue**: Langfuse's LangGraph integration has a known issue on Python 3.10 (GitHub Issue linked in Langfuse docs). Some OTel context propagation features require 3.11+.

**Solution**: Use Python ≥3.11. Recommended: 3.12.

### 6. CrewAI ↔ langchain (Tools Only)

**Issue**: CrewAI core is langchain-free. But if you use `crewai-tools` (separate package) with LangChain-wrapped tools (e.g., `langchain_community.utilities.GoogleSerperAPIWrapper`), you'll need `langchain-community` installed.

**Solution**: Use CrewAI's native tools where possible. Only install `langchain-community` if you need specific LangChain tool wrappers.

## Package Variants Cheat Sheet

| Need | Install | Don't Install |
|------|---------|---------------|
| CrewAI agents + memory | `crewai>=1.10.0` | `crewai-tools` (unless you need specific tools) |
| Pydantic AI with OpenAI | `pydantic-ai-slim[openai]` | `pydantic-ai` (pulls all providers) |
| LangGraph orchestration | `langchain>=1.2.0` | `langgraph` separately (bundled in langchain 1.2+) |
| Langfuse core tracing | `langfuse>=3.0.0` | — |
| Langfuse + LangGraph | `langfuse>=3.0.0` + `langchain>=1.2.0` | `langchain-core` alone (won't work) |
| Langfuse + CrewAI OTel | `openinference-instrumentation-crewai` | — |
| LangSmith (alternative) | Built into `langchain-core` | `langfuse` (unless using both) |

## Dependency Audit Command

Verify your environment has compatible versions:

```bash
python -c "
import crewai; print(f'CrewAI: {crewai.__version__}')
import langfuse; print(f'Langfuse: {langfuse.__version__}')
import langchain; print(f'LangChain: {langchain.__version__}')
import langchain_core; print(f'LangChain Core: {langchain_core.__version__}')
import langgraph; print(f'LangGraph: {langgraph.__version__}')
import pydantic; print(f'Pydantic: {pydantic.__version__}')
import opentelemetry.version; print(f'OTel API: {opentelemetry.version.__version__}')
try:
    import pydantic_ai; print(f'Pydantic AI: {pydantic_ai.__version__}')
except: print('Pydantic AI: not installed (using pydantic-ai-slim?)')
"
```
