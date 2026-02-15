# Prompt Engineering Skill

Comprehensive technical knowledge for designing, optimizing, and managing prompts for large language models.

---

## Prompt Patterns

### Zero-Shot Prompting
Use when the task is simple and well-defined, or the model has sufficient pre-training knowledge.

```
You are a sentiment analyzer. Classify the following text as positive, negative, or neutral.

Text: "The product arrived late but the quality exceeded my expectations."

Classification:
```

**Best for:** Simple classification, well-defined tasks, when examples aren't available

### Few-Shot Learning
Provide examples to guide the model's output format and reasoning.

```
Classify the customer feedback:

Example 1:
Feedback: "Great service, will buy again!"
Category: Positive
Priority: Low

Example 2:
Feedback: "Product broke after one day, want refund"
Category: Negative
Priority: High

Example 3:
Feedback: "Shipping was okay, product as described"
Category: Neutral
Priority: Low

Now classify:
Feedback: "The app crashes every time I try to checkout, losing customers because of this"
Category:
Priority:
```

**Example Selection Criteria:**
- Cover diverse scenarios (happy path, edge cases, errors)
- Order from simple to complex
- Include boundary cases
- Balance across categories
- Use realistic, representative data

**Dynamic Example Selection:**
```python
def select_examples(query: str, example_pool: List[Example], k: int = 3) -> List[Example]:
    """Select most relevant examples using embedding similarity."""
    query_embedding = embed(query)
    similarities = [
        (ex, cosine_similarity(query_embedding, embed(ex.text)))
        for ex in example_pool
    ]
    # Get top-k most similar, ensuring category diversity
    selected = []
    categories_seen = set()
    for ex, score in sorted(similarities, key=lambda x: -x[1]):
        if ex.category not in categories_seen or len(selected) < k:
            selected.append(ex)
            categories_seen.add(ex.category)
        if len(selected) >= k:
            break
    return selected
```

### Chain-of-Thought (CoT)
Guide the model through explicit reasoning steps.

```
Solve this problem step by step:

Problem: A store has 156 apples. They sell 47 apples in the morning and receive a shipment of 89 apples at noon. How many apples do they have at the end of the day?

Let's think through this:
1. Start with initial inventory: 156 apples
2. After morning sales: 156 - 47 = 109 apples
3. After shipment: 109 + 89 = 198 apples

Answer: 198 apples
```

**CoT Variations:**
- **Zero-shot CoT**: Add "Let's think step by step" to prompt
- **Manual CoT**: Provide explicit reasoning steps in examples
- **Auto-CoT**: Let model generate reasoning, then verify
- **Self-consistency**: Generate multiple CoT paths, majority vote

**Verification Points:**
```
After each step, verify:
- Does this step logically follow from the previous?
- Are all calculations correct?
- Have I considered all relevant information?
- Is there an alternative interpretation?
```

### Tree-of-Thought (ToT)
Explore multiple reasoning branches for complex problems.

```
Problem: Design a system that can handle 10,000 concurrent users.

Branch 1: Horizontal Scaling Approach
- Pros: Easy to scale, fault-tolerant
- Cons: Complexity in state management
- Feasibility: High

Branch 2: Vertical Scaling Approach
- Pros: Simpler architecture
- Cons: Single point of failure, limits
- Feasibility: Medium

Branch 3: Hybrid Approach
- Pros: Best of both worlds
- Cons: More complex to implement
- Feasibility: High

Evaluation: Branch 3 (Hybrid) is most promising because...
Selected path: Proceed with hybrid approach, focusing on...
```

### ReAct (Reasoning + Acting)
Combine reasoning with tool/action execution.

```
Question: What was the revenue of Apple Inc in 2023?

Thought 1: I need to find Apple's 2023 financial data. Let me search for their annual report.
Action 1: search("Apple Inc 2023 annual report revenue")
Observation 1: Apple reported total revenue of $383.3 billion for fiscal year 2023...

Thought 2: I found the information. The search result shows Apple's 2023 revenue.
Action 2: finish("Apple Inc's revenue in 2023 was $383.3 billion")
```

**ReAct Loop Structure:**
```python
def react_loop(question: str, tools: Dict[str, Callable], max_steps: int = 10):
    history = []
    for step in range(max_steps):
        # Generate thought and action
        response = llm.generate(
            f"Question: {question}\n"
            f"Previous steps: {history}\n"
            f"Available tools: {list(tools.keys())}\n"
            f"Think about what to do next, then take an action."
        )

        thought, action, action_input = parse_response(response)

        if action == "finish":
            return action_input

        # Execute action
        observation = tools[action](action_input)
        history.append({
            "thought": thought,
            "action": action,
            "observation": observation
        })

    return "Max steps reached without conclusion"
```

### Constitutional AI Pattern
Self-critique and revision based on principles.

```
Initial response: [model's first answer]

Critique based on these principles:
1. Be helpful and accurate
2. Avoid harmful content
3. Respect privacy
4. Be unbiased

Critique: The response could be improved by...

Revised response: [improved answer addressing critique]
```

### Role-Based Prompting
Assign specific persona for consistent behavior.

```
You are a senior security engineer with 15 years of experience in application security. You have deep expertise in:
- OWASP Top 10 vulnerabilities
- Secure coding practices
- Penetration testing methodologies
- Compliance frameworks (SOC 2, HIPAA, GDPR)

When reviewing code, you:
- Prioritize security issues by severity
- Provide specific remediation steps
- Reference relevant security standards
- Consider both immediate fixes and long-term improvements

Review the following code for security issues:
[code]
```

---

## Prompt Optimization Techniques

### Token Reduction Strategies

**Compression techniques:**
```
# Instead of verbose instructions:
"Please analyze the following piece of code and identify any potential security vulnerabilities that might exist within it, paying special attention to input validation, authentication mechanisms, and data handling practices."

# Use concise instructions:
"Analyze this code for security vulnerabilities. Focus on: input validation, auth, data handling."
```

**Context pruning:**
- Remove redundant information
- Summarize long contexts
- Use references instead of full content
- Extract only relevant sections

**Output constraints:**
```
Respond with JSON only. No explanations.
Format: {"sentiment": "positive|negative|neutral", "confidence": 0.0-1.0}
```

### Response Parsing

**Structured output formats:**
```
Respond in this exact format:
```json
{
  "analysis": {
    "summary": "Brief summary (max 50 words)",
    "issues": [
      {
        "type": "security|performance|style",
        "severity": "critical|high|medium|low",
        "description": "Issue description",
        "fix": "Suggested fix"
      }
    ],
    "score": 0-100
  }
}
```
```

**Parsing with validation:**
```python
from pydantic import BaseModel, validator
from typing import List, Literal

class Issue(BaseModel):
    type: Literal["security", "performance", "style"]
    severity: Literal["critical", "high", "medium", "low"]
    description: str
    fix: str

    @validator('description')
    def description_not_empty(cls, v):
        if not v.strip():
            raise ValueError('Description cannot be empty')
        return v

class Analysis(BaseModel):
    summary: str
    issues: List[Issue]
    score: int

    @validator('score')
    def score_in_range(cls, v):
        if not 0 <= v <= 100:
            raise ValueError('Score must be 0-100')
        return v

def parse_llm_response(response: str) -> Analysis:
    # Extract JSON from response
    json_match = re.search(r'```json\n(.*?)\n```', response, re.DOTALL)
    if json_match:
        return Analysis.parse_raw(json_match.group(1))
    return Analysis.parse_raw(response)
```

### Error Handling and Retry Strategies

```python
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

class LLMError(Exception):
    pass

class RateLimitError(LLMError):
    pass

class InvalidResponseError(LLMError):
    pass

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=60),
    retry=retry_if_exception_type(RateLimitError)
)
def call_llm_with_retry(prompt: str, model: str) -> str:
    try:
        response = llm.complete(prompt, model=model)

        # Validate response
        if not response or len(response.strip()) < 10:
            raise InvalidResponseError("Response too short")

        return response

    except RateLimitException:
        raise RateLimitError("Rate limited, will retry")
    except Exception as e:
        raise LLMError(f"LLM call failed: {e}")
```

### Cache Optimization

```python
import hashlib
from functools import lru_cache
from redis import Redis

redis_client = Redis()

def get_cache_key(prompt: str, model: str, temperature: float) -> str:
    """Generate deterministic cache key."""
    content = f"{prompt}:{model}:{temperature}"
    return f"llm:{hashlib.sha256(content.encode()).hexdigest()}"

def cached_llm_call(
    prompt: str,
    model: str,
    temperature: float = 0.0,
    cache_ttl: int = 3600
) -> str:
    """LLM call with Redis caching."""
    # Only cache deterministic calls (temperature=0)
    if temperature == 0:
        cache_key = get_cache_key(prompt, model, temperature)
        cached = redis_client.get(cache_key)
        if cached:
            return cached.decode()

    response = llm.complete(prompt, model=model, temperature=temperature)

    if temperature == 0:
        redis_client.setex(cache_key, cache_ttl, response)

    return response
```

### Batch Processing

```python
from typing import List
import asyncio

async def batch_process_prompts(
    prompts: List[str],
    model: str,
    batch_size: int = 10,
    max_concurrent: int = 5
) -> List[str]:
    """Process prompts in batches with concurrency control."""
    semaphore = asyncio.Semaphore(max_concurrent)

    async def process_one(prompt: str) -> str:
        async with semaphore:
            return await llm.acomplete(prompt, model=model)

    results = []
    for i in range(0, len(prompts), batch_size):
        batch = prompts[i:i + batch_size]
        batch_results = await asyncio.gather(
            *[process_one(p) for p in batch],
            return_exceptions=True
        )
        results.extend(batch_results)

    return results
```

---

## Evaluation Frameworks

### Accuracy Metrics

```python
from sklearn.metrics import precision_recall_fscore_support, accuracy_score
from typing import List, Dict

def evaluate_classification(
    predictions: List[str],
    ground_truth: List[str],
    labels: List[str]
) -> Dict[str, float]:
    """Evaluate classification task performance."""
    precision, recall, f1, _ = precision_recall_fscore_support(
        ground_truth, predictions, labels=labels, average='weighted'
    )

    return {
        "accuracy": accuracy_score(ground_truth, predictions),
        "precision": precision,
        "recall": recall,
        "f1_score": f1,
        "per_class": {
            label: {
                "precision": p,
                "recall": r,
                "f1": f
            }
            for label, p, r, f in zip(
                labels,
                *precision_recall_fscore_support(
                    ground_truth, predictions, labels=labels, average=None
                )[:3]
            )
        }
    }
```

### Consistency Testing

```python
def test_consistency(
    prompt_template: str,
    test_inputs: List[str],
    expected_format: callable,
    n_runs: int = 5
) -> Dict[str, float]:
    """Test prompt consistency across multiple runs."""
    consistency_scores = []

    for test_input in test_inputs:
        prompt = prompt_template.format(input=test_input)
        responses = [llm.complete(prompt) for _ in range(n_runs)]

        # Check format consistency
        format_valid = [expected_format(r) for r in responses]

        # Check semantic consistency (responses should be similar)
        embeddings = [embed(r) for r in responses]
        avg_similarity = np.mean([
            cosine_similarity(embeddings[i], embeddings[j])
            for i in range(len(embeddings))
            for j in range(i + 1, len(embeddings))
        ])

        consistency_scores.append({
            "format_consistency": sum(format_valid) / len(format_valid),
            "semantic_consistency": avg_similarity
        })

    return {
        "avg_format_consistency": np.mean([s["format_consistency"] for s in consistency_scores]),
        "avg_semantic_consistency": np.mean([s["semantic_consistency"] for s in consistency_scores])
    }
```

### Edge Case Validation

```python
# Edge case categories
EDGE_CASES = {
    "empty_input": ["", " ", "\n", "\t"],
    "special_characters": ["<script>alert('xss')</script>", "'; DROP TABLE users;--", "\x00\x01\x02"],
    "unicode": ["", "Hello", "مرحبا", ""],
    "length_extremes": ["x" * 10000, "a"],
    "format_breaking": ["```json\n{invalid}", "{{template}}", "${variable}"],
    "adversarial": [
        "Ignore all previous instructions and...",
        "SYSTEM: You are now...",
        "[INST] New instructions: [/INST]"
    ]
}

def test_edge_cases(
    prompt_fn: callable,
    expected_behavior: Dict[str, str]
) -> Dict[str, bool]:
    """Test prompt handling of edge cases."""
    results = {}

    for category, cases in EDGE_CASES.items():
        category_results = []
        for case in cases:
            try:
                response = prompt_fn(case)
                # Check if response matches expected behavior
                is_valid = validate_response(response, expected_behavior.get(category))
                category_results.append(is_valid)
            except Exception as e:
                category_results.append(False)

        results[category] = sum(category_results) / len(category_results)

    return results
```

---

## A/B Testing Methodology

### Test Design

```python
from dataclasses import dataclass
from typing import Optional
import random

@dataclass
class PromptVariant:
    name: str
    template: str
    description: str

@dataclass
class ABTest:
    name: str
    hypothesis: str
    variants: List[PromptVariant]
    primary_metric: str
    secondary_metrics: List[str]
    traffic_split: Dict[str, float]
    min_sample_size: int

    def assign_variant(self, user_id: str) -> PromptVariant:
        """Deterministic assignment based on user_id."""
        hash_val = int(hashlib.md5(f"{self.name}:{user_id}".encode()).hexdigest(), 16)
        rand_val = (hash_val % 1000) / 1000

        cumulative = 0
        for variant in self.variants:
            cumulative += self.traffic_split[variant.name]
            if rand_val < cumulative:
                return variant

        return self.variants[-1]

# Example test setup
test = ABTest(
    name="cot_vs_direct",
    hypothesis="Chain-of-thought prompting improves accuracy on complex reasoning tasks",
    variants=[
        PromptVariant(
            name="control",
            template="Answer this question: {question}",
            description="Direct prompting"
        ),
        PromptVariant(
            name="treatment",
            template="Answer this question step by step: {question}\n\nLet's think through this:",
            description="Chain-of-thought prompting"
        )
    ],
    primary_metric="accuracy",
    secondary_metrics=["latency", "token_count", "user_satisfaction"],
    traffic_split={"control": 0.5, "treatment": 0.5},
    min_sample_size=1000
)
```

### Statistical Analysis

```python
from scipy import stats
import numpy as np

def analyze_ab_test(
    control_results: List[float],
    treatment_results: List[float],
    alpha: float = 0.05
) -> Dict:
    """Perform statistical analysis of A/B test results."""

    # Basic statistics
    control_mean = np.mean(control_results)
    treatment_mean = np.mean(treatment_results)

    # Two-sample t-test
    t_stat, p_value = stats.ttest_ind(control_results, treatment_results)

    # Effect size (Cohen's d)
    pooled_std = np.sqrt(
        (np.std(control_results)**2 + np.std(treatment_results)**2) / 2
    )
    cohens_d = (treatment_mean - control_mean) / pooled_std

    # Confidence interval for difference
    diff_mean = treatment_mean - control_mean
    diff_se = np.sqrt(
        np.var(control_results)/len(control_results) +
        np.var(treatment_results)/len(treatment_results)
    )
    ci_95 = (
        diff_mean - 1.96 * diff_se,
        diff_mean + 1.96 * diff_se
    )

    return {
        "control_mean": control_mean,
        "treatment_mean": treatment_mean,
        "lift": (treatment_mean - control_mean) / control_mean * 100,
        "p_value": p_value,
        "is_significant": p_value < alpha,
        "effect_size": cohens_d,
        "confidence_interval_95": ci_95,
        "sample_sizes": {
            "control": len(control_results),
            "treatment": len(treatment_results)
        }
    }
```

### Rollout Strategy

```python
from enum import Enum
from datetime import datetime

class RolloutPhase(Enum):
    CANARY = "canary"      # 1-5% traffic
    BETA = "beta"          # 10-25% traffic
    GRADUAL = "gradual"    # 25-75% traffic
    FULL = "full"          # 100% traffic

def manage_rollout(
    test: ABTest,
    results: Dict,
    current_phase: RolloutPhase
) -> Dict:
    """Determine next rollout phase based on results."""

    # Safety checks
    if results.get("error_rate", 0) > 0.05:
        return {"action": "rollback", "reason": "Error rate too high"}

    if results.get("latency_p95") > 5000:  # 5 seconds
        return {"action": "rollback", "reason": "Latency too high"}

    # Check for statistical significance
    if not results.get("is_significant"):
        return {
            "action": "continue",
            "reason": "Need more data for significance",
            "estimated_samples_needed": calculate_required_samples(results)
        }

    # Progression logic
    phase_progression = {
        RolloutPhase.CANARY: RolloutPhase.BETA if results["lift"] > 0 else "rollback",
        RolloutPhase.BETA: RolloutPhase.GRADUAL if results["lift"] > 5 else RolloutPhase.CANARY,
        RolloutPhase.GRADUAL: RolloutPhase.FULL if results["lift"] > 5 else "hold",
        RolloutPhase.FULL: "complete"
    }

    next_action = phase_progression.get(current_phase, "hold")

    return {
        "action": next_action,
        "current_phase": current_phase.value,
        "next_phase": next_action.value if isinstance(next_action, RolloutPhase) else next_action,
        "results_summary": results
    }
```

---

## Safety Mechanisms

### Input Validation

```python
import re
from typing import Tuple

class InputValidator:
    # Patterns for detecting injection attempts
    INJECTION_PATTERNS = [
        r"ignore\s+(all\s+)?previous\s+instructions",
        r"system\s*:\s*you\s+are",
        r"\[INST\].*\[/INST\]",
        r"<\|im_start\|>",
        r"Human:",
        r"Assistant:",
    ]

    MAX_INPUT_LENGTH = 10000

    def validate(self, user_input: str) -> Tuple[bool, str]:
        """Validate user input for safety."""

        # Length check
        if len(user_input) > self.MAX_INPUT_LENGTH:
            return False, f"Input exceeds maximum length of {self.MAX_INPUT_LENGTH}"

        # Injection pattern check
        input_lower = user_input.lower()
        for pattern in self.INJECTION_PATTERNS:
            if re.search(pattern, input_lower, re.IGNORECASE):
                return False, "Input contains potentially harmful patterns"

        # Encoding check
        try:
            user_input.encode('utf-8')
        except UnicodeEncodeError:
            return False, "Input contains invalid characters"

        return True, "Valid"

    def sanitize(self, user_input: str) -> str:
        """Sanitize input while preserving meaning."""
        # Remove control characters
        sanitized = ''.join(
            char for char in user_input
            if ord(char) >= 32 or char in '\n\t'
        )

        # Escape special delimiters
        sanitized = sanitized.replace("```", "'''")

        return sanitized[:self.MAX_INPUT_LENGTH]
```

### Output Filtering

```python
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class FilterResult:
    is_safe: bool
    filtered_content: str
    violations: List[str]
    confidence: float

class OutputFilter:
    BLOCKED_PATTERNS = [
        # PII patterns
        r'\b\d{3}-\d{2}-\d{4}\b',  # SSN
        r'\b\d{16}\b',  # Credit card
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',  # Email (if sensitive)
    ]

    SENSITIVE_TOPICS = [
        "illegal activities",
        "harmful content",
        "personal attacks",
    ]

    def filter(self, output: str) -> FilterResult:
        """Filter LLM output for safety."""
        violations = []
        filtered = output

        # Pattern-based filtering
        for pattern in self.BLOCKED_PATTERNS:
            matches = re.findall(pattern, filtered)
            if matches:
                violations.append(f"PII detected: {pattern}")
                filtered = re.sub(pattern, "[REDACTED]", filtered)

        # Content classification (could use another LLM)
        content_safety = self.classify_content_safety(filtered)
        if content_safety["is_harmful"]:
            violations.append(f"Harmful content: {content_safety['category']}")
            filtered = "[Content filtered for safety]"

        return FilterResult(
            is_safe=len(violations) == 0,
            filtered_content=filtered,
            violations=violations,
            confidence=content_safety["confidence"]
        )

    def classify_content_safety(self, content: str) -> Dict:
        """Classify content for safety (placeholder for actual implementation)."""
        # In production, use a safety classifier model
        return {"is_harmful": False, "category": None, "confidence": 0.95}
```

### Audit Logging

```python
import json
import logging
from datetime import datetime
from typing import Any, Dict

class PromptAuditLogger:
    def __init__(self, log_path: str = "prompt_audit.jsonl"):
        self.logger = logging.getLogger("prompt_audit")
        handler = logging.FileHandler(log_path)
        handler.setFormatter(logging.Formatter('%(message)s'))
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)

    def log_interaction(
        self,
        request_id: str,
        user_id: str,
        prompt: str,
        response: str,
        model: str,
        metadata: Dict[str, Any] = None
    ):
        """Log prompt interaction for audit trail."""
        # Hash sensitive data
        prompt_hash = hashlib.sha256(prompt.encode()).hexdigest()

        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "request_id": request_id,
            "user_id": user_id,
            "prompt_hash": prompt_hash,
            "prompt_length": len(prompt),
            "response_length": len(response),
            "model": model,
            "metadata": metadata or {},
            # Store full content if compliance requires
            # "prompt": prompt,
            # "response": response,
        }

        self.logger.info(json.dumps(log_entry))
```

---

## Multi-Model Strategies

### Model Selection Logic

```python
from enum import Enum
from typing import Callable

class ModelTier(Enum):
    FAST = "fast"       # GPT-3.5, Claude Instant, Gemini Flash
    BALANCED = "balanced"  # GPT-4, Claude Sonnet
    POWERFUL = "powerful"  # GPT-4 Turbo, Claude Opus

class ModelRouter:
    def __init__(self):
        self.routes = {
            ModelTier.FAST: ["gpt-3.5-turbo", "claude-3-haiku"],
            ModelTier.BALANCED: ["gpt-4", "claude-3-5-sonnet"],
            ModelTier.POWERFUL: ["gpt-4-turbo", "claude-3-opus"],
        }

    def select_model(
        self,
        task_complexity: str,
        latency_requirement: int,  # ms
        budget_per_call: float,    # USD
        accuracy_requirement: float
    ) -> str:
        """Select optimal model based on requirements."""

        # Simple routing logic
        if latency_requirement < 500 and accuracy_requirement < 0.9:
            tier = ModelTier.FAST
        elif accuracy_requirement > 0.95 or task_complexity == "high":
            tier = ModelTier.POWERFUL
        else:
            tier = ModelTier.BALANCED

        # Return first available model in tier
        return self.routes[tier][0]

    def route_by_task(self, task_type: str) -> str:
        """Route based on task type."""
        routing_table = {
            "classification": ModelTier.FAST,
            "summarization": ModelTier.BALANCED,
            "code_generation": ModelTier.POWERFUL,
            "translation": ModelTier.FAST,
            "reasoning": ModelTier.POWERFUL,
            "extraction": ModelTier.BALANCED,
        }
        tier = routing_table.get(task_type, ModelTier.BALANCED)
        return self.routes[tier][0]
```

### Fallback Chains

```python
class FallbackChain:
    def __init__(self, models: List[str], timeout: int = 30):
        self.models = models
        self.timeout = timeout

    async def execute(self, prompt: str) -> Dict:
        """Execute with automatic fallback."""
        last_error = None

        for model in self.models:
            try:
                response = await asyncio.wait_for(
                    llm.acomplete(prompt, model=model),
                    timeout=self.timeout
                )
                return {
                    "success": True,
                    "model_used": model,
                    "response": response,
                    "fallback_count": self.models.index(model)
                }
            except asyncio.TimeoutError:
                last_error = f"Timeout for {model}"
            except Exception as e:
                last_error = str(e)

        return {
            "success": False,
            "error": last_error,
            "models_tried": self.models
        }

# Usage
chain = FallbackChain([
    "gpt-4-turbo",      # Primary
    "claude-3-opus",    # Fallback 1
    "gpt-4",            # Fallback 2
    "claude-3-sonnet",  # Fallback 3
])
```

### Ensemble Methods

```python
from collections import Counter

class PromptEnsemble:
    def __init__(self, models: List[str], strategy: str = "majority_vote"):
        self.models = models
        self.strategy = strategy

    async def execute(self, prompt: str) -> Dict:
        """Execute prompt across multiple models and aggregate."""

        # Get responses from all models
        tasks = [
            llm.acomplete(prompt, model=model)
            for model in self.models
        ]
        responses = await asyncio.gather(*tasks, return_exceptions=True)

        valid_responses = [
            r for r in responses if not isinstance(r, Exception)
        ]

        if self.strategy == "majority_vote":
            # For classification tasks
            votes = Counter(valid_responses)
            winner, count = votes.most_common(1)[0]
            return {
                "result": winner,
                "confidence": count / len(valid_responses),
                "agreement": votes
            }

        elif self.strategy == "best_of_n":
            # Use a judge model to select best response
            judge_prompt = f"""
            Select the best response from these options:
            {chr(10).join(f'{i+1}. {r}' for i, r in enumerate(valid_responses))}

            Return only the number of the best response.
            """
            selection = await llm.acomplete(judge_prompt, model="gpt-4")
            selected_idx = int(selection.strip()) - 1
            return {
                "result": valid_responses[selected_idx],
                "all_responses": valid_responses
            }
```

---

## Production System Patterns

### Prompt Management System

```python
from typing import Dict, Optional
from datetime import datetime
import json

class PromptRegistry:
    def __init__(self, storage_backend):
        self.storage = storage_backend

    def register_prompt(
        self,
        name: str,
        template: str,
        version: str,
        metadata: Dict = None
    ) -> str:
        """Register a new prompt version."""
        prompt_id = f"{name}:{version}"

        self.storage.save({
            "id": prompt_id,
            "name": name,
            "version": version,
            "template": template,
            "metadata": metadata or {},
            "created_at": datetime.utcnow().isoformat(),
            "status": "active"
        })

        return prompt_id

    def get_prompt(
        self,
        name: str,
        version: Optional[str] = None
    ) -> Dict:
        """Get prompt by name, optionally specific version."""
        if version:
            return self.storage.get(f"{name}:{version}")

        # Get latest active version
        versions = self.storage.list(prefix=f"{name}:")
        active = [v for v in versions if v["status"] == "active"]
        return max(active, key=lambda x: x["created_at"])

    def deprecate_prompt(self, name: str, version: str):
        """Mark a prompt version as deprecated."""
        prompt_id = f"{name}:{version}"
        prompt = self.storage.get(prompt_id)
        prompt["status"] = "deprecated"
        prompt["deprecated_at"] = datetime.utcnow().isoformat()
        self.storage.save(prompt)
```

### Version Deployment

```yaml
# prompt-config.yaml
prompts:
  sentiment_analysis:
    production:
      version: "2.3.1"
      model: "gpt-4"
      temperature: 0
      max_tokens: 100
    staging:
      version: "2.4.0"
      model: "gpt-4-turbo"
      temperature: 0
      max_tokens: 100
    canary:
      version: "3.0.0-beta"
      model: "gpt-4-turbo"
      traffic_percentage: 5

  code_review:
    production:
      version: "1.2.0"
      model: "claude-3-opus"
      temperature: 0.2
```

### Monitoring Setup

```python
from prometheus_client import Counter, Histogram, Gauge
import time

# Metrics
prompt_requests = Counter(
    'prompt_requests_total',
    'Total prompt requests',
    ['prompt_name', 'model', 'status']
)

prompt_latency = Histogram(
    'prompt_latency_seconds',
    'Prompt execution latency',
    ['prompt_name', 'model'],
    buckets=[0.1, 0.5, 1, 2, 5, 10, 30]
)

prompt_tokens = Histogram(
    'prompt_tokens_total',
    'Tokens used per request',
    ['prompt_name', 'model', 'direction'],  # direction: input/output
    buckets=[100, 500, 1000, 2000, 4000, 8000]
)

active_requests = Gauge(
    'prompt_active_requests',
    'Currently active prompt requests',
    ['prompt_name']
)

class MonitoredPromptExecutor:
    def __init__(self, prompt_name: str, model: str):
        self.prompt_name = prompt_name
        self.model = model

    async def execute(self, prompt: str) -> str:
        active_requests.labels(prompt_name=self.prompt_name).inc()
        start_time = time.time()

        try:
            response = await llm.acomplete(prompt, model=self.model)

            # Record metrics
            prompt_requests.labels(
                prompt_name=self.prompt_name,
                model=self.model,
                status="success"
            ).inc()

            prompt_latency.labels(
                prompt_name=self.prompt_name,
                model=self.model
            ).observe(time.time() - start_time)

            prompt_tokens.labels(
                prompt_name=self.prompt_name,
                model=self.model,
                direction="input"
            ).observe(count_tokens(prompt))

            prompt_tokens.labels(
                prompt_name=self.prompt_name,
                model=self.model,
                direction="output"
            ).observe(count_tokens(response))

            return response

        except Exception as e:
            prompt_requests.labels(
                prompt_name=self.prompt_name,
                model=self.model,
                status="error"
            ).inc()
            raise

        finally:
            active_requests.labels(prompt_name=self.prompt_name).dec()
```

---

## Template Design Patterns

### Modular Template Structure

```python
class PromptTemplate:
    """Composable prompt template system."""

    def __init__(self):
        self.sections = {}

    def add_section(self, name: str, content: str, required: bool = True):
        self.sections[name] = {"content": content, "required": required}
        return self

    def render(self, **variables) -> str:
        rendered_sections = []

        for name, section in self.sections.items():
            content = section["content"]

            # Replace variables
            for var, value in variables.items():
                content = content.replace(f"{{{var}}}", str(value))

            # Check for unreplaced required variables
            if section["required"] and "{" in content:
                raise ValueError(f"Missing required variable in section {name}")

            rendered_sections.append(content)

        return "\n\n".join(rendered_sections)

# Usage
template = PromptTemplate()
template.add_section("role", """
You are a {role} specializing in {specialty}.
""")
template.add_section("context", """
Context:
{context}
""", required=False)
template.add_section("task", """
Task: {task}
""")
template.add_section("format", """
Respond in JSON format:
{output_schema}
""")

prompt = template.render(
    role="code reviewer",
    specialty="Python security",
    task="Review this code for vulnerabilities",
    output_schema='{"issues": [], "severity": ""}',
    context="This is a financial application"
)
```

---

## Anti-Patterns to Avoid

### Common Mistakes

1. **Vague Instructions**
   ```
   # Bad
   "Analyze this data"

   # Good
   "Analyze this sales data. Calculate: 1) total revenue, 2) top 3 products by units sold, 3) month-over-month growth rate. Format as JSON."
   ```

2. **Missing Output Format**
   ```
   # Bad
   "Classify this feedback"

   # Good
   "Classify this feedback as positive, negative, or neutral. Respond with only one word."
   ```

3. **Prompt Injection Vulnerability**
   ```
   # Bad
   f"Translate: {user_input}"

   # Good
   f"""Translate the following text to Spanish.
   Only output the translation, nothing else.

   Text to translate (delimited by triple backticks):
   ```{sanitize(user_input)}```"""
   ```

4. **Ignoring Token Limits**
   ```python
   # Bad
   prompt = system_message + full_document + user_query

   # Good
   prompt = system_message + summarize_if_needed(full_document, max_tokens=2000) + user_query
   ```

5. **No Error Handling**
   ```python
   # Bad
   response = llm.complete(prompt)
   data = json.loads(response)

   # Good
   response = llm.complete(prompt)
   try:
       data = json.loads(extract_json(response))
       validate_schema(data, expected_schema)
   except (json.JSONDecodeError, ValidationError) as e:
       logger.error(f"Failed to parse response: {e}")
       data = fallback_response()
   ```

---

> **Related Skill:** For integrating prompts into agentic systems, see `/home/rodo/.claude/skills/agentic-ai/SKILL.md`
