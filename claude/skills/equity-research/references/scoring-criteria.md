# Scoring Criteria Reference — Equity Research Scorecard v1.0

> All criteria scored [1–5]. Score reflects the **weaker** of sub-dimensions assessed. 🚩 = RED FLAG criterion: score of 1 triggers automatic verdict downgrade.

---

## Chapter 1: Fundamental Quality
**Weight:** 35%

### 1.1 — Revenue Growth & Trajectory [1–5] 🚩 RED FLAG

**What it measures:** Top-line growth rate AND whether growth is accelerating, stable, or decelerating. Both magnitude and direction matter.

**Score 5:** Revenue growth significantly above sector corridor "Strong" threshold AND accelerating (sequential quarterly growth rates increasing). Multi-year track record of beating estimates.
**Score 4:** Growth above sector "Strong" threshold, stable trajectory. Consistent beat-and-raise pattern.
**Score 3:** Growth within sector "Adequate" corridor. Stable but not accelerating. Roughly in line with estimates.
**Score 2:** Growth below sector "Adequate" floor OR clear deceleration trend (3+ consecutive quarters of declining growth rate). Missing estimates.
**Score 1:** Revenue declining, stagnant, or growth collapsed to single digits in what should be a growth company. Structural demand problem evident.

**Red flag triggers:** Revenue decline in 2+ consecutive quarters without clear cyclical explanation. Organic growth negative while acquisitions mask decline. Revenue growth far below sector peers.

**Sector calibration:** Apply the Financial Health Corridors from frameworks.md. 5% growth is "Strong" for a utility but "Weak" for SaaS.

**Key calculation:** 
- Revenue CAGR: 1-year and 3-year
- Sequential quarterly growth rates (QoQ)
- Organic vs. acquisition-driven growth (if discernible)

---

### 1.2 — Margin Profile & Trend [1–5] 🚩 RED FLAG

**What it measures:** Current margin levels (gross, operating, net) relative to sector peers AND the direction of margin trends over the past 8–12 quarters.

**Score 5:** Margins at or above sector "Strong" corridor on all levels. Expanding trend evident. Operating leverage improving.
**Score 4:** Margins above sector average. Stable or modestly expanding. Minor pressure in one area compensated by strength elsewhere.
**Score 3:** Margins within sector "Adequate" corridor. Stable. No clear expansion or compression trend.
**Score 2:** Margins below sector average OR compressing on 2+ margin levels. Competitive pressure or cost inflation eroding profitability.
**Score 1:** Margins significantly below peers AND compressing. Gross margin erosion signals pricing power loss. Structural profitability problem.

**Red flag triggers:** Gross margin declining 200+ bps over 4 quarters without investment explanation. Operating margin negative and worsening in a company past early growth stage. Adjusted EBITDA wildly divergent from GAAP operating income (quality concern).

**Key calculation:**
- Gross margin, operating margin, EBITDA margin, net margin — current and 3yr trend
- Quarter-over-quarter margin change (8 quarters)
- Margin relative to top 3 peers

---

### 1.3 — Return on Invested Capital (ROIC) [1–5]

**What it measures:** The company's ability to generate returns above its cost of capital. ROIC > WACC = value creation. This is the single most important long-term indicator.

**Score 5:** ROIC consistently > 2x estimated WACC. Top-quartile for sector. Stable or improving over 3+ years.
**Score 4:** ROIC > 1.5x WACC. Above sector median. Stable.
**Score 3:** ROIC roughly equal to WACC (0.8–1.2x). Meeting cost of capital but not creating excess value.
**Score 2:** ROIC below WACC. Value destruction, but cyclical or temporary factors may explain (recent large capex cycle, acquisition integration).
**Score 1:** ROIC persistently below WACC for 3+ years with no credible path to improvement. Structural value destruction.

**WACC estimation shortcut:**
- Risk-free rate (10yr Treasury) + equity risk premium (5–6%) × beta = cost of equity
- Blend with after-tax cost of debt weighted by capital structure
- For quick calibration: most large-caps WACC falls in 7–11% range

**Key calculation:**
- ROIC = NOPAT / (Total equity + Net debt)
- NOPAT = Operating income × (1 − tax rate)
- Compare to estimated WACC and sector median ROIC

---

### 1.4 — Cash Flow Quality & Conversion [1–5]

**What it measures:** The quality and reliability of cash generation. FCF conversion (FCF/Net Income) reveals whether reported earnings translate to actual cash. High accruals with low cash conversion = earnings quality concern.

**Score 5:** FCF conversion > 100% consistently. FCF growing faster than reported earnings. Low capex intensity relative to sector. Clean working capital dynamics.
**Score 4:** FCF conversion 80–100%. FCF growth in line with earnings growth. Capex at or below sector average.
**Score 3:** FCF conversion 60–80%. Acceptable but with some drag from working capital swings or elevated capex.
**Score 2:** FCF conversion < 60% OR FCF negative despite reported profitability. Large gap between GAAP earnings and cash flow.
**Score 1:** Persistently negative FCF in a mature business. Cash consumption accelerating. Working capital or capex consuming all earnings.

**Key calculation:**
- FCF = Operating cash flow − Capex
- FCF conversion = FCF / Net income
- FCF margin = FCF / Revenue
- FCF yield = FCF / Market cap
- Accrual ratio = (Net income − Operating CF) / Total assets (high = low quality)

---

### 1.5 — Balance Sheet Strength [1–5]

**What it measures:** Financial resilience and ability to withstand stress. Leverage relative to earnings capacity, liquidity position, and debt maturity profile.

**Score 5:** Net cash position or minimal net debt (< 0.5x EBITDA). Strong current ratio (> 2x). No material near-term maturities. Investment-grade credit. Fortress balance sheet.
**Score 4:** Net debt/EBITDA < 1.5x (or below sector "Strong" threshold). Comfortable liquidity. No maturity wall. BBB+ or better.
**Score 3:** Leverage within sector "Adequate" corridor. Liquidity adequate but not abundant. Some near-term maturities manageable through cash flow.
**Score 2:** Leverage approaching sector "Weak" threshold. Tightening liquidity. Upcoming maturities requiring refinancing. Credit quality deteriorating.
**Score 1:** Overleveraged — net debt/EBITDA above sector "Weak" threshold. Liquidity strained. Maturity wall approaching without clear refinancing path. Covenant risk.

**Sector-specific notes:**
- Banks: Use CET1 ratio, not debt/EBITDA
- REITs: Leverage higher by nature; use sector-specific corridors
- Utilities: Regulated utilities tolerate higher leverage (rate base backing)

---

### 1.6 — Earnings Quality & Predictability [1–5]

**What it measures:** How reliable, transparent, and sustainable reported earnings are. Covers accounting quality, earnings volatility, and predictability of the business model.

**Score 5:** Highly predictable revenue model (recurring/subscription). Minimal one-time adjustments. Clean audit history. Beat estimates consistently. Low earnings volatility.
**Score 4:** Mostly predictable with some variability. Reasonable adjustments. Consistent with cash flow. Moderate earnings volatility.
**Score 3:** Adequate transparency. Some lumpiness (project-based revenue, large contracts). Adjustments present but reasonable. Earnings in line with sector volatility.
**Score 2:** Significant adjustments between GAAP and non-GAAP. Restructuring charges recurring. Revenue recognition aggressive. Earnings misses more frequent than beats.
**Score 1:** Opaque financials. Persistent large gap between adjusted and GAAP figures. Frequent restatements. Auditor concerns. Earnings essentially unpredictable.

**Warning signals:**
- Stock-based compensation > 15% of revenue (tech-specific — dilution drag on real earnings)
- Adjusted EBITDA more than 30% above GAAP operating income
- Days sales outstanding (DSO) growing faster than revenue
- Inventory build-up without corresponding revenue growth
- Change in accounting policies or estimates near quarter-end

---

## Chapter 2: Valuation
**Weight:** 20%

### 2.1 — Absolute Valuation [1–5]

**What it measures:** Whether key valuation multiples (P/E, EV/EBITDA, P/FCF, EV/Revenue) are reasonable in the context of the company's growth rate and quality.

**Score 5:** All primary multiples below sector average despite above-average growth and quality. Clear undervaluation on absolute basis. Significant margin of safety.
**Score 4:** Multiples at or slightly below sector average with above-average fundamentals. Reasonable entry point.
**Score 3:** Multiples roughly at sector average with average fundamentals. Fairly priced. PEG ratio 1.0–1.5x.
**Score 2:** Multiples above sector average without superior fundamentals to justify. PEG > 2.0. Limited margin of safety.
**Score 1:** Extreme premium — multiples > 2x sector average. Priced for perfection. Any execution miss will cause significant multiple compression.

**Key multiples (sector-dependent):**
- P/E forward (most sectors)
- EV/EBITDA (industrials, telecom, energy)
- P/FCF (capital-light businesses)
- EV/Revenue (high-growth pre-profit tech)
- P/TBV (banks)
- P/FFO (REITs)

---

### 2.2 — Relative Valuation vs. Peers [1–5]

**What it measures:** Valuation premium/discount relative to closest comparable companies, adjusted for growth and profitability differences.

**Score 5:** Trading at meaningful discount (> 15%) to peer group median despite comparable or superior growth/margins. Market mispricing likely.
**Score 4:** Modest discount (5–15%) to peers with competitive fundamentals. Relative value opportunity.
**Score 3:** In line with peer group (within ±5%). No relative mispricing. Market pricing reflects fundamentals correctly.
**Score 2:** Modest premium (5–20%) vs. peers without clearly superior fundamentals. Premium needs justification.
**Score 1:** Significant premium (> 20%) to peers. Fundamentals do not justify the spread. Valuation convergence risk.

**Implementation:** Identify 3–5 closest publicly traded peers. Compare P/E, EV/EBITDA, and EV/Revenue on forward basis. Adjust for growth (PEG) and margin (EV/EBITDA/margin-adjusted) differentials.

---

### 2.3 — Historical Valuation Range [1–5]

**What it measures:** Where the current valuation sits relative to the company's OWN historical trading range (5-year) and whether the business fundamentals have changed enough to justify deviation.

**Score 5:** Trading below 5-year average multiple by > 1 standard deviation AND fundamentals have NOT deteriorated. Historical reversion opportunity.
**Score 4:** Below 5-year average. Fundamentals stable or improving. Room for multiple normalization.
**Score 3:** Within ±0.5 standard deviations of 5-year average. Historical norm. No mean-reversion signal.
**Score 2:** Above 5-year average by > 0.5 standard deviations without clear fundamental improvement to justify.
**Score 1:** At or above 5-year highs on multiple basis. Extended well beyond historical norm. Mean-reversion risk elevated.

**Caveat:** If the business has structurally changed (e.g., pivoted from hardware to SaaS), historical multiples may not be relevant. Note this and adjust accordingly.

---

### 2.4 — DCF / Intrinsic Value Gap [1–5]

**What it measures:** The gap between current market price and estimated intrinsic value from discounted cash flow analysis. This is the "what is the company really worth" check.

**Score 5:** DCF fair value > 30% above current price under conservative assumptions. Large margin of safety.
**Score 4:** DCF fair value 15–30% above current price. Meaningful upside to intrinsic value.
**Score 3:** DCF fair value within ±15% of current price. Fairly valued by cash flow analysis.
**Score 2:** DCF fair value 15–30% below current price. Market pricing in optimism above what cash flows support.
**Score 1:** DCF fair value > 30% below current price. Severe overvaluation relative to cash flow fundamentals.

**Methodology:** See `references/valuation-methods.md` for full DCF framework. Key: use conservative growth assumptions (below management guidance), realistic terminal growth (2–4%), and appropriate WACC. Sensitivity test across growth and discount rate assumptions.

---

## Chapter 3: Competitive Position & Moat
**Weight:** 15%

### 3.1 — Moat Type & Durability [1–5] 🚩 RED FLAG

**What it measures:** Whether the company possesses a sustainable competitive advantage ("moat") and how durable that moat is over a 5–10 year horizon.

**Score 5:** Multiple reinforcing moat sources (e.g., network effects + switching costs + brand). Moat widening over time. Top competitor would need 5+ years and billions of dollars to replicate.
**Score 4:** Clear single moat source that is durable and well-maintained. Moat stable. Significant barrier to entry.
**Score 3:** Narrow moat — some competitive advantage exists but it's not insurmountable. Cost advantage or moderate switching costs. Moat steady but could erode under sustained competitive attack.
**Score 2:** Minimal moat. Competitive advantages are temporary (first-mover, current technology lead). Erosion underway or expected within 2–3 years.
**Score 1:** No moat. Commodity business. No pricing power, no switching costs, no differentiation. Competes purely on price. Race to bottom.

**Moat taxonomy:**
| Moat Type | Description | Durability Signal |
|---|---|---|
| Network Effects | Value increases with each user | User growth accelerating, multi-sided platform |
| Switching Costs | Painful/expensive to leave | High retention rates, long contracts, deep integration |
| Cost Advantages | Structural cost advantage | Scale-driven, proprietary process, resource access |
| Intangible Assets | Brand, patents, licenses | Pricing power, regulatory barriers, patent portfolio |
| Efficient Scale | Natural monopoly/oligopoly | Limited market size doesn't attract new entrants |

---

### 3.2 — Market Position & Share Trend [1–5]

**What it measures:** Current market share and whether the company is gaining or losing position.

**Score 5:** Market leader (#1 or #2) with share gaining. Outgrowing the market by 2x+. Competitive position strengthening.
**Score 4:** Strong market position (top 3). Share stable or modestly gaining. Growing in line with or slightly above market.
**Score 3:** Mid-tier position. Share stable. Neither gaining nor losing material ground.
**Score 2:** Market position weakening. Share losses evident over 2+ years. Growing below market rate.
**Score 1:** Peripheral player with declining share. Losing relevance. Competitors eating into core business.

---

### 3.3 — Pricing Power [1–5]

**What it measures:** The ability to raise prices without losing customers. This is the most reliable indicator of competitive strength.

**Score 5:** Consistent history of above-inflation price increases with minimal churn. Revenue growth driven by mix of price AND volume. Gross margins expanding or stable over inflationary periods.
**Score 4:** Able to pass through inflation plus modest real price increases. Some elasticity but manageable.
**Score 3:** Can pass through inflation but limited real pricing power. Pricing actions offset by volume softness.
**Score 2:** Difficulty passing through cost increases. Margin compression during inflationary periods. Competitive pricing pressure.
**Score 1:** Price taker. No ability to raise prices. Commodity dynamics. Margin entirely dependent on input costs.

---

### 3.4 — Competitive Threat Intensity [1–5]

**What it measures:** The severity and imminence of competitive threats, including disruption risk, new entrants, and technological substitution.

**Score 5:** Competitive threats minimal and distant. Barriers to entry high. No credible disruptive threat on the horizon. Incumbency advantage.
**Score 4:** Competitive landscape stable. Some emerging threats but manageable. Company well-positioned to defend or adapt.
**Score 3:** Active competition but company holding its own. Some emerging threats require strategic response within 1–2 years.
**Score 2:** Intensifying competition. Well-funded competitors gaining ground. Disruptive technology or business model emerging. Defensive actions needed now.
**Score 1:** Under severe competitive attack. Market share bleeding. Disruption underway. Competitive moat breached or about to be breached.

---

## Chapter 4: Growth Catalysts & Optionality
**Weight:** 10%

### 4.1 — Near-Term Catalysts (0–12 months) [1–5]

**What it measures:** Specific, identifiable events in the next 12 months that could drive the stock higher.

**Score 5:** Multiple concrete catalysts with clear timelines (e.g., earnings beat setup, product launch, regulatory approval, contract announcement). Management under-promising.
**Score 4:** 1–2 solid catalysts with reasonable probability. Positive estimate revision cycle beginning.
**Score 3:** No major catalysts but steady execution expected. Catalyst-neutral.
**Score 2:** Potential negative catalysts ahead (earnings risk, competitive launch, regulatory decision). Risk of negative surprise.
**Score 1:** Clear near-term headwinds — guidance cut likely, competitive loss imminent, litigation outcome approaching.

---

### 4.2 — Medium-Term Growth Drivers (1–3 years) [1–5]

**What it measures:** Strategic growth initiatives that should drive revenue and earnings expansion over the next 1–3 years.

**Score 5:** Multiple high-conviction growth vectors (new product lines, geographic expansion, pricing actions, cross-sell opportunity). Clear execution plan with early evidence. TAM expanding.
**Score 4:** 1–2 well-articulated growth drivers with management credibility behind them. Early execution evidence.
**Score 3:** Growth expected to continue at current trajectory. No major acceleration or deceleration drivers. Organic growth adequate.
**Score 2:** Growth drivers unclear or depend on market tailwinds. Company-specific catalysts weak.
**Score 1:** Growth stalling or dependent on M&A with unclear synergy realization. No organic growth engine visible.

---

### 4.3 — Long-Term Optionality & TAM Expansion [1–5]

**What it measures:** Upside potential beyond the base business — new markets, adjacencies, platform potential, secular tailwinds that could expand the TAM significantly.

**Score 5:** Platform business with massive optionality. Addressable market expanding structurally. Company positioned to capture adjacent markets. Multi-decade runway.
**Score 4:** Clear long-term secular tailwinds supporting the business. Some adjacency potential. TAM growing organically.
**Score 3:** Adequate long-term outlook. Business relevant for foreseeable future but limited upside optionality beyond core.
**Score 2:** Long-term outlook uncertain. Technology or market shifts could strand the business within 5–10 years.
**Score 1:** Secular headwinds. Declining industry. Business model at risk of obsolescence. No credible pivot option.

---

## Chapter 5: Management & Capital Allocation
**Weight:** 10%

### 5.1 — Management Track Record & Credibility [1–5]

**What it measures:** Management's history of executing against stated goals, delivering on guidance, and navigating challenges. Words vs. actions.

**Score 5:** Exceptional execution track record. Consistently meets or beats guidance. Successfully navigated past challenges. CEO/CFO have delivered results at prior roles. Industry respect.
**Score 4:** Good track record with occasional misses well-explained. Credible management team. Prior experience relevant.
**Score 3:** Adequate. Mixed track record — some hits, some misses. Guidance accuracy roughly ±5%.
**Score 2:** Multiple guidance cuts or missed targets in past 2 years. Credibility eroding. Leadership changes creating uncertainty.
**Score 1:** Serial over-promiser, under-deliverer. Guidance unreliable. Activist pressure or board turmoil.

---

### 5.2 — Capital Allocation Discipline [1–5]

**What it measures:** How management deploys capital — R&D investment, M&A track record, buyback timing, dividend policy, balance sheet management.

**Score 5:** Exceptional capital allocators. M&A accretive with strong integration track record. Buybacks concentrated at low valuations. R&D spend yielding returns. Warren Buffett-caliber discipline.
**Score 4:** Disciplined capital allocation. Mostly value-accretive M&A. Reasonable R&D ROI. Sensible buyback program.
**Score 3:** Adequate. Capital allocation decisions reasonable but unspectacular. Some M&A mediocre but not destructive.
**Score 2:** Capital allocation concerns. Value-destructive M&A (overpayment, poor integration). Buybacks at peak valuations. R&D spending without visible return.
**Score 1:** Serial value destroyers. Empire-building M&A. Buying back stock at highs while cutting at lows. ROIC persistently below WACC reflects poor capital decisions.

---

### 5.3 — Insider Alignment & Ownership [1–5]

**What it measures:** Skin in the game. Are insiders buying or selling? Is management compensation aligned with long-term shareholder value?

**Score 5:** Significant insider ownership (CEO > 3% or multi-million $ stake). Recent insider buying on open market. Compensation heavily tied to long-term performance metrics (ROIC, FCF, relative TSR).
**Score 4:** Meaningful insider ownership. No material selling. Compensation structure reasonable with long-term incentives.
**Score 3:** Moderate insider ownership. Selling limited to scheduled 10b5-1 plans. Standard compensation structure.
**Score 2:** Low insider ownership. Notable insider selling beyond scheduled plans. Compensation tilted toward short-term revenue targets.
**Score 1:** Minimal insider ownership. Aggressive insider selling. Compensation not aligned with shareholder value. Golden parachutes without performance requirements.

**Data source:** `get_holder_info(type: insider)` from MCP for insider transaction data.

---

### 5.4 — Corporate Governance & Transparency [1–5]

**What it measures:** Board independence, shareholder-friendly governance practices, disclosure quality, and communication transparency.

**Score 5:** Best-in-class governance. Independent board, no poison pills, annual director elections, proxy access, strong disclosure practices, responsive IR. Single share class.
**Score 4:** Good governance. Mostly independent board. Standard disclosure. Reasonable shareholder rights.
**Score 3:** Adequate governance. Minor concerns (e.g., staggered board, limited proxy access) but no deal-breakers.
**Score 2:** Governance concerns. Dual-class shares with limited voting rights for public shareholders. Board not fully independent. Related-party transactions.
**Score 1:** Poor governance. Entrenched management, controlled board, multiple anti-takeover provisions, poor disclosure, related-party issues.

---

## Chapter 6: Risk Assessment
**Weight:** 10%

### 6.1 — Macro & Cyclical Exposure [1–5]

**What it measures:** Sensitivity to economic cycles, interest rates, currency fluctuations, and macroeconomic conditions.

**Score 5:** Counter-cyclical or non-cyclical. Revenue resilient in downturns. Minimal rate/currency sensitivity. Mission-critical product with inelastic demand.
**Score 4:** Low cyclicality. Some exposure but manageable. Revenue declined < 10% in last recession. Geographic diversification helps.
**Score 3:** Moderate cyclicality. Revenue correlates with GDP growth but doesn't amplify swings. Some interest rate sensitivity.
**Score 2:** High cyclicality. Revenue swings 20–30% through the cycle. Significant rate or currency exposure. Operating leverage amplifies earnings volatility.
**Score 1:** Extreme cyclicality or macro dependence. Revenue collapses in downturns. Highly leveraged to commodity prices, interest rates, or single currency. No natural hedging.

---

### 6.2 — Regulatory & Legal Risk [1–5]

**What it measures:** Exposure to adverse regulatory changes, litigation, antitrust action, or policy shifts.

**Score 5:** Minimal regulatory exposure. No material litigation. Regulated in a stable, predictable framework. Compliance record clean.
**Score 4:** Some regulatory exposure but manageable. Minor litigation within normal course of business. Regulatory environment stable.
**Score 3:** Moderate regulatory risk. Industry faces potential regulatory changes within 2–3 years. Some litigation but manageable financial exposure.
**Score 2:** Significant regulatory risk. Major regulatory changes proposed or likely. Material litigation ongoing. Fines possible.
**Score 1:** Severe regulatory/legal overhang. Antitrust action, potential business model disruption from regulation, major litigation with material financial exposure.

---

### 6.3 — Concentration Risk [1–5]

**What it measures:** Dependence on a small number of customers, suppliers, geographies, or products.

**Score 5:** Highly diversified across all dimensions. No single customer > 5% of revenue. No single supplier critical. Geographic and product diversification strong.
**Score 4:** Good diversification. Largest customer < 10%. Some supplier or geographic concentration but manageable.
**Score 3:** Moderate concentration. Top customer 10–20% of revenue OR significant geographic concentration (> 50% from one region) OR key single-supplier dependency.
**Score 2:** High concentration. Top customer > 20% OR top 3 customers > 50%. Single-geography dependence. Critical supplier with no alternative.
**Score 1:** Extreme concentration. Single customer > 30% of revenue. Single product > 80% of revenue. Single geography with geopolitical risk. Supply chain single point of failure.

---

### 6.4 — ESG & Tail Risk [1–5]

**What it measures:** Environmental, social, and governance tail risks that could cause sudden, severe value destruction. Includes climate exposure, social license to operate, cybersecurity, and black swan vulnerability.

**Score 5:** ESG leader in sector. Strong cybersecurity posture. Minimal environmental liabilities. Diversified operations reduce tail risk.
**Score 4:** Good ESG practices. Manageable environmental exposure. Standard cybersecurity for industry. Low tail risk.
**Score 3:** Average ESG profile. Some environmental or social exposure but within industry norms. Normal tail risk.
**Score 2:** Below-average ESG. Material environmental liabilities, labor controversies, or supply chain concerns. Elevated tail risk.
**Score 1:** ESG red flags. Major environmental liabilities, social controversies, or governance failures that could cause sudden value destruction. Existential tail risk scenarios credible.
