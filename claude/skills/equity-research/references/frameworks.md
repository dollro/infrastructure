# Equity Research Scorecard — Comprehensive Frameworks Reference
## v1.0

**Last Updated:** February 2026
**Purpose:** Operational reference guide for all quantitative frameworks used in equity research analysis
**Authority:** Equity Research Scorecard Methodology (2026)

---

## Table of Contents
1. [Sector Classification & Financial Corridors](#1-sector-classification--financial-corridors)
2. [Scoring System Overview](#2-scoring-system-overview)
3. [IAS Calculation & Verdict Scale](#3-ias-calculation--verdict-scale)
4. [Chance/Risk Framework](#4-chancerisk-framework)
5. [Quality Tiers](#5-quality-tiers)

---

## 1. Sector Classification & Financial Corridors

### Sector Groups

Before any financial benchmarking, classify the company into a sector group. This determines which benchmark corridors, growth expectations, and valuation parameters to use throughout the analysis.

| Sector Group | Examples | Primary Valuation | Key Metrics |
|---|---|---|---|
| **High-Growth Tech** | Cloud SaaS, semiconductors, platform tech | EV/Revenue, EV/EBITDA, P/E | Revenue growth, NRR, Rule of 40, gross margin |
| **Mature Tech** | Legacy software, hardware, IT services | P/E, EV/EBITDA, FCF yield | Margin stability, FCF conversion, capital returns |
| **Consumer Discretionary** | Retail, restaurants, travel, luxury | P/E, EV/EBITDA | Same-store growth, margin trend, brand strength |
| **Consumer Staples** | Food, beverages, household products | P/E, dividend yield | Organic growth, pricing power, payout ratio |
| **Healthcare / Pharma** | Large pharma, medical devices, diagnostics | P/E, EV/EBITDA | Pipeline depth, patent cliff, R&D yield |
| **Biotech** | Clinical-stage biotech | Risk-adjusted NPV, EV/pipeline | Pipeline probability, cash runway, binary events |
| **Financials — Banks** | Commercial banks, investment banks | P/TBV, P/E, ROE | NIM, credit quality, CET1 ratio, efficiency ratio |
| **Financials — Insurance** | P&C, life, reinsurance | P/BV, combined ratio | Combined ratio, reserve adequacy, investment yield |
| **Financials — Fintech** | Payment processors, neobanks | EV/Revenue, P/E | TPV growth, take rate, unit economics |
| **Industrials** | Aerospace, machinery, building products | EV/EBITDA, P/E | Backlog, book-to-bill, cycle position |
| **Energy** | Oil & gas, integrated, oilfield services | EV/EBITDA, P/CF, FCF yield | Reserve replacement, breakeven price, FCF discipline |
| **Utilities** | Regulated, renewable | P/E, dividend yield, RAB | Rate base growth, allowed ROE, payout ratio |
| **REITs** | Office, residential, industrial, data center | P/FFO, P/AFFO, NAV | FFO growth, occupancy, same-property NOI, dividend coverage |
| **Materials** | Chemicals, metals, mining | EV/EBITDA (normalized) | Cycle position, cost curve position, volume/price mix |
| **Telecom** | Wireless, cable, towers | EV/EBITDA, FCF yield | ARPU trend, churn, subscriber growth, capex intensity |

### Financial Health Corridors by Sector Group

These corridors define "good," "adequate," and "concerning" ranges for key financial metrics within each sector group. Use these to calibrate scoring in Chapters 1 and 2.

#### High-Growth Tech (Revenue Growth > 20%)

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| Revenue Growth (YoY) | > 30% | 15–30% | < 15% |
| Gross Margin | > 75% | 60–75% | < 60% |
| Rule of 40 (Growth + FCF Margin) | > 50 | 30–50 | < 30 |
| Net Revenue Retention | > 130% | 110–130% | < 110% |
| FCF Margin | > 20% | 5–20% | Negative |
| Net Debt / EBITDA | < 1x | 1–3x | > 3x |

#### Mature Tech / Software

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| Revenue Growth (YoY) | > 10% | 5–10% | < 5% |
| Operating Margin | > 30% | 20–30% | < 20% |
| FCF Conversion (FCF/Net Income) | > 100% | 80–100% | < 80% |
| ROIC | > 20% | 12–20% | < 12% |
| Shareholder Yield | > 5% | 2–5% | < 2% |

#### Consumer Staples / Defensives

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| Organic Revenue Growth | > 5% | 2–5% | < 2% |
| Operating Margin | > 20% | 12–20% | < 12% |
| FCF Conversion | > 90% | 70–90% | < 70% |
| Dividend Payout Ratio | 40–60% | 60–80% | > 80% or < 20% |
| Net Debt / EBITDA | < 2x | 2–3.5x | > 3.5x |

#### Industrials / Cyclicals

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| Revenue Growth (through-cycle avg) | > 8% | 3–8% | < 3% |
| EBITDA Margin | > 20% | 12–20% | < 12% |
| ROIC (through-cycle) | > 15% | 8–15% | < 8% |
| Net Debt / EBITDA | < 1.5x | 1.5–3x | > 3x |
| FCF Conversion | > 80% | 60–80% | < 60% |
| Book-to-Bill | > 1.1x | 0.9–1.1x | < 0.9x |

#### Financials — Banks

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| ROE | > 15% | 10–15% | < 10% |
| CET1 Ratio | > 13% | 10.5–13% | < 10.5% |
| Net Interest Margin | > 3.5% | 2.5–3.5% | < 2.5% |
| Efficiency Ratio | < 55% | 55–65% | > 65% |
| NPL Ratio | < 1% | 1–3% | > 3% |
| Dividend Payout | 30–50% | 20–30% or 50–70% | < 20% or > 70% |

#### Healthcare / Pharma

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| Revenue Growth | > 8% | 3–8% | < 3% |
| Gross Margin | > 70% | 55–70% | < 55% |
| R&D as % of Revenue | 15–25% (balanced) | 10–15% or 25–35% | < 10% or > 35% |
| Pipeline Value (risk-adj) | > 1.5x current revenue | 0.5–1.5x | < 0.5x |
| Patent Cliff Exposure (5yr) | < 15% revenue at risk | 15–30% | > 30% |

#### Energy

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| FCF Yield | > 10% | 5–10% | < 5% |
| Net Debt / EBITDA | < 1x | 1–2x | > 2x |
| Breakeven Price (oil) | < $40/bbl | $40–55/bbl | > $55/bbl |
| Reserve Replacement Ratio | > 120% | 80–120% | < 80% |
| Shareholder Returns (% FCF) | > 60% | 30–60% | < 30% |

#### REITs

| Metric | Strong [5] | Adequate [3] | Weak [1] |
|---|---|---|---|
| AFFO Growth | > 5% | 2–5% | < 2% |
| Occupancy Rate | > 95% | 90–95% | < 90% |
| Same-Property NOI Growth | > 4% | 1–4% | < 1% |
| Net Debt / EBITDA | < 5x | 5–7x | > 7x |
| AFFO Payout Ratio | 65–80% | 80–90% | > 90% |
| NAV Premium/Discount | Discount > 10% | ±10% | Premium > 15% |

---

## 2. Scoring System Overview

### 25 Criteria, 6 Chapters

| Chapter | Weight | Criteria Count | Focus |
|---|---|---|---|
| 1. Fundamental Quality | 35% | 6 | Financial health, growth, profitability, cash flow |
| 2. Valuation | 20% | 4 | Absolute, relative, historical, intrinsic value |
| 3. Competitive Position & Moat | 15% | 4 | Moat durability, market share, pricing power |
| 4. Growth Catalysts & Optionality | 10% | 3 | Near/medium/long-term drivers |
| 5. Management & Capital Allocation | 10% | 4 | Track record, capital discipline, alignment |
| 6. Risk Assessment | 10% | 4 | Macro, regulatory, concentration, ESG/tail |

### Scoring Scale [1–5]

| Score | Meaning |
|:---:|---|
| 5 | Exceptional — top decile quality for this metric/dimension. Structural advantage. |
| 4 | Strong — clearly above average, no material concerns. Well-positioned. |
| 3 | Adequate — meets expectations for the sector and stage. Minor gaps. |
| 2 | Below expectations — notable concerns that create risk. Needs monitoring. |
| 1 | Weak — significant deficiency. Potential deal-breaker if in 🚩 criterion. |

**Scoring principle:** Score reflects the **weaker** of sub-dimensions assessed. For example, strong revenue growth (score 5) but decelerating trajectory (score 3) → overall score 3.

### Red Flag Criteria 🚩

Three criteria are designated Red Flags:
- **1.1 Revenue Growth & Trajectory** — Declining or stagnant revenue in a growth sector signals broken thesis.
- **1.2 Margin Profile & Trend** — Persistently compressing margins signal structural competitive erosion.
- **3.1 Moat Type & Durability** — No identifiable moat in a competitive industry signals commoditization risk.

If ANY 🚩 criterion scores 1, the verdict is automatically downgraded one level (e.g., Buy → Hold).

---

## 3. IAS Calculation & Verdict Scale

### Investment Attractiveness Score (IAS)

```
IAS = (Ch1_avg × 0.35 + Ch2_avg × 0.20 + Ch3_avg × 0.15 + Ch4_avg × 0.10 + Ch5_avg × 0.10 + Ch6_avg × 0.10) × 20
```

Where `ChN_avg` = arithmetic mean of all criteria scores in Chapter N.

**Scale:** 1–100 (theoretical range 20–100).

**Red Flag Gate:** If any 🚩 criterion = 1, IAS is calculated normally BUT the verdict derived from the IAS is downgraded one level. If two or more 🚩 criteria = 1, downgrade two levels. The IAS score itself is NOT adjusted — only the verdict mapping.

### Verdict Scale

| IAS Range | Verdict | Definition |
|---|---|---|
| 85–100 | **Strong Buy** | Exceptional — significantly undervalued with structural tailwinds and durable moat. Rare. |
| 70–84 | **Buy** | Compelling risk/reward — solid fundamentals, reasonable valuation, identifiable catalysts. |
| 55–69 | **Hold** | Fair value or mixed picture — fundamentals adequate but no clear catalyst or margin of safety. |
| 40–54 | **Underweight** | Concerns outweigh positives — deteriorating fundamentals, overvaluation, or elevated risk. |
| < 40 | **Sell** | Fundamental problems — broken model, severe overvaluation, or unresolvable risks. |

### Chance/Risk Ratio

The Chance/Risk Ratio summarizes the skew of the investment:

```
Chance/Risk Ratio = (Bull upside % × bull probability + Base upside % × base probability) / (Bear downside % × bear probability)
```

| Ratio | Interpretation |
|---|---|
| > 3.0 | Highly favorable skew — asymmetric upside |
| 2.0–3.0 | Favorable — reward clearly exceeds risk |
| 1.0–2.0 | Balanced — roughly symmetrical |
| 0.5–1.0 | Unfavorable — risk exceeds reward |
| < 0.5 | Highly unfavorable — downside dominates |

---

## 4. Chance/Risk Framework

### Bull / Base / Bear Scenarios

Every analysis must include three explicit scenarios with probability weights that sum to 100%.

| Scenario | Typical Probability | What It Assumes | Price Target Basis |
|---|---|---|---|
| **Bull** | 15–30% | Everything goes right. Beat-and-raise quarters. Multiple expansion. Catalysts hit. | Highest reasonable valuation on optimistic earnings |
| **Base** | 45–60% | Consensus path. Current trajectory continues. No major surprises. | Fair value on normalized earnings |
| **Bear** | 15–30% | Key risks materialize. Miss estimates. Multiple compression. | Trough valuation on stressed earnings |

**Probability calibration guidelines:**
- Default: 20% bull / 55% base / 25% bear (slightly risk-conscious)
- If strong momentum and improving fundamentals: shift to 25/55/20
- If deteriorating fundamentals or macro headwinds: shift to 15/50/35
- Never assign < 10% to any scenario — unknown unknowns exist

### Probability-Weighted Price Target

```
Target = (Bull price × bull prob) + (Base price × base prob) + (Bear price × bear prob)
```

This produces the expected value price target. Compare to current price for upside/downside %.

### Catalyst Timeline

Map expected catalysts on a timeline:

| Timeframe | Catalyst Type | Examples |
|---|---|---|
| 0–3 months | Earnings/guidance | Next quarter report, guidance update |
| 3–6 months | Product/operational | Product launch, FDA decision, contract win |
| 6–12 months | Strategic | M&A, restructuring, new market entry |
| 1–3 years | Structural | TAM expansion, margin inflection, competitive moat widening |
| 3+ years | Secular | Industry transformation, demographic shift |

---

## 5. Quality Tiers

Based on the composite Chapter 1 (Fundamental Quality) score, companies fall into quality tiers that affect valuation expectations:

| Quality Tier | Ch1 Avg Score | Characteristics | Valuation Implications |
|---|---|---|---|
| **Compounder** | 4.5–5.0 | High ROIC, durable margins, consistent growth, fortress balance sheet, excellent FCF conversion. These compound intrinsic value year after year. | Deserves premium multiple. Fair value on upper-quartile historical range. Rarely cheap — focus on entry timing. |
| **Quality** | 3.5–4.4 | Above-average fundamentals with minor gaps. Good but not exceptional. Some cyclicality or competitive pressure. | Deserves sector-average to modest premium. Look for entry points during temporary dislocation. |
| **Average** | 2.5–3.4 | Meets basic expectations. Mixed signals — some strong metrics, some weak. Thesis depends on improvement story. | Should trade at or below sector average multiples. Requires clear catalyst for upgrade. |
| **Challenged** | 1.5–2.4 | Below-average fundamentals. Deteriorating trends on multiple dimensions. Turnaround required. | Discount warranted. Value trap risk. Only invest if turnaround thesis is specific and evidence-backed. |
| **Distressed** | 1.0–1.4 | Broken fundamentals. Cash burn, leverage concerns, competitive irrelevance. | Deep value only. Equity may be impaired. Special situation analysis required. |

These tiers help calibrate valuation expectations. A Compounder at 25x P/E may be fairly valued; an Average company at 25x P/E is likely overvalued.
