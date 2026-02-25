# Output Structure: braindump_final.md

This document defines the structure and content guidelines for the final
specification output. Follow this structure when writing `braindump_final.md`.

---

## Document Header

```markdown
# Feature Specification: [Feature Name]

| Field       | Value                          |
|-------------|--------------------------------|
| Project     | [Project Name]                 |
| Date        | [YYYY-MM-DD]                   |
| Status      | Draft                          |
| Author      | [User name if known, else "-"] |
| Version     | 1.0                            |
```

---

## Section 1: Executive Summary

**Length:** 3-5 sentences.
**Purpose:** A busy developer or PM should understand the feature after reading
only this section.

Cover:
- What the feature does (one sentence)
- Why it matters / what problem it solves (one sentence)
- Who benefits (one sentence)
- Scope of v1 (one sentence)

---

## Section 2: Problem Statement

**Purpose:** Establish the "why" with enough detail to justify the work.

Include:
- Who is affected and in what context
- The current pain (with specifics — frequency, severity, workarounds)
- The cost of NOT solving this (time wasted, revenue lost, user churn, etc.)
- Any data or evidence supporting the problem (if provided by user)

---

## Section 3: Target Users & Personas

**Purpose:** Make the user concrete enough that design decisions can reference them.

For each user segment:
- **Label** (e.g., "Power User," "Admin," "First-time Visitor")
- **Description:** Who they are, their context, their goal
- **Technical skill level:** (non-technical / basic / intermediate / advanced)
- **Frequency of use:** (daily / weekly / occasional / one-time)
- **Key needs:** What they specifically need from this feature

---

## Section 4: Core Use Cases

**Purpose:** The 3-5 things users MUST be able to do. These are non-negotiable.

Format each use case as:

```markdown
### UC-[N]: [Use Case Title]

**Actor:** [Which user persona]
**Trigger:** [What initiates this use case]
**Preconditions:** [What must be true before this can happen]
**Main Flow:**
1. [Step 1]
2. [Step 2]
3. ...
**Postconditions:** [What is true after successful completion]
**Acceptance Criteria:**
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]
```

---

## Section 5: Feature Scope

### 5.1 In Scope (v1)

List all features/capabilities included in v1. For each:
- Feature name
- Brief description (1-2 sentences)
- Priority: Must-have / Should-have / Nice-to-have
- Related use case(s)

### 5.2 Explicitly Out of Scope (Deferred)

List features/ideas that were discussed but deliberately excluded from v1.
For each:
- What it is
- Why it's deferred (not enough time, dependency on v1 learning, low priority)
- When it might be revisited (v2, never, TBD)

This section is critical for preventing scope creep.

---

## Section 6: User Journeys & UX Flows

**Purpose:** Step-by-step flows showing how a user moves through the feature.

For each core use case, describe:
- **Entry point:** How does the user get here?
- **Step-by-step flow:** What they see, what they do, what happens next
- **Decision points:** Where the flow branches based on user choice or system state
- **Exit points:** How does the user leave this flow? (success, cancel, error)
- **UI notes:** Any specific UI patterns, components, or layouts discussed

Use narrative format or numbered steps. ASCII flow diagrams are welcome for
complex branching.

---

## Section 7: Data Model & State Management

**Purpose:** What data exists, where it lives, and how it changes.

Cover:
- **Key entities** and their relationships (informal — not a formal ERD)
- **Data ownership:** Who creates, reads, updates, deletes each entity?
- **State transitions:** What states can entities be in? What triggers transitions?
- **Persistence:** What's stored permanently vs. session-only vs. cached?
- **External data:** Any data that comes from outside the system (APIs, imports)
- **Data constraints:** Uniqueness, validation rules, size limits

---

## Section 8: Edge Cases & Error Handling

**Purpose:** What can go wrong and how the system should respond.

Format:

```markdown
### EC-[N]: [Edge Case Title]

**Scenario:** [What happens]
**Expected behavior:** [How the system should respond]
**User communication:** [What the user sees/is told]
**Recovery path:** [How the user gets back to a good state]
```

Common categories to cover:
- Invalid/unexpected input
- Network/service failures
- Concurrent access / race conditions
- Permission/authorization edge cases
- Empty states (no data yet)
- Boundary conditions (max limits, zero values)

---

## Section 9: Acceptance Criteria

**Purpose:** Testable, verifiable conditions that define "done" for each feature.

Format as a checklist. Each criterion must be:
- **Specific:** No ambiguity about what's being tested
- **Testable:** A QA engineer could write a test case from it
- **Independent:** Each can be verified separately
- **Complete:** Covers happy path, error paths, and edge cases

Group by feature or use case.

---

## Section 10: Non-Functional Requirements

Cover as relevant (not all will apply to every feature):

- **Performance:** Response times, throughput, concurrent user targets
- **Security:** Authentication, authorization, data encryption, input validation
- **Accessibility:** WCAG level, screen reader support, keyboard navigation
- **Compatibility:** Browsers, devices, OS versions, screen sizes
- **Scalability:** Expected growth, data volume projections
- **Reliability:** Uptime targets, acceptable downtime, backup/recovery
- **Compliance:** GDPR, DSGVO, industry-specific requirements
- **Internationalization:** Languages, locales, date/number formats

---

## Section 11: Risks, Dependencies & Open Questions

### Risks
For each risk:
- **Risk:** What could go wrong
- **Likelihood:** High / Medium / Low
- **Impact:** High / Medium / Low
- **Mitigation:** What can be done to reduce the risk

### Dependencies
- External services / APIs
- Other teams or features that must ship first
- Third-party tools or libraries
- Data migrations or infrastructure changes

### Open Questions
Items that came up during the interview but were not resolved. Format:
- **Question:** [The open question]
- **Context:** [Why it matters]
- **Proposed next step:** [Who should answer this, how]

---

## Section 12: Appendix (Optional)

Include if relevant:
- Glossary of domain-specific terms
- Links to reference materials, competitor examples, design inspiration
- Raw notes or decisions that didn't fit elsewhere
- Technical constraints or architecture notes

---

## Writing Checklist

Before finalizing, verify:

- [ ] Executive summary is readable standalone
- [ ] Every feature has at least one acceptance criterion
- [ ] Out-of-scope items are listed (prevents scope creep)
- [ ] Edge cases cover error states, empty states, and boundary conditions
- [ ] Assumptions are explicitly marked as `[ASSUMPTION — verify]`
- [ ] User's original language/terminology is preserved
- [ ] Decision rationale is captured where choices were made
- [ ] Open questions have proposed next steps
- [ ] A developer with zero context could implement from this document
