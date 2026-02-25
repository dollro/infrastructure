# Best-Breed Stock Investment Analyst Skill
## Deep Research: SKILL.md Content, Tool Integration & Architecture Patterns

---

## 1. The Landscape: What Exists Today

I found **5 distinct project families** that attempt to solve this, each with different strengths and weaknesses:

### A. tradermonty/claude-trading-skills → `us-stock-analysis`
**Stars:** 16 | **Architecture:** Modular skill ecosystem (17 skills)

**What they got right:**
- **Reference file library** with separate docs for each analytical dimension: `fundamental-analysis.md`, `technical-analysis.md`, `financial-metrics.md`, `report-template.md`
- **Workflow orchestration** — their README defines multi-skill workflows (daily monitoring, weekly review, individual stock research) that chain skills together
- **Complementary skills** that feed into the main analysis: sector-analyst, breadth-chart-analyst, market-news-analyst, institutional-flow-tracker, options-strategy-advisor, us-market-bubble-detector
- **API integration** (FMP API + Finviz) baked into the skill with `scripts/` helper Python files

**What they got wrong / missing:**
- No weighted scoring system — the analysis is qualitative prose, not systematized
- No chance/risk matrix or probability-weighted scenarios in the core us-stock-analysis skill
- No explicit MCP server integration instructions in SKILL.md
- The skills are fragmented — you need to run 4-5 separate skills manually to get a complete picture

### B. quant-sentiment-ai/claude-equity-research
**Stars:** 152 | **Architecture:** Single Claude Code plugin/command

**What they got right:**
- **Goldman Sachs-style output format** with executive summary, fundamental analysis, catalyst analysis, valuation, risk assessment, technical context
- **Bull/Base/Bear scenarios** with probability weighting (e.g., 25%/55%/20%)
- **Position sizing guidance** (1-5%) and stop-loss levels
- **Enhanced intelligence** sections: options flow analysis, insider activity monitoring, sector positioning, ESG
- Clean command interface: `/trading-ideas AAPL`

**What they got wrong / missing:**
- It's a Claude Code plugin, NOT a claude.ai skill — different format
- **No scoring system** — the recommendation is generated purely from LLM reasoning, not a structured rubric
- **No MCP integration** — relies entirely on web search for data
- **No reference files** — all the intelligence is in a single `trading-ideas.md` command prompt
- No structured data gathering step — it's basically a giant prompt that says "search and analyze"

### C. OctagonAI/skills → `financial-analyst-master`
**Stars:** 7 | **Architecture:** MCP-dependent skill collection (50+ skills)

**What they got right:**
- **Granular decomposition** — separate skills for every single financial analysis task (income-statement, balance-sheet, cash-flow, each growth metric, each SEC filing type, each earnings transcript dimension)
- **Master orchestrator** skills that chain the granular skills together
- **Structured MCP tool calls** — each skill knows exactly which Octagon MCP tool to call with which parameters
- **Real API data** rather than web-scraped data

**What they got wrong / missing:**
- **Completely dependent on Octagon MCP** — useless without it
- **No analytical framework** — the skills fetch data but don't provide scoring rubrics or investment judgment
- **No chance/risk assessment** — it's a data retrieval system, not an analyst
- Each skill is tiny (just a few lines) — the intelligence is in the MCP server, not the skill

### D. Anthropic Official: Claude for Financial Services Skills
**Not publicly available** (Enterprise waitlist only)

**What they describe:**
- Earnings Update Reports (8-12 pages, beat/miss analysis, updated estimates)
- Coverage Initiation (full research reports with investment recommendations)
- Three-Statement Modeling (IS/BS/CF with DCF, comps, sensitivity)
- Comp Tables (peer benchmarking with valuation multiples)
- Competitive Landscape Assessment

**Key insight:** These are the gold standard but **proprietary and inaccessible**. They reportedly use Daloopa (financial data for 3,500+ companies) as a connector.

### E. jimmysjournal.substack.com (5 Best Prompts for Stock Analysis)
**Not a skill** — but the best public prompt engineering for stock analysis

**Key prompts documented:**
1. **Priming prompt** — persona definition as senior equity research analyst
2. **Financial deep-dive** — structured IS/BS/CF analysis with ratio calculations  
3. **Competitive moat analysis** — Porter's Five Forces + moat classification
4. **Risk mapping** — categorized risks with probability, impact, early-warning indicators
5. **Forward-looking perspective** — 3-5yr positioning considering macro trends

**Key insight:** This is the closest to a "best-breed" analytical framework that actually gets good results, but it's 5 separate prompts rather than one integrated skill.

---

## 2. The Gap: What Nobody Has Built Yet

No existing skill combines ALL of these:

| Capability | tradermonty | quant-sentiment | OctagonAI | Jimmy's Journal | **Your Skill** |
|---|---|---|---|---|---|
| Structured persona | ✅ | ✅ | ❌ | ✅ | ✅ |
| MCP data integration | ❌ (FMP script) | ❌ | ✅ (Octagon only) | ❌ | ✅ (Yahoo Finance MCP) |
| Web search fallback | Partial | ✅ | ❌ | ✅ | ✅ |
| Weighted scoring rubric | ❌ | ❌ | ❌ | ❌ | ✅ |
| Reference file library | ✅ (4 files) | ❌ | ❌ | ❌ | ✅ |
| Chance/risk matrix | ❌ | Partial | ❌ | Partial | ✅ |
| DCF / valuation models | ❌ | Partial | ❌ | ❌ | ✅ |
| Bull/base/bear scenarios | ❌ | ✅ | ❌ | ❌ | ✅ |
| Investment recommendation | ❌ | ✅ | ❌ | ❌ | ✅ |
| Report template | ✅ | ✅ (format) | ❌ | ❌ | ✅ |
| Multiple modes | ❌ | ✅ (--detailed) | ❌ | N/A | ✅ |

---

## 3. Best-Breed SKILL.md Architecture

Based on analysis of all projects, here's what makes a SKILL.md great:

### 3.1 Critical Success Factors (from comparative analysis)

**1. The persona must encode JUDGMENT, not just process**
- Bad: "You are a financial analyst. Analyze the stock."
- Good: "You are a senior equity research analyst with 15+ years experience. You've covered 200+ companies across cycles. You know that growth only creates value when ROIC > WACC. You're skeptical of management guidance by default. You look for the second-order effects that consensus misses."
- Your VC skill does this extremely well — the stock skill should mirror this quality.

**2. The scoring rubric is the core differentiator**
- None of the open-source skills have a real scoring system
- Your VC skill's 35-criteria, 8-chapter scoring framework is uniquely powerful
- The stock skill needs an equivalent: criteria + definitions + scoring bands + red flags
- **This is what separates a "pretty report" from an "actionable investment decision"**

**3. Reference files must be operational, not theoretical**
- Bad: A reference file that lists "things to look at"
- Good: A reference file that says "For revenue growth: pull 3yr CAGR from MCP. If >20% = score 5. If 10-20% = score 4. If 0-10% = score 3. If declining but profitable = score 2. If declining and burning cash = score 1. Red flag: revenue recognition changes in last 2 years."
- The tradermonty and your VC skill both use this "analyst checklist" pattern effectively.

**4. Tool integration instructions must be EXPLICIT in SKILL.md**
- Tell Claude exactly which MCP tool to call, with which parameters, in which order
- This is what OctagonAI does well (but for their own MCP only)
- Your skill needs to map: "For financial statements → call `get_financial_statement` with ticker + `income_stmt` / `balance_sheet` / `cashflow`"

**5. The workflow must be sequential and gated**
- Don't let Claude jump to conclusions before gathering data
- Step 1: Gather ALL data (MCP calls + web search) — output raw data
- Step 2: Analyze and score — systematic, criteria by criteria
- Step 3: Synthesize — connect the dots, form the thesis
- Step 4: Generate report — using the template

### 3.2 Your Yahoo Finance MCP Server — Tool Mapping

Your `dollro/yahoo-finance-mcp-server` (fork of laxmimerit) provides these 9 tools:

```
┌─────────────────────────────────────────────────────────────────┐
│  YOUR MCP SERVER TOOLS → ANALYSIS MAPPING                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  get_stock_info(ticker)                                         │
│  → Company overview, current price, market cap, PE, EPS,        │
│    sector, industry, forward PE, dividend yield                 │
│  → USED IN: Section 1 (Overview), Section 4 (Valuation)        │
│                                                                 │
│  get_financial_statement(ticker, financial_type)                 │
│  → income_stmt / quarterly_income_stmt                          │
│  → balance_sheet / quarterly_balance_sheet                      │
│  → cashflow / quarterly_cashflow                                │
│  → USED IN: Section 3 (Financial Analysis) — THE CORE          │
│                                                                 │
│  get_historical_stock_prices(ticker, period, interval)          │
│  → Price history for trend analysis, volatility, drawdowns      │
│  → USED IN: Section 4 (Valuation - historical range),          │
│             Section 7 (Risk - volatility metrics)               │
│                                                                 │
│  get_yahoo_finance_news(ticker)                                 │
│  → Recent news articles for sentiment analysis                  │
│  → USED IN: Section 2 (Recent Developments), Section 6 (Catalysts) │
│                                                                 │
│  get_recommendations(ticker, "recommendations" | "upgrades_..") │
│  → Analyst consensus, upgrades/downgrades history               │
│  → USED IN: Section 4 (Valuation - analyst targets),           │
│             Section 8 (Decision - consensus check)              │
│                                                                 │
│  get_holder_info(ticker, holder_type)                           │
│  → Institutional holders, insider transactions, mutual funds    │
│  → USED IN: Section 5 (Moat - institutional conviction),       │
│             Section 7 (Risk - insider selling patterns)         │
│                                                                 │
│  get_stock_actions(ticker)                                      │
│  → Dividends, stock splits history                              │
│  → USED IN: Section 3 (Shareholder returns)                    │
│                                                                 │
│  get_option_chain(ticker, date, type) +                         │
│  get_option_expiration_dates(ticker)                            │
│  → Options data for implied volatility, put/call ratio          │
│  → USED IN: Section 7 (Risk - implied vol as forward risk),    │
│             Section 6 (Catalysts - unusual options activity)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 What Web Search Must Fill

Your MCP gives you company-level data. Web search fills the gaps:

| Gap | Search Query Pattern | Used In |
|---|---|---|
| Peer/competitor identification | `"[company] competitors market share 2025"` | Moat analysis, peer comps |
| Sector/industry multiples | `"[sector] average PE EV/EBITDA 2025"` | Valuation benchmarking |
| Macro risks | `"[sector] regulatory risk 2025"`, `"interest rate impact [sector]"` | Risk assessment |
| Recent analyst reports | `"[ticker] analyst price target upgrade downgrade"` | Valuation, consensus |
| Management quality | `"[CEO name] track record capital allocation"` | Qualitative assessment |
| TAM/SAM sizing | `"[market] total addressable market size 2025"` | Growth opportunity |
| SEC risk factors | `"[ticker] 10-K risk factors 2024"` or fetch from SEC EDGAR | Risk taxonomy |
| Earnings transcript insights | `"[ticker] earnings call Q[X] 2025 guidance"` | Forward-looking analysis |

### 3.4 Optional: Python Helper Scripts

The tradermonty approach of bundling helper scripts is powerful. Consider:

**`scripts/financial_ratios.py`** — Calculate derived metrics from raw MCP data:
- ROIC, WACC estimate, FCF yield, Altman Z-score, Piotroski F-score
- 3yr / 5yr CAGR for revenue, earnings, FCF
- Margin trend analysis (expanding/contracting)
- Debt-to-equity, interest coverage, current ratio

**`scripts/valuation_model.py`** — Simple DCF calculator:
- Takes FCF, growth rate, discount rate, terminal growth
- Outputs intrinsic value under bull/base/bear assumptions
- Can be called from the SKILL.md workflow

**`scripts/peer_comparison.py`** — Multi-ticker comparison:
- Pull same MCP data for 3-5 peers
- Output comparison table with key metrics

These scripts can be invoked by Claude during analysis via bash tool, making the skill much more capable.

---

## 4. Recommended SKILL.md Structure

```
stock-investment-analyst/
├── SKILL.md                              # ~250-300 lines
├── references/
│   ├── frameworks.md                     # Scoring framework, IAS calculation
│   ├── scoring-criteria.md               # All criteria with rubrics [1-5]
│   ├── analyst-checklists.md             # "How to assess" operational guides
│   ├── report-template.md               # Complete output template
│   ├── valuation-methods.md             # DCF, comps, historical range
│   └── risk-taxonomy.md                 # Risk categories + early warnings
└── scripts/                              # Optional Python helpers
    ├── financial_ratios.py               # Derived metric calculations
    └── valuation_model.py               # Simple DCF calculator
```

### SKILL.md Core Sections (Best-Breed Synthesis)

```markdown
---
name: stock-investment-analyst
description: "Professional equity research analyst for US-listed stocks.
Generates institutional-grade chance/risk reports with investment
recommendations. Uses Yahoo Finance MCP for live data. ALWAYS trigger
when: analyzing a stock, generating a stock report, evaluating an
investment, comparing stocks, assessing stock risk, performing equity
research, or when a ticker symbol is mentioned with analysis intent.
Trigger keywords: stock analysis, equity research, investment report,
chance/risk, buy/sell/hold, price target, valuation, DCF, peer comps."
---

# Stock Investment Analyst

## Persona (from Jimmy's Journal + your VC pattern)
Senior equity research analyst, 15+ years sell-side and buy-side.
Covered 200+ companies across market cycles. Skeptical by nature.
Knows that growth only matters when ROIC > WACC. Looks for what
consensus is missing. Writes in analytical prose, not bullet catalogs.

## Tone & Style (from your VC skill pattern)
Professional, objective, concise, high-signal. Standard finance
terminology used naturally. Paragraphs that weave numbers, context,
and judgment. Tables for scoring summaries and financial data.
Goal: a report a portfolio manager reads in 15 min with clear conviction.

## Reference Files (your VC skill pattern — table format)
| File | When to Read | Content |
| frameworks.md | ALWAYS | Scoring framework, IAS calc, sector benchmarks |
| scoring-criteria.md | Full Analysis | All criteria: definitions, rubrics, red flags |
| analyst-checklists.md | Full Analysis | Operational "how to assess" for each criterion |
| report-template.md | When producing report | Full output template |
| valuation-methods.md | Valuation deep-dive | DCF, comps, historical range methods |
| risk-taxonomy.md | Risk analysis | Risk categories, early-warning indicators |

## MCP Tool Integration (EXPLICIT — from OctagonAI pattern)
Yahoo Finance MCP server provides these tools. Call them in this order:

### Step 1: Core Data Pull (always)
1. get_stock_info(ticker) → overview, price, sector, key metrics
2. get_financial_statement(ticker, "income_stmt") → annual P&L
3. get_financial_statement(ticker, "quarterly_income_stmt") → recent quarters
4. get_financial_statement(ticker, "balance_sheet") → assets, liabilities
5. get_financial_statement(ticker, "cashflow") → cash generation
6. get_historical_stock_prices(ticker, "1y", "1d") → 1yr daily prices
7. get_recommendations(ticker, "recommendations") → analyst consensus

### Step 2: Extended Data (full analysis mode)
8. get_financial_statement(ticker, "quarterly_balance_sheet")
9. get_financial_statement(ticker, "quarterly_cashflow")
10. get_historical_stock_prices(ticker, "5y", "1wk") → 5yr trend
11. get_holder_info(ticker, "institutional_holders")
12. get_holder_info(ticker, "insider_transactions")
13. get_yahoo_finance_news(ticker) → recent news
14. get_recommendations(ticker, "upgrades_downgrades")
15. get_stock_actions(ticker) → dividends, splits
16. get_option_expiration_dates(ticker) → check options liquidity

### Step 3: Web Search (fill gaps MCP can't provide)
- Search for peer companies and sector multiples
- Search for recent analyst reports and price targets
- Search for macro/regulatory context
- Search for management track record / recent statements
- Fetch SEC 10-K risk factors section if needed

## Modes (from your VC skill pattern)
### Full Analysis (default) → Read all reference files
### Quick Take → Read frameworks.md only
### Chance/Risk Focus → Read risk-taxonomy.md + scoring-criteria.md
### Valuation Deep-Dive → Read valuation-methods.md
### Peer Comparison → Read frameworks.md + scoring-criteria.md

## Workflow (from your VC skill — sequential, gated)
Step 1: GATHER — Call all MCP tools, run web searches
Step 2: CALCULATE — Derive ratios, growth rates, margins
Step 3: SCORE — Apply rubric to each criterion [1-5]
Step 4: SYNTHESIZE — Form thesis, chance/risk matrix
Step 5: OUTPUT — Generate report per template

## Scoring System
[25 criteria across 6 chapters, weighted composite → IAS 1-100]
[Maps to: Strong Buy / Buy / Hold / Underweight / Sell]

## Output Mandates
- Always include disclaimer
- Always show scoring summary table
- Always include "what would change the thesis" section
- Bull/base/bear scenarios with probability weights
- Price target range (not a single number)
```

---

## 5. Key Design Decisions

### 5.1 Fewer, Deeper Criteria vs. Many Shallow Ones

| Approach | OctagonAI (50+ skills) | tradermonty (4 ref files) | **Recommended** |
|---|---|---|---|
| Criteria count | ~100 data points | ~20 qualitative | **25 scored criteria** |
| Scoring | None | None | **Quantitative [1-5] with rubric** |
| Integration | Fragmented | Manual orchestration | **Single skill, single workflow** |

**Recommendation:** 25 criteria is the sweet spot — enough depth for rigor, few enough that Claude can reason through them all in one pass without losing coherence. Your VC skill has 35, which works because VC due diligence has more dimensions. Stock analysis is more standardized.

### 5.2 Single-Skill vs. Multi-Skill Ecosystem

tradermonty uses 17 separate skills. Octagon uses 50+. Both require the user to manually orchestrate.

**Recommendation:** Build ONE comprehensive skill that internally orchestrates. The SKILL.md should tell Claude to call MCP tools in sequence, then analyze, then output. The user says "analyze AAPL" and gets a complete report. No manual chaining.

If you later want sector analysis, macro briefing, or options strategy — those can be separate skills. But the core investment analysis should be self-contained.

### 5.3 MCP-First vs. Web-Search-First

| Strategy | Pros | Cons |
|---|---|---|
| MCP-first (your Yahoo Finance) | Structured data, reliable, parseable | Limited to what yfinance provides |
| Web-search-first | Broader data (analyst targets, qualitative) | Unstructured, may be stale |
| **Hybrid (recommended)** | Best of both | More complex workflow |

**Recommendation:** MCP for all quantitative data (financials, prices, holders, recommendations). Web search for qualitative context (news, management, macro, peers, sector multiples, SEC risk factors). This is what your SKILL.md workflow should encode.

### 5.4 Report Format

| Format | When to Use |
|---|---|
| **Markdown artifact** | Default — renders beautifully in claude.ai |
| **PDF via pdf skill** | When user says "create a report" or "PDF" |
| **React artifact** | When user wants interactive (expandable sections, charts) |
| **docx via docx skill** | When user needs to share/edit externally |

---

## 6. Concrete Next Steps

1. **I build the SKILL.md** following the architecture above, modeled on your VC skill structure, integrating your Yahoo Finance MCP tools explicitly

2. **I build the reference files:**
   - `frameworks.md` — 6-chapter scoring framework with IAS calculation formula
   - `scoring-criteria.md` — All 25 criteria with definitions, [1-5] rubrics, red flags
   - `analyst-checklists.md` — Operational "how to assess" for each criterion using MCP + web search
   - `report-template.md` — Complete output template (executive summary through appendix)
   - `valuation-methods.md` — DCF methodology, comps approach, historical range
   - `risk-taxonomy.md` — Risk categories, probability/impact framework, monitoring triggers

3. **Optional: Python helper scripts** for derived calculations (ratios, simple DCF)

4. **Test it** on 2-3 tickers (e.g., AAPL, NVDA, a value stock like JNJ) to calibrate scoring bands

The unique value proposition: **the only open-source stock analysis skill that combines structured MCP data retrieval with a quantitative scoring rubric and a professional chance/risk framework** — essentially bringing your VC skill's rigor to public equity analysis.
