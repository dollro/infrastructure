# Risk Taxonomy & Early Warning System — Equity Research Scorecard v1.0

> Comprehensive risk assessment framework. Covers risk identification, probability/severity scoring, stress testing, and monitoring triggers.

---

## Table of Contents
1. [Risk Category Framework](#1-risk-category-framework)
2. [Early Warning Indicators](#2-early-warning-indicators)
3. [Stress Test Scenarios](#3-stress-test-scenarios)
4. [Monitoring Triggers](#4-monitoring-triggers)
5. [Risk-Adjusted Position Sizing](#5-risk-adjusted-position-sizing)

---

## 1. Risk Category Framework

### Category A: Business & Competitive Risk

| Risk | Description | What to Look For | Severity If Realized |
|---|---|---|---|
| **Moat Erosion** | Competitive advantages weakening | Market share loss, pricing pressure, margin compression, new well-funded entrants | High — structural value destruction |
| **Disruption** | Technology or business model substitution | Emerging alternatives gaining traction, customer migration signals, declining NPS | Very High — potential existential |
| **Customer Concentration** | Revenue dependence on few customers | Top customer > 10% revenue, contract renewal dates, customer financial health | High — revenue cliff risk |
| **Product Concentration** | Revenue dependence on single product | Single product > 60% revenue, product lifecycle stage, replacement pipeline | Medium to High |
| **Pricing Power Loss** | Inability to maintain/raise prices | Gross margin erosion in inflationary environment, customer pushback, competitive undercutting | High — permanent margin reset |
| **Management Execution** | Failure to deliver on strategy | Guidance misses, delayed product launches, failed integration, leadership turnover | Medium — recoverable if addressed |

### Category B: Financial Risk

| Risk | Description | What to Look For | Severity If Realized |
|---|---|---|---|
| **Leverage / Debt** | Excessive debt burden | Net debt/EBITDA > sector "Weak" threshold, covenant proximity, rising interest expense, ratings downgrade | Very High — solvency risk |
| **Liquidity** | Insufficient cash to meet obligations | Declining cash balances, negative operating CF, maturity wall, revolver draw | Very High — immediate |
| **Earnings Quality** | Reported earnings overstating reality | GAAP/non-GAAP divergence growing, accruals rising, FCF conversion declining, DSO increasing | High — trust destruction |
| **Currency** | Adverse FX movements | High international revenue without natural hedges, emerging market currencies, margin sensitivity to FX | Medium — can be hedged |
| **Working Capital** | Cash trapped in receivables/inventory | DSO rising, inventory build without revenue growth, days payable stretching (supplier strain) | Medium — cash flow drag |

### Category C: Macro & External Risk

| Risk | Description | What to Look For | Severity If Realized |
|---|---|---|---|
| **Recession / Cyclical** | Economic downturn impact | High beta, discretionary product, B2B spend correlated to GDP, customer budget sensitivity | Medium to High — sector-dependent |
| **Interest Rate** | Rate changes impacting valuation or business | High leverage, rate-sensitive revenue (housing, auto), long-duration asset with high P/E | Medium — repricing risk |
| **Inflation** | Input cost increases not passable | Rising COGS faster than revenue, commodity input exposure, wage inflation in labor-intensive business | Medium — margin compression |
| **Geopolitical** | Trade war, sanctions, regional instability | Revenue concentration in geopolitically sensitive regions, supply chain through conflict zones | Medium to High — varies by exposure |
| **Pandemic / Black Swan** | Low-probability, high-impact events | No specific leading indicator — focus on resilience: balance sheet strength, business model flexibility, digital capability | Very High — by definition |

### Category D: Regulatory & Legal Risk

| Risk | Description | What to Look For | Severity If Realized |
|---|---|---|---|
| **Regulatory Change** | New regulations impacting business model | Proposed legislation, regulatory commentary, industry lobbying activity, political sentiment shift | High — can permanently alter economics |
| **Antitrust** | Government action against market power | Market share concentration, DOJ/FTC investigations, European Commission scrutiny, political rhetoric | High — forced structural changes |
| **Litigation** | Material lawsuit exposure | Pending lawsuits, class action filings, product liability, patent disputes, settlement history | Variable — depends on exposure |
| **Tax** | Adverse tax policy changes | Proposed tax legislation, international tax reform (OECD BEPS), effective tax rate far below statutory | Medium — earnings impact |
| **Data / Privacy** | Data protection enforcement | GDPR/CCPA violations, data breach history, changing privacy regulations, consent requirements | Medium to High — fines + trust |

### Category E: ESG & Sustainability Risk

| Risk | Description | What to Look For | Severity If Realized |
|---|---|---|---|
| **Climate / Environmental** | Physical or transition climate risk | Carbon-intensive operations, stranded asset risk, disclosure requirements, carbon pricing exposure | Variable — sector-dependent |
| **Social / Labor** | Workforce or community issues | Labor disputes, DEI controversies, supply chain labor conditions, community opposition | Medium — reputational + operational |
| **Governance** | Board and management failures | Dual-class shares, related-party transactions, board not independent, excessive compensation | Medium to High — value extraction |
| **Cybersecurity** | Data breach or systems compromise | Prior incidents, security spending relative to peers, critical infrastructure dependence | High — trust + legal + operational |

---

## 2. Early Warning Indicators

These are leading indicators that often precede material fundamental deterioration. Screen for these in every analysis.

### Financial Early Warnings

| Indicator | Signal | Data Source | Action Level |
|---|---|---|---|
| **Revenue deceleration** | Sequential QoQ growth rate declining for 3+ quarters | Quarterly income statement | Review thesis if growth halves |
| **Gross margin erosion** | Gross margin down > 100 bps YoY for 2+ quarters | Quarterly income statement | Investigate cause immediately |
| **FCF conversion drop** | FCF/Net Income falls below 70% for 2+ quarters | Cash flow statement | Quality concern — investigate |
| **DSO increase** | Days sales outstanding rising > 10% YoY | Balance sheet + revenue | Revenue quality concern |
| **Inventory build** | Inventory growth > revenue growth for 2+ quarters | Balance sheet | Demand weakness or obsolescence |
| **Debt increase** | Net debt/EBITDA deteriorating by > 0.5x in 12 months | Balance sheet | Monitor covenant headroom |
| **SBC acceleration** | Stock-based compensation growing faster than revenue | Cash flow statement | Dilution accelerating |
| **Guidance cut** | Management lowers guidance mid-year | Earnings calls, news | Credibility hit; often understated |
| **CFO departure** | Chief Financial Officer leaves unexpectedly | News, filings | Investigate aggressively — often precedes bad news |
| **Auditor change** | Switch to different audit firm, especially smaller | SEC filings | Significant red flag |

### Competitive Early Warnings

| Indicator | Signal | Data Source | Action Level |
|---|---|---|---|
| **Share loss** | Revenue growth below industry growth rate for 2+ quarters | Web search — industry data | Moat may be narrowing |
| **Pricing pressure** | ASP declining or promotions increasing | Earnings calls, channel checks | Pricing power weakening |
| **New entrant gaining** | Well-funded competitor crossing meaningful adoption threshold | Web search, news | Evaluate threat severity |
| **Key customer churn** | Major customer contract non-renewal or RFP | News, SEC filings | Revenue cliff risk |
| **Patent expiry** | Key patents expiring within 2 years | SEC filings, patent databases | Margin/revenue at risk |

### Management & Governance Early Warnings

| Indicator | Signal | Data Source | Action Level |
|---|---|---|---|
| **Insider selling cluster** | 3+ insiders selling in same month outside of 10b5-1 plans | Insider transaction data (MCP) | Investigate — insiders know more |
| **Board resignations** | Independent director departures | SEC filings, news | Governance concern |
| **CEO distraction** | CEO taking external board seats, media roles, or political appointments | News, proxy filings | Focus dilution |
| **Accounting changes** | Revenue recognition policy change, new non-GAAP metrics, adjustment methodology change | SEC filings | Obfuscation risk |
| **Activist involvement** | Known activist hedge fund takes position | 13D/13F filings, news | Catalyst or distraction |

---

## 3. Stress Test Scenarios

Apply these standardized stress tests to assess downside resilience.

### Scenario 1: Mild Recession (-10% Revenue)
**Assumptions:** Revenue declines 10% from current level. Gross margins compress 200 bps. Operating expenses stay flat (limited variable cost flex). Working capital deteriorates slightly.

**Calculate:**
- Stressed EBITDA = Revenue × 0.90 × (Current margin − 2pp)
- Stressed interest coverage = Stressed EBITDA / Interest expense
- Can the company still service debt? Cover dividend? Maintain investment?
- How many quarters of cash runway at stressed burn rate?

### Scenario 2: Severe Recession (-25% Revenue)
**Assumptions:** Revenue declines 25%. Gross margins compress 500 bps. Company cuts opex by 15% (with lag). Working capital deteriorates meaningfully.

**Calculate:**
- Same as above but more severe
- At what point do covenants trigger?
- Does the company need to raise capital at distressed terms?
- Is the equity value impaired in this scenario?

### Scenario 3: Competitive Disruption (-15% Revenue, Permanent)
**Assumptions:** A competitor captures 15% of the company's revenue permanently. No margin offset possible. Growth rate permanently reduced by 5pp.

**Calculate:**
- Impact on intrinsic value (DCF with permanently lower growth)
- Fair value under disrupted growth scenario vs. current price
- What valuation multiple does the market currently embed? Is it too optimistic?

### Scenario 4: Interest Rate Shock (+200 bps)
**Assumptions:** Interest rates rise 200 bps across the curve. All variable-rate debt reprices immediately. Fixed-rate debt reprices at maturity.

**Calculate:**
- Incremental annual interest expense
- Impact on EPS
- WACC increases → DCF fair value impact
- P/E compression for long-duration assets

### Scenario 5: Regulatory Disruption
**Assumptions:** Adverse regulation implemented. Revenue from affected segment declines 30% over 3 years. Compliance costs increase opex by 5%.

**Calculate:**
- Affected revenue as % of total
- EPS impact under regulatory scenario
- Sum-of-parts: value excluding affected segment vs. current EV

---

## 4. Monitoring Triggers

Define specific thresholds that should trigger a thesis review. Include these in every report.

### Standard Monitoring Framework

| Category | Metric | Positive Trigger (upgrade thesis) | Negative Trigger (downgrade thesis) |
|---|---|---|---|
| **Growth** | Revenue growth QoQ | Acceleration for 2+ quarters | Deceleration for 3+ quarters |
| **Margins** | Operating margin | Expansion > 100 bps sustained | Compression > 150 bps sustained |
| **Cash Flow** | FCF conversion | Sustained > 100% | Drops below 60% |
| **Leverage** | Net debt/EBITDA | Below 1.0x and declining | Above sector "Weak" threshold |
| **Returns** | ROIC | Rising above WACC spread | Falling below WACC |
| **Valuation** | Forward P/E | Moves below 5yr average | Moves above 5yr 90th percentile |
| **Competition** | Market share | Evidence of sustained share gains | Evidence of share loss |
| **Management** | Insider activity | Meaningful open-market buying | Cluster selling outside 10b5-1 |
| **Governance** | Board changes | New independent directors with relevant expertise | Board resignations or activist involvement |

### Thesis-Specific Triggers

In addition to standard triggers, each report should define 2–3 thesis-specific triggers unique to the investment case. Examples:

- "If AWS revenue growth decelerates below 15%, the cloud growth narrative weakens materially."
- "If the FDA rejects the Phase III application, the pipeline value drops by approximately $X billion."
- "If the DOJ files antitrust suit, expect 10–15% multiple compression immediately."

---

## 5. Risk-Adjusted Position Sizing

While position sizing is ultimately the portfolio manager's decision, the research report should provide guidance based on the risk profile.

### Position Size Framework

| IAS Range | Verdict | Suggested Position Size | Rationale |
|---|---|---|---|
| 85–100 | Strong Buy | 3–5% of portfolio | High conviction, exceptional risk/reward |
| 70–84 | Buy | 2–4% of portfolio | Favorable risk/reward |
| 55–69 | Hold | 1–2% of portfolio (if owned) | Neutral — no active position change |
| 40–54 | Underweight | 0–1% of portfolio | Reduce exposure |
| < 40 | Sell | 0% | Exit position |

### Risk-Based Adjustments

Adjust position size downward for:
- High volatility (beta > 1.5): reduce by 20–30%
- Concentration risk (top customer > 20%): reduce by 10–20%
- Leverage concern (net debt/EBITDA above sector average): reduce by 10–20%
- Binary catalyst (FDA decision, lawsuit outcome): reduce by 30–50% OR size for maximum loss
- Low liquidity (ADV < $10M): reduce to ensure exit within 5 trading days

Adjust position size upward for:
- High insider buying: increase by 10–20%
- Fortress balance sheet (net cash): increase by 10–20%
- Counter-cyclical (low beta, recession-resistant): increase by 10–20%
- Multiple converging catalysts: increase by 10–20%

### Stop-Loss Framework

| Verdict | Suggested Stop-Loss | Rationale |
|---|---|---|
| Strong Buy | 20–25% below entry | High conviction — wider stop to avoid noise |
| Buy | 15–20% below entry | Standard — protect against thesis failure |
| Hold | 10–15% below entry | Tighter — limited upside expectation |

**Important:** Stop-losses should be based on thesis invalidation, not arbitrary price levels. If the stock drops 15% because the market sold off but fundamentals are unchanged, that's an opportunity, not a stop-loss trigger. If the stock drops 10% because of a guidance cut that invalidates the thesis, exit regardless of stop level.
