# Professional Stock Investment Analyst Skill for Claude
## Research Report: Architecture, Tools & MCP Server Ecosystem

---

## Executive Summary

Building a professional-grade stock chance/risk analysis skill for Claude requires combining three layers: **(1)** a well-structured SKILL.md with analyst frameworks, **(2)** real-time financial data via MCP servers, and **(3)** web search + document creation capabilities for the final report output. The research below maps the full landscape and recommends an optimal architecture.

---

## 1. MCP Server Landscape for Financial Data

### Tier 1: Best-in-Class (Recommended Stack)

| MCP Server | Data Coverage | API Key? | Best For |
|---|---|---|---|
| **Octagon MCP** (`octagon-mcp`) | SEC filings (8K+ companies), 10yr earnings transcripts, financial metrics/ratios, stock data (10K+ tickers), 13F holdings, private markets | Yes (free tier) | **All-in-one investment research** — orchestrates multiple specialized agents |
| **SEC EDGAR MCP** (`sec-edgar-mcp`) | 10-K, 10-Q, 8-K, XBRL financials, insider trading (Form 4), company facts | No (free SEC API) | **Primary source financials** — exact numeric precision from XBRL |
| **Yahoo Finance MCP** (`mcp-yahoo-finance`) | Real-time prices, historical data, company info, financial statements, options, earnings, news | No (no auth) | **Quick market data** — zero setup, ideal for price/valuation snapshot |

### Tier 2: Complementary / Specialized

| MCP Server | Data Coverage | API Key? | Best For |
|---|---|---|---|
| **Alpha Vantage MCP** | Stocks, options, forex, crypto, commodities, 50+ technical indicators (RSI, MACD, SMA, Bollinger) | Yes (free tier) | **Technical analysis** — richest indicator library |
| **Financial Datasets MCP** | Income statements, balance sheets, cash flow, stock prices, market news | Yes | **Clean fundamental data** with millisecond latency |
| **Financial Modeling Prep (FMP)** | Fundamentals, DCF valuations, ratios, ETF composition, peer comparisons | Yes | **Valuation models** — includes DCF and comps data |
| **Finnhub MCP** | Market news, stock quotes, financials, analyst recommendations, earnings surprises | Yes (free tier) | **Sentiment & analyst consensus** |

### Tier 3: Specialized Add-ons

| MCP Server | Use Case |
|---|---|
| **Alpaca MCP** | Paper trading, position tracking, brokerage-grade real-time data |
| **Bright Data Yahoo Finance** | Enterprise-grade scraping with CAPTCHA bypass (paid) |
| **EdgarTools (Python lib)** | AI-native SEC analysis with MCP server built-in, 3,450+ lines of API docs |

### Recommendation for Your Skill

**Primary stack:** Octagon MCP + Yahoo Finance MCP + Claude's built-in web search

- **Octagon** handles the heavy lifting: SEC filings, earnings transcripts, financial metrics, institutional holdings, and deep research — all via a single MCP endpoint
- **Yahoo Finance** provides the real-time price snapshot, historical prices, and quick fundamental data without any API key
- **Web search** fills gaps: analyst price targets, recent news sentiment, macro context, competitor developments

**Why not SEC EDGAR directly?** Octagon already wraps SEC EDGAR data with additional intelligence layers. Only add raw SEC EDGAR MCP if you need exact XBRL-parsed numbers for financial modeling.

**Why not Alpha Vantage?** Add it only if the skill needs deep technical analysis (RSI, MACD, Bollinger Bands). For a fundamental chance/risk report, it's optional.

---

## 2. Existing Skills & Plugins in the Ecosystem

### Anthropic Official: Claude for Financial Services Skills
- **Earnings Update Reports** — 8-12 page quarterly analysis with beat/miss, updated estimates
- **Coverage Initiation** — full research reports with investment recommendations and valuation
- **Three-Statement Modeling** — integrated IS/BS/CF with DCF, comps, sensitivity
- **Comp Tables** — peer benchmarking with valuation multiples
- **Competitive Landscape** — market positioning and strategic assessment
- ⚠️ These are **Enterprise-only** (waitlist) and not available as user skills

### Open Source: Notable Projects

| Project | Platform | Description |
|---|---|---|
| **OctagonAI/skills** | Claude Code / Skills.sh | Collection of financial analyst skills including `financial-analyst-master` that orchestrates income statement, balance sheet, cash flow, growth analysis, earnings transcript analysis, and stock quotes |
| **quant-sentiment-ai/claude-equity-research** | Claude Code Plugin | Goldman Sachs-style equity research: executive summary, fundamental analysis, technical analysis, options flow, insider activity, ESG, bull/base/bear scenarios with price targets |
| **tradermonty/claude-trading-skills** | Claude Code / Skills.sh | Technical analysis skill for chart pattern recognition with probabilistic scenarios |
| **mcpmarket.com Investment Analysis** | MCP Market | Fundamental analysis and intrinsic valuation skill |

### Your Existing: vc-investment-analyst
Your VC skill is an excellent structural template. The stock analyst skill should follow the same architecture pattern:
- Persona + tone definition
- Reference files table (frameworks, scoring, checklists, templates)
- Multiple modes (Full Analysis, Quick Take, Deep-Dive)
- Structured workflow (Gather → Analyze → Score → Synthesize → Output)

---

## 3. Recommended Skill Architecture

### SKILL.md Structure

```
/mnt/skills/user/stock-investment-analyst/
├── SKILL.md                          # Main skill definition
└── references/
    ├── frameworks.md                 # Analysis frameworks (see below)
    ├── scoring-criteria.md           # Chance/risk scoring rubric
    ├── report-template.md            # Output template for the report
    ├── valuation-methods.md          # DCF, comps, precedent, sum-of-parts
    ├── risk-taxonomy.md              # Risk categories and early-warning indicators
    └── sector-benchmarks.md          # Key metrics by sector (margins, growth, multiples)
```

### Core Analysis Frameworks (for `frameworks.md`)

**1. Fundamental Quality Score (40% weight)**
- Revenue growth trajectory (3yr CAGR, acceleration/deceleration)
- Margin profile (gross, operating, net, FCF) vs. peers
- ROIC vs. WACC spread (value creation test)
- Balance sheet health (debt/equity, interest coverage, current ratio)
- Cash flow quality (OCF/Net Income, capex intensity, FCF conversion)
- Earnings quality (accruals ratio, revenue recognition flags)

**2. Valuation Assessment (20% weight)**
- P/E (trailing + forward), PEG ratio
- EV/EBITDA, EV/Revenue (for growth companies)
- DCF intrinsic value estimate (bull/base/bear)
- Peer multiple comparison (premium/discount analysis)
- Historical valuation range (where are we in the cycle?)

**3. Competitive Position & Moat (15% weight)**
- Porter's Five Forces assessment
- Moat type classification (network effects, switching costs, intangibles, cost advantages, scale)
- Market share trend
- Customer concentration risk
- Pricing power evidence

**4. Growth Catalysts & Opportunity (10% weight)**
- TAM/SAM/SOM sizing
- Product pipeline / innovation trajectory
- Geographic expansion opportunities
- M&A optionality
- Secular tailwinds

**5. Risk Assessment (15% weight)**
- Macro/cyclical exposure
- Regulatory/legal risk
- Technology disruption risk
- Key person / management risk
- Financial risk (leverage, liquidity, covenant)
- ESG / governance flags
- Concentration risk (customer, supplier, geographic)

### Scoring System

Each criterion scored 1-5:
| Score | Label | Meaning |
|---|---|---|
| 5 | Exceptional | Top-decile, significant competitive advantage |
| 4 | Strong | Above-average, clear positive signal |
| 3 | Adequate | In-line with expectations, neutral |
| 2 | Concerning | Below expectations, material risk |
| 1 | Critical | Significant red flag, potential deal-breaker |

**Aggregate scoring:**
- Weighted composite → **Investment Attractiveness Score (IAS)** on 1-100 scale
- IAS 80-100 → Strong Buy | 65-79 → Buy | 50-64 → Hold | 35-49 → Underweight | <35 → Sell

### Report Output Structure

```
1. EXECUTIVE SUMMARY
   - Ticker, Price, Market Cap, Sector
   - Investment Thesis (2-3 sentences)
   - Recommendation: [Strong Buy / Buy / Hold / Underweight / Sell]
   - Price Target (12-month) with bull/base/bear scenarios
   - IAS Score with radar chart

2. COMPANY OVERVIEW
   - Business model, revenue segments, geographic mix
   - Management quality assessment
   - Recent developments & catalysts

3. FINANCIAL ANALYSIS
   - Income statement trends (3-5yr)
   - Balance sheet health
   - Cash flow analysis
   - Unit economics / key operating metrics
   - Comparison to peers table

4. VALUATION
   - Multiple analysis (P/E, EV/EBITDA, EV/Revenue)
   - DCF model summary (key assumptions, sensitivity)
   - Historical valuation context
   - Peer valuation comparison
   - Fair value range estimation

5. COMPETITIVE POSITION & MOAT
   - Industry dynamics
   - Moat assessment
   - Market share and positioning

6. CHANCE ASSESSMENT (Bull Case)
   - Growth catalysts with probability weighting
   - Upside scenarios with quantified impact
   - Strategic optionality

7. RISK ASSESSMENT (Bear Case)
   - Risk matrix (probability × impact)
   - Stress test scenarios
   - Early-warning indicators to monitor
   - Downside scenarios with quantified impact

8. INVESTMENT DECISION
   - Chance/Risk ratio summary
   - Scoring summary table (all criteria)
   - Final recommendation with conviction level
   - Key monitoring triggers (what would change the thesis)
   - Position sizing guidance (based on conviction)

APPENDIX
   - Data sources and methodology notes
   - Disclaimer (not financial advice)
```

### Modes

| Mode | Trigger | Output |
|---|---|---|
| **Full Analysis** | "analyze [TICKER]", "investment report on [TICKER]" | Complete 15-20 page report with all 8 sections |
| **Quick Take** | "quick take on [TICKER]", "what do you think of [TICKER]" | 3-5 paragraph summary with key thesis, biggest risk, preliminary score |
| **Chance/Risk Focus** | "chance/risk for [TICKER]", "risk analysis [TICKER]" | Focused sections 6-7 with risk matrix and scenario analysis |
| **Valuation Deep-Dive** | "value [TICKER]", "is [TICKER] overvalued" | Focused section 4 with full DCF, comps, and historical context |
| **Peer Comparison** | "compare [TICKER1] vs [TICKER2]" | Side-by-side analysis with scoring deltas |

### Workflow (Full Analysis Mode)

```
Step 1: DATA GATHERING
  ├── MCP: Octagon → financial metrics, SEC filings, earnings transcripts, 13F holdings
  ├── MCP: Yahoo Finance → current price, historical prices, company info, news
  ├── Web Search → analyst consensus, recent news, macro context, competitors
  └── User Uploads → any provided documents (10-K, earnings deck, etc.)

Step 2: FUNDAMENTAL ANALYSIS
  ├── Parse financial statements (IS, BS, CF) for 3-5 years
  ├── Calculate key ratios and growth rates
  ├── Compare to sector benchmarks
  └── Identify trends, inflections, anomalies

Step 3: VALUATION
  ├── Pull peer multiples
  ├── Build simplified DCF (conservative/base/optimistic)
  ├── Historical valuation range analysis
  └── Determine fair value range

Step 4: QUALITATIVE ASSESSMENT
  ├── Moat analysis from competitive data
  ├── Management quality from earnings transcripts
  ├── Growth catalysts from recent filings/news
  └── Risk identification from 10-K risk factors + external research

Step 5: SCORING & SYNTHESIS
  ├── Score each criterion (1-5)
  ├── Calculate weighted IAS
  ├── Map to recommendation
  └── Build chance/risk matrix

Step 6: REPORT GENERATION
  ├── Generate professional report (docx or PDF via skill)
  ├── Include data tables, scoring summaries
  ├── Add disclaimer
  └── Output to user
```

---

## 4. MCP Server Configuration

For Claude Desktop / Claude Code, the config would look like:

```json
{
  "mcpServers": {
    "octagon": {
      "command": "npx",
      "args": ["-y", "octagon-mcp@latest"],
      "env": {
        "OCTAGON_API_KEY": "YOUR_KEY"
      }
    },
    "yahoo-finance": {
      "command": "uvx",
      "args": ["mcp-yahoo-finance"]
    },
    "sec-edgar": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "-e",
        "SEC_EDGAR_USER_AGENT=Your Name (email@example.com)",
        "stefanoamorelli/sec-edgar-mcp:latest"
      ]
    },
    "alpha-vantage": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-alphavantage"],
      "env": {
        "ALPHA_VANTAGE_API_KEY": "YOUR_KEY"
      }
    }
  }
}
```

For **Claude.ai** (consumer interface, your current environment):
- Use the **Anthropic API within artifacts** to call MCP servers via the inner API
- Use **web search** as the primary data source (already available)
- Use **web_fetch** to pull data from Yahoo Finance, Finviz, SEC EDGAR directly
- Build the analysis using Claude's built-in reasoning + structured frameworks from the skill

---

## 5. Implementation Strategy

### Phase 1: Core Skill (works in claude.ai today)
Build the SKILL.md with full analyst frameworks, scoring rubrics, and report template. Use web search + web_fetch as primary data sources. This gives you 80% of the value immediately.

**Data sources via web search/fetch:**
- Yahoo Finance pages → price, fundamentals, financial statements
- SEC EDGAR full-text search → 10-K, 10-Q filings
- Finviz → screening data, analyst targets, technical snapshot
- Macrotrends.net → historical financials
- Seeking Alpha / analyst coverage → consensus estimates

### Phase 2: MCP Integration (Claude Desktop / Claude Code)
Add Octagon MCP + Yahoo Finance MCP for structured data retrieval. This upgrades data quality from "web-scraped" to "API-grade."

### Phase 3: Output Polish
Integrate with docx/pdf/pptx skills for professional output formatting. Generate downloadable reports with charts and tables.

### Phase 4: Artifact Mode
Build a React artifact that displays the analysis interactively — with tabs for each section, expandable risk matrices, and an IAS radar chart.

---

## 6. Key Differentiators vs. Existing Solutions

| Feature | Octagon Skills | quant-sentiment-ai | **Your Custom Skill** |
|---|---|---|---|
| Chance/Risk Matrix | ❌ | Partial (bull/base/bear) | ✅ Full probability × impact matrix |
| Weighted Scoring System | ❌ | ❌ | ✅ 35+ criteria, weighted IAS score |
| Investment Recommendation | ❌ | ✅ Buy/Sell/Hold | ✅ 5-tier with conviction level |
| DCF Valuation | ❌ | ❌ | ✅ Simplified 3-scenario DCF |
| Earnings Transcript Analysis | ✅ (via MCP) | ❌ | ✅ (via MCP or web search) |
| SEC Filings Deep-Dive | ✅ (via MCP) | ❌ | ✅ (via MCP or web fetch) |
| European Context | ❌ | ❌ | ✅ (dual US/EU perspective) |
| Professional Report Output | ❌ | Markdown only | ✅ docx/PDF via skill integration |
| Monitoring Triggers | ❌ | ❌ | ✅ "What would change the thesis" |

---

## 7. Disclaimer Framework

Every report must include:

> **DISCLAIMER:** This analysis is generated by an AI system for educational and informational purposes only. It does not constitute financial advice, a recommendation to buy or sell securities, or an offer to transact. All data is sourced from public sources and may contain errors. Past performance does not guarantee future results. Always consult a qualified financial advisor before making investment decisions. The author/system assumes no liability for investment decisions made based on this analysis.

---

## Next Steps

1. **Decide scope:** Full skill creation now, or iterative build?
2. **Choose data strategy:** Web search only (Phase 1) or MCP integration (Phase 2)?
3. **Choose output format:** Markdown artifact, docx, PDF, or interactive React?
4. **I can build the complete SKILL.md + reference files** following your VC analyst skill pattern, ready to drop into `/mnt/skills/user/`

*Research completed February 16, 2026*
