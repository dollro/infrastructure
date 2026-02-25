# Analyst Assessment Checklists — Equity Research Scorecard v1.0

> Operational playbook for conducting equity research. Each checklist specifies exactly what data to pull from MCP, what to calculate, what to search for, and how to evaluate evidence.

---

## Chapter 1: Fundamental Quality

### 1.1 — Revenue Growth & Trajectory

**MCP data pull:**
- `get_financial_statement(income_stmt)` → Extract "Total Revenue" for 3–4 annual periods. Calculate YoY growth rates.
- `get_financial_statement(quarterly_income_stmt)` → Extract quarterly revenue for 8 quarters. Calculate QoQ growth rates and YoY quarterly comparisons.

**Calculations:**
- 1-year revenue growth = (Latest annual / Prior annual) − 1
- 3-year revenue CAGR = (Latest annual / 3-years-ago annual)^(1/3) − 1
- Sequential QoQ growth for last 4 quarters — is the rate accelerating or decelerating?
- YoY quarterly growth (Q vs. same Q prior year) — removes seasonality

**Web search:**
- "[Company] revenue guidance [year]" — compare actual growth to management guidance
- "[Company] organic growth" — separate organic from acquisition-driven growth if recent M&A
- "[Sector] industry growth rate" — benchmark company growth vs. market growth

**Assessment questions:**
- Is revenue growth organic or acquisition-driven? Strip out M&A to see the underlying engine.
- Are the last 2 quarters accelerating or decelerating vs. the trailing average? Inflection points matter.
- Is the company outgrowing its market (gaining share) or just riding the market (beta)?
- Does management have a credible path to maintain or accelerate current growth rates?

---

### 1.2 — Margin Profile & Trend

**MCP data pull:**
- `get_financial_statement(income_stmt)` → Extract: Total Revenue, Gross Profit, Operating Income, EBITDA, Net Income for 3–4 years. Calculate all margin levels.
- `get_financial_statement(quarterly_income_stmt)` → Same metrics quarterly for 8 quarters. Track margin trajectory.

**Calculations:**
- Gross margin = Gross Profit / Revenue (and trend over 8 quarters)
- Operating margin = Operating Income / Revenue (and trend)
- EBITDA margin = EBITDA / Revenue
- Net margin = Net Income / Revenue
- Margin delta: compare latest quarter margin to same quarter prior year and to 2-year-ago quarter
- Incremental margin = change in operating income / change in revenue (measures operating leverage)

**Web search:**
- "[Company] margin expansion guidance" — does management project margin improvement?
- "[Sector] average operating margin" — peer benchmark

**Assessment questions:**
- Are margins expanding, stable, or compressing? What's driving the direction?
- Is gross margin stable? Gross margin erosion is the most dangerous signal — it indicates pricing power loss or cost structure problems.
- Is there operating leverage? Revenue growth should translate to faster operating income growth in a well-run business.
- Is the company investing (depressing margins temporarily) or losing competitiveness (structural compression)?
- Incremental margin > existing margin = operating leverage (positive). Incremental margin < existing margin = deleverage (concerning).

---

### 1.3 — Return on Invested Capital (ROIC)

**MCP data pull:**
- `get_financial_statement(income_stmt)` → Operating Income, Tax Rate (effective)
- `get_financial_statement(balance_sheet)` → Total Stockholders' Equity, Total Debt (long-term + short-term), Cash & Short-Term Investments

**Calculations:**
- NOPAT = Operating Income × (1 − effective tax rate)
- Invested Capital = Total Equity + Total Debt − Cash (or: Total Assets − Current Liabilities + Short-Term Debt)
- ROIC = NOPAT / Average Invested Capital (average of beginning and end of period)
- Compare ROIC to WACC estimate (shortcut: 8–10% for most large-caps, adjust for risk)
- ROIC spread = ROIC − WACC (positive = value creation)
- Calculate ROIC for 3 years — look at trend

**Web search:**
- "[Company] WACC estimate" or "[Company] cost of capital" — analyst estimates if available
- "[Sector] median ROIC" — sector benchmark

**Assessment questions:**
- Is ROIC > WACC? By how much? Persistent positive spread = compounding machine.
- Is ROIC trending up, stable, or down? What's driving the direction?
- How does ROIC compare to sector median? Top-quartile performers warrant premium valuation.
- Has a large acquisition recently depressed ROIC? If so, is there a credible integration timeline to restore it?
- A company growing at 25% with ROIC below WACC is DESTROYING value at an accelerating rate. Never confuse growth with value creation.

---

### 1.4 — Cash Flow Quality & Conversion

**MCP data pull:**
- `get_financial_statement(cashflow)` → Operating Cash Flow, Capital Expenditures, Free Cash Flow. 3–4 years.
- `get_financial_statement(income_stmt)` → Net Income (same periods)
- `get_financial_statement(quarterly_cashflow)` → Quarterly FCF for recent 4 quarters

**Calculations:**
- FCF = Operating Cash Flow − Capex
- FCF margin = FCF / Revenue
- FCF conversion = FCF / Net Income (> 100% is excellent)
- FCF yield = FCF / Market Cap (use `get_stock_info` for market cap)
- Capex intensity = Capex / Revenue
- Accrual ratio = (Net Income − Operating CF) / Total Assets (high positive = low earnings quality)
- Shareholder yield = (Buybacks + Dividends) / Market Cap

**Assessment questions:**
- Is the company generating real cash or just reporting paper profits?
- FCF conversion > 100% means cash earnings exceed accounting earnings — positive signal.
- FCF conversion persistently < 70% in a mature business is a yellow flag — where is the cash going?
- Is capex "maintenance" (required to sustain) or "growth" (investing for future returns)? Management often claims the latter.
- Working capital: Is DSO (days sales outstanding) rising faster than revenue? Possible revenue quality concern.

---

### 1.5 — Balance Sheet Strength

**MCP data pull:**
- `get_financial_statement(balance_sheet)` → Total Debt, Cash & Short-Term Investments, Current Assets, Current Liabilities, Total Stockholders' Equity
- `get_financial_statement(income_stmt)` → EBITDA, Interest Expense

**Calculations:**
- Net debt = Total Debt − Cash
- Net debt / EBITDA (leverage ratio)
- Current ratio = Current Assets / Current Liabilities
- Interest coverage = EBITDA / Interest Expense
- Debt/Equity ratio
- Compare all to sector corridors in frameworks.md

**Web search:**
- "[Company] credit rating" — S&P/Moody's rating for debt quality
- "[Company] debt maturity schedule" — near-term refinancing risk

**Assessment questions:**
- Could the company survive 18 months of zero revenue? (extreme stress test for liquidity)
- What percentage of debt matures in the next 2 years? Maturity walls create refinancing risk.
- Is leverage trending up or down? Companies taking on debt to fund buybacks at high valuations = concerning.
- For banks: CET1 ratio vs. regulatory minimum (10.5% minimum, > 13% = strong)

---

### 1.6 — Earnings Quality & Predictability

**MCP data pull:**
- `get_financial_statement(income_stmt)` → Compare GAAP Operating Income to EBITDA. Note magnitude of adjustments.
- `get_financial_statement(quarterly_income_stmt)` → Look at quarterly earnings consistency. Large quarter-to-quarter swings = low predictability.
- `get_financial_statement(cashflow)` → Compare Net Income to Operating Cash Flow. Persistent large gaps = accrual concern.

**Web search:**
- "[Company] earnings surprise history" — pattern of beats vs. misses
- "[Company] revenue recognition" — any changes in accounting policies
- "[Company] stock-based compensation" — for tech companies, SBC as % of revenue

**Assessment questions:**
- How large is the gap between GAAP and non-GAAP earnings? Companies that persistently add back "one-time" charges have recurring one-time charges.
- Is stock-based compensation material (> 10–15% of revenue)? SBC is a real expense — it dilutes shareholders.
- Revenue model: recurring (subscription) vs. transactional vs. project-based? Recurring = most predictable.
- Earnings beat/miss pattern: consistent beats suggest conservative guidance (positive signal). Consistent misses or volatile pattern = low credibility.

---

## Chapter 2: Valuation

### 2.1–2.3 — Absolute, Relative, and Historical Valuation

**MCP data pull:**
- `get_stock_info` → P/E ratio (trailing and forward if available), EPS, Market Cap, Enterprise Value
- `get_financial_statement(income_stmt)` → Revenue, EBITDA, Net Income for multiples calculation
- `get_financial_statement(cashflow)` → FCF for P/FCF calculation
- `get_historical_stock_prices(5y, 1wk)` → Historical price for long-term valuation context

**Calculations:**
- Forward P/E = Price / Forward EPS estimate (use analyst consensus from web search if not in MCP)
- EV/EBITDA = Enterprise Value / trailing EBITDA
- P/FCF = Market Cap / trailing FCF
- EV/Revenue = Enterprise Value / trailing Revenue (for growth companies)
- PEG ratio = Forward P/E / expected EPS growth rate
- FCF yield = FCF / Market Cap
- Earnings yield = EPS / Price (inverse P/E — compare to risk-free rate)

**Web search:**
- "[Sector] forward P/E median [year]" — sector benchmark multiples
- "[Company] peer group valuation" — comparable company multiples
- "[Company] analyst price target consensus" — where the Street sits
- "[Company] historical P/E range" — 5yr high/low multiple

**Assessment questions:**
- On absolute basis: Is the stock cheap, fair, or expensive for what you're getting?
- PEG < 1.0 with quality fundamentals is classically attractive. PEG > 2.0 requires exceptional quality to justify.
- Relative to peers: is any discount/premium justified by fundamental differences?
- Historical: Where in the 5-year range are we? If near the top, what has improved to justify it? If near the bottom, what has deteriorated?
- FCF yield vs. 10yr Treasury yield: Is the equity offering better yield than risk-free bonds?

### 2.4 — DCF / Intrinsic Value

**Reference:** See `references/valuation-methods.md` for complete DCF methodology.

**Quick assessment:**
- Build a simple 5-year DCF using current FCF, reasonable growth assumptions (conservative — below management guidance), and appropriate WACC.
- Terminal value using 2.5–3.5% terminal growth rate (GDP-like) and exit multiple method as cross-check.
- Sensitivity table: ±1% on growth rate and ±1% on WACC. If the stock is overvalued in most scenarios, that's telling.

---

## Chapter 3: Competitive Position & Moat

### 3.1–3.4 — All Competitive Criteria

**MCP data pull:**
- `get_stock_info` → Sector, Industry — for competitive context
- `get_yahoo_finance_news` → Recent news for competitive developments

**Web search (critical for this chapter):**
- "[Company] market share [industry]" — market position data
- "[Company] vs [Competitor 1] vs [Competitor 2]" — competitive comparison
- "[Company] competitive advantages" or "[Company] moat" — analyst and expert commentary
- "[Industry] competitive landscape [year]" — industry structure
- "[Company] customer switching costs" — retention and stickiness evidence
- "[Company] pricing power" or "[Company] price increases" — pricing actions and customer response

**Assessment questions:**
- **Moat identification:** Which of the 5 moat types does this company possess? Be specific. "Brand" is vague — what does the brand allow them to do? (Price premium? Higher retention? Lower CAC?)
- **Moat durability:** Is the moat widening (network effects growing, switching costs increasing) or narrowing (technology commoditizing, new entrants appearing)?
- **Market share:** Is the company gaining or losing? Compare revenue growth to total market growth.
- **Pricing power:** Can they raise prices above inflation without losing customers? Look at historical gross margin during inflationary periods.
- **Competitive threats:** Who is the most dangerous competitor? What would it take to disrupt this business? Is disruption likely within 5 years?

---

## Chapter 4: Growth Catalysts & Optionality

### 4.1–4.3 — All Catalyst Criteria

**MCP data pull:**
- `get_yahoo_finance_news` → Recent catalysts, announcements
- `get_recommendations(upgrades_downgrades)` → Recent analyst rating changes signal catalyst views
- `get_stock_info` → Forward estimates imply market's growth expectation

**Web search:**
- "[Company] product pipeline [year]" — upcoming product launches
- "[Company] earnings call highlights" — management commentary on growth drivers
- "[Company] TAM addressable market" — market sizing
- "[Company] geographic expansion" — new market entry plans
- "[Company] M&A strategy" — acquisition-driven growth
- "[Industry] secular trends" — long-term tailwinds/headwinds

**Assessment questions:**
- **Near-term (0–12 months):** What specific events could move the stock? Earnings beats, product launches, regulatory decisions, contract announcements. Be concrete.
- **Medium-term (1–3 years):** What is the growth engine? New products? Geographic expansion? Pricing? Market share gains? Is there evidence execution is on track?
- **Long-term optionality:** Is the TAM expanding or contracting? Does the company have a platform that could expand into adjacencies? Secular tailwinds or headwinds?
- **Consensus expectations:** What is the market already pricing in? If the stock trades at 30x forward P/E, the market expects significant growth. The question is: will actual growth EXCEED expectations?

---

## Chapter 5: Management & Capital Allocation

### 5.1–5.4 — All Management Criteria

**MCP data pull:**
- `get_holder_info(type: insider)` → Insider buying/selling patterns. Net insider buying = positive signal.
- `get_holder_info(type: institutional)` → Top institutional holders. Increasing institutional ownership = smart money endorsement.
- `get_stock_actions` → Dividend history, stock splits — capital return consistency.
- `get_financial_statement(cashflow)` → Buyback and dividend amounts.

**Web search:**
- "[Company] CEO track record" or "[CEO name] track record" — management history
- "[Company] capital allocation" — how management deploys capital
- "[Company] M&A history" — track record of acquisitions
- "[Company] corporate governance" — board composition, shareholder rights
- "[Company] insider buying [year]" — recent transactions
- "[Company] executive compensation" — alignment with shareholder value

**Assessment questions:**
- **Track record:** Has management consistently delivered on guidance? Pattern of beats = conservative guidance (positive). Pattern of misses = credibility problem.
- **Capital allocation:** Are buybacks well-timed (buying at low valuations) or poorly timed (buying at highs)? Is M&A accretive (ROIC on acquisitions > WACC)?
- **Insider signals:** Net insider buying is one of the strongest predictive signals in equity markets. Selling is weaker (diversification, estate planning), but cluster selling by multiple insiders is a warning.
- **Governance:** Dual-class share structures are a governance discount. Related-party transactions are always a red flag.

---

## Chapter 6: Risk Assessment

### 6.1–6.4 — All Risk Criteria

**MCP data pull:**
- `get_stock_info` → Beta (market sensitivity), sector (cyclicality indicator)
- `get_historical_stock_prices(5y, 1wk)` → Maximum drawdown during past corrections (2020 COVID, 2022 rate hikes)
- `get_financial_statement(income_stmt)` → Revenue volatility through past cycles
- `get_yahoo_finance_news` → Recent risk-relevant news (lawsuits, regulatory, etc.)

**Web search:**
- "[Company] 10-K risk factors" — management's own risk disclosure (from latest annual report)
- "[Company] litigation" or "[Company] lawsuits" — legal exposure
- "[Company] regulatory risk" — regulatory environment changes
- "[Company] customer concentration" — top customer dependency
- "[Company] supply chain risk" — single-source suppliers
- "[Company] ESG rating" or "[Company] ESG controversies" — sustainability risks
- "[Company] cybersecurity" — data breach history, cybersecurity posture

**Assessment questions:**
- **Macro/cyclical:** How did revenue and earnings perform during the 2020 downturn? During the 2022 rate hike cycle? Historical stress tests reveal cyclical exposure.
- **Regulatory:** Is there pending legislation that could materially impact the business model? Antitrust scrutiny? Sector-specific regulation?
- **Concentration:** Is any single customer > 10% of revenue? Is revenue concentrated in one geography (especially one with geopolitical risk)? Is there a single-source supplier?
- **Tail risk:** What is the worst realistic scenario? (Not asteroid-hits-Earth, but realistic severe scenario.) How much could the stock fall? Is there existential risk?
- **10-K risk factors:** Always read the company's own risk disclosures. Management is legally required to disclose known material risks. The most informative ones are specific (not boilerplate), newly added (indicates emerging concern), or notably longer than peers (management is worried).
