# Valuation Methods Reference — Equity Research Scorecard v1.0

> Comprehensive valuation methodology for intrinsic value estimation. Use multiple methods and triangulate. No single method is sufficient.

---

## Table of Contents
1. [Discounted Cash Flow (DCF)](#1-discounted-cash-flow-dcf)
2. [Comparable Company Analysis (Comps)](#2-comparable-company-analysis-comps)
3. [Historical Valuation Range](#3-historical-valuation-range)
4. [Fair Value Triangulation](#4-fair-value-triangulation)
5. [Sector-Specific Valuation Methods](#5-sector-specific-valuation-methods)

---

## 1. Discounted Cash Flow (DCF)

### When to Use
DCF is the primary intrinsic value method. Use for all companies with positive or near-term-positive free cash flow. For pre-profit companies, use revenue-based DCF or comparable method instead.

### Standard DCF Framework

**Step 1: Establish Base FCF**
- Use trailing 12-month FCF as starting point
- Normalize for one-time items (restructuring, litigation, unusually high/low capex)
- If FCF is highly volatile, use 3-year average as base
- FCF = Operating Cash Flow − Capital Expenditures

**Step 2: Project FCF Growth (5-Year Explicit Period)**

| Year | Growth Rate Basis |
|---|---|
| Year 1 | Analyst consensus or recent trajectory, modestly conservative |
| Year 2 | Fade toward medium-term sustainable rate |
| Year 3 | Medium-term sustainable rate |
| Years 4–5 | Fade toward terminal growth |

**Growth rate guidance:**
- NEVER use management guidance as the high-end. Management guidance IS the starting point, then stress-test downward.
- For high-growth companies (>20% revenue growth): Assume growth halves over the 5-year period (e.g., 30% → 15%)
- For mature companies (<10% growth): Assume roughly stable growth or slight deceleration
- Apply margin expansion/compression assumptions to convert revenue growth to FCF growth
- FCF growth = Revenue growth + margin expansion + working capital efficiency gains − capex intensity changes

**Step 3: Estimate WACC (Discount Rate)**

```
WACC = (E/V × Re) + (D/V × Rd × (1 − Tax Rate))
```

Where:
- E/V = Equity weight (market cap / enterprise value)
- D/V = Debt weight (net debt / enterprise value)
- Re = Cost of equity = Risk-free rate + Beta × Equity risk premium
- Rd = Cost of debt = Weighted average interest rate on outstanding debt
- Tax rate = Effective tax rate

**Shortcut WACC estimation:**

| Company Profile | Typical WACC Range |
|---|---|
| Large-cap, low-beta, investment grade | 7–9% |
| Mid-cap, moderate beta | 9–11% |
| Small-cap, higher risk | 11–14% |
| High-growth tech, elevated beta | 10–13% |
| Emerging market exposure | Add 1–3% premium |

**Current inputs (update as needed):**
- Risk-free rate: Use 10-year US Treasury yield (search for current rate)
- Equity risk premium: 5.0–6.0% (Damodaran estimate for US market)
- Beta: From `get_stock_info` MCP call

**Step 4: Calculate Terminal Value**

Two methods — use both as cross-check:

**Method A: Gordon Growth Model**
```
Terminal Value = FCF_Year5 × (1 + g) / (WACC − g)
```
Where g = terminal growth rate (typically 2.5–3.5%, should not exceed long-term GDP growth)

**Method B: Exit Multiple**
```
Terminal Value = EBITDA_Year5 × Exit EV/EBITDA multiple
```
Use sector median EV/EBITDA or company's 5-year average. Apply 10–20% discount to current multiple as conservative assumption.

**Terminal value should be 50–75% of total DCF value.** If > 80%, the explicit period assumptions are too conservative or terminal growth too aggressive. If < 40%, verify explicit period growth isn't too aggressive.

**Step 5: Calculate Fair Value**

```
Enterprise Value = Sum of PV(FCF_Year1 through Year5) + PV(Terminal Value)
Equity Value = Enterprise Value − Net Debt + Cash
Fair Value Per Share = Equity Value / Shares Outstanding
```

### DCF Sensitivity Table

Always present a sensitivity table varying the two most impactful assumptions:

| | WACC 8% | WACC 9% | WACC 10% | WACC 11% | WACC 12% |
|---|---|---|---|---|---|
| Growth 5% | $[___] | $[___] | $[___] | $[___] | $[___] |
| Growth 8% | $[___] | $[___] | $[___] | $[___] | $[___] |
| Growth 10% | $[___] | $[___] | $[___] | $[___] | $[___] |
| Growth 12% | $[___] | $[___] | $[___] | $[___] | $[___] |
| Growth 15% | $[___] | $[___] | $[___] | $[___] | $[___] |

### DCF Sanity Checks

After calculating DCF fair value, verify:
- **Implied terminal multiple:** What EV/EBITDA multiple does the terminal value imply? If > 20x for a non-tech company, terminal growth is likely too aggressive.
- **Implied revenue growth:** What revenue CAGR does the DCF imply? Is it achievable for this company?
- **Margin assumptions:** Are projected margins above historical peak? If so, justify why.
- **Capex assumptions:** Are maintenance capex and growth capex appropriately estimated? Under-estimating capex inflates FCF.

### DCF Pitfalls to Avoid

- **Don't anchor to current price.** Build the DCF independently, then compare to market price.
- **Don't use terminal growth > 4%.** No company grows faster than GDP indefinitely. 2.5–3.5% is the safe range.
- **Don't assume margin expansion without structural reason.** Margin expansion in DCF should be supported by specific operating leverage or mix shift evidence.
- **Don't ignore stock-based compensation.** SBC dilutes shareholders. Either subtract SBC from FCF or increase share count over time.
- **Don't use WACC < 7%.** Even in low-rate environments, equity risk deserves real compensation.

---

## 2. Comparable Company Analysis (Comps)

### Peer Selection

Select 3–5 closest comparable companies based on:

| Factor | Priority | Notes |
|---|---|---|
| Business model | Highest | Same revenue model (subscription, transactional, etc.) |
| Industry | High | Same or adjacent industry |
| Growth rate | High | Within 2x growth rate range |
| Size | Medium | Similar market cap bracket (within 3–5x) |
| Margin profile | Medium | Similar profitability characteristics |
| Geography | Lower | US-listed preferred for consistency |

### Comps Valuation Method

**Step 1: Identify peer multiples**

For each peer, calculate:
- Forward P/E (preferred for profitabl companies)
- EV/EBITDA (trailing and forward)
- EV/Revenue (for high-growth)
- P/FCF
- PEG ratio

**Step 2: Determine appropriate multiple**

Use median of peer group (not mean — avoids outlier distortion). If the target company has superior growth or margins, it may deserve a premium; if inferior, a discount.

**Premium/discount adjustments:**
- Growth: +5% premium for each 5pp above peer median growth rate
- Margins: +5% premium for each 5pp above peer median margin
- Quality (ROIC): +5% premium for each 5pp above peer median ROIC
- Risk: −5% discount for higher leverage, lower governance, or higher cyclicality

**Step 3: Apply and triangulate**

```
Comps Fair Value = Target's forward metric × Adjusted peer median multiple
```

Calculate fair value from each multiple independently. If they cluster within ±10%, confidence is high. If they diverge widely, investigate why (different capital structures, tax rates, or business mix).

---

## 3. Historical Valuation Range

### Methodology

**Step 1: Gather historical multiples**

From 5-year weekly price history (`get_historical_stock_prices(5y, 1wk)`) and annual financial data:
- Calculate trailing P/E, EV/EBITDA at each year-end
- Note the 5-year high, low, average, and current for each multiple

**Step 2: Context-adjust**

Before applying historical multiples, ask:
- Has the business fundamentally changed? (e.g., shift from hardware to SaaS, major acquisition, divestiture)
- Has the sector re-rated? (e.g., multiple expansion/compression across the industry)
- Has the growth rate changed materially?

If yes to any: historical range is less relevant. Adjust or rely more on comps/DCF.

**Step 3: Determine fair value range**

```
Historical Fair Value = Current metric × 5-year average multiple
Historical High = Current metric × 5-year high multiple (optimistic)
Historical Low = Current metric × 5-year low multiple (pessimistic)
```

The average provides the central fair value estimate. The range defines optimistic/pessimistic bounds for scenario analysis.

---

## 4. Fair Value Triangulation

### Blending Multiple Methods

No single valuation method is definitive. Triangulate using weights based on confidence:

| Method | Default Weight | When to Increase Weight | When to Decrease Weight |
|---|---|---|---|
| DCF | 40% | Stable, predictable FCF; high-quality inputs | Volatile or negative FCF; uncertain growth |
| Comps | 30% | Good peer set available; liquid comps | Few true comps; company is unique |
| Historical Range | 20% | Stable business; no structural change | Business model or growth profile changed |
| Sum-of-Parts | 10% | Conglomerate or multi-segment | Single-product company |

**Blended Fair Value:**
```
Fair Value = (DCF × weight) + (Comps × weight) + (Historical × weight) + (SoTP × weight)
```

**Margin of Safety:**
- For a BUY recommendation: current price should be at least 15% below blended fair value
- For a STRONG BUY: at least 25% below
- For a HOLD: within ±15% of fair value
- For UNDERWEIGHT: 10–25% above fair value
- For SELL: > 25% above fair value

### Price Target Derivation

The probability-weighted price target (from bull/base/bear scenarios) should be:
- Compared to the blended fair value as a sanity check
- If they diverge by > 20%, revisit assumptions
- The final price target should reflect BOTH the valuation analysis AND the scenario analysis

---

## 5. Sector-Specific Valuation Methods

### SaaS / Cloud Software
- **Primary:** EV/Revenue (high-growth), EV/EBITDA or P/E (profitable)
- **Rule of 40:** Revenue growth % + FCF margin % should exceed 40 for quality SaaS. Companies well above deserve premium multiples.
- **Magic number:** Net new ARR / prior quarter sales & marketing spend. > 1.0 = efficient growth.
- **NRR-adjusted:** Companies with NRR > 130% deserve premium because existing customers are a built-in growth engine.

### Banks / Financial Institutions
- **Primary:** P/TBV (price to tangible book value), P/E
- **ROE-based:** Fair P/TBV = (ROE − g) / (COE − g). Banks earning ROE > COE deserve P/TBV > 1x.
- **Never use EV/EBITDA** for banks — capital structure IS the business.
- **Key check:** Is ROE sustainable at current levels or inflated by rate environment?

### REITs
- **Primary:** P/FFO, P/AFFO, NAV discount/premium
- **FFO = Net Income + Depreciation − Gains on Sale.** AFFO = FFO − maintenance capex.
- **NAV:** Sum of property values (use cap rate on NOI) − net debt. Compare share price to NAV per share.
- **Dividend coverage:** AFFO payout ratio should be < 85% for safety.

### Biotech / Pre-Revenue Healthcare
- **Primary:** Risk-adjusted NPV of pipeline
- Assign probability of success to each pipeline asset by phase:
  | Phase | Typical Probability of Success |
  |---|---|
  | Preclinical | 5–10% |
  | Phase I | 10–15% |
  | Phase II | 25–35% |
  | Phase III | 50–70% |
  | Filed/Under Review | 85–95% |
- Calculate NPV of each asset's peak revenue × probability × appropriate discount rate
- Sum pipeline value + cash − burn rate × months to key catalyst = fair value

### Energy / Commodities
- **Primary:** EV/EBITDA (normalized), P/CF, FCF yield, NAV (for resource companies)
- **Normalize earnings** through the commodity cycle. Don't use peak or trough year.
- **Breakeven analysis:** What commodity price makes this company FCF neutral? Below current price = margin of safety.
- **Reserve-based NAV:** PV of reserves at conservative commodity price assumptions.

### Industrials / Cyclicals
- **Primary:** EV/EBITDA (mid-cycle), P/E (mid-cycle)
- **Critical:** Use mid-cycle or normalized earnings, NOT trailing. Buying cyclicals at low trailing P/E (peak earnings) is a classic value trap.
- **Inverse P/E rule:** For cyclicals, the best time to buy is often when the P/E looks highest (trough earnings). The best time to sell is when P/E looks lowest (peak earnings).
- **Backlog and book-to-bill:** Forward-looking indicators matter more than trailing earnings for cyclicals.
