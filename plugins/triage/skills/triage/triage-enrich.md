# Phase 2: Enrichment & Triage Knowledge

Use this knowledge to answer questions about how issues are triaged, how priority is calculated, what enrichment sources are used, and how confidence and recommended actions are determined.

## Triage Assessment Criteria

### Complexity (Low / Medium / High / Very High)
- **Low**: Simple configuration change, documentation fix, or single-file change with clear pattern
- **Medium**: Multi-file change following existing patterns, moderate testing needed
- **High**: Architectural changes, new integration points, or cross-module impact
- **Very High**: Fundamental design changes, breaking changes, or novel technical challenges

### Value (Low / Medium / High / Critical)
- **Low**: Nice-to-have, affects few users, minor convenience improvement
- **Medium**: Meaningful improvement for a segment of users, noticeable quality-of-life gain
- **High**: Significant business impact, affects many users, or addresses data integrity issues
- **Critical**: Data loss, security vulnerability, or blocks core business workflows

### Risk (Low / Medium / High)
- **Low**: Isolated change, good test coverage, no breaking changes
- **Medium**: Some integration points affected, moderate regression risk
- **High**: Wide-reaching changes, breaking change potential, affects critical paths

### Effort Estimate (XS / S / M / L / XL)
- **XS**: < 2 hours (typo fix, config change)
- **S**: 2-8 hours (single focused change with tests)
- **M**: 1-3 days (multi-file feature or complex bug fix)
- **L**: 1-2 weeks (significant feature or refactoring)
- **XL**: 2+ weeks (major feature, architectural change)

### Implementation Path (Manual / Copilot-Assisted / Agentic)
- **Manual**: Requires deep domain expertise, nuanced judgment, or novel architectural decisions that AI cannot reliably handle
- **Copilot-Assisted**: Code changes follow existing patterns where AI can help with boilerplate, test generation, and repetitive tasks while a developer guides the approach
- **Agentic**: Well-defined scope with clear existing patterns — an AI agent could drive the full implementation with minimal human oversight

## Priority Score Calculation

Priority is calculated as:

```
Priority = (Value weight x Urgency weight) / (Effort weight x Risk weight)
```

Normalized to a 1-10 scale.

**Weight mappings:**

| Dimension | Rating | Weight |
|-----------|--------|--------|
| Value | Low | 1 |
| Value | Medium | 2 |
| Value | High | 3 |
| Value | Critical | 4 |
| Urgency | (assessed 1-3) | Based on issue age, affected users, severity |
| Effort | XS | 1 |
| Effort | S | 1.5 |
| Effort | M | 2 |
| Effort | L | 3 |
| Effort | XL | 4 |
| Risk | Low | 1 |
| Risk | Medium | 1.5 |
| Risk | High | 2 |

**Example**: Value=High (3), Urgency=2, Effort=M (2), Risk=Low (1)
→ Priority = (3 × 2) / (2 × 1) = 3.0 → normalized ≈ 7/10

## Confidence Calibration Rules

### High — ALL of the following are true:
- The issue clearly describes the problem or feature
- Source code from the affected area was provided and reviewed
- At least one enrichment source (ADO, Ideas Portal, or documentation) provided relevant context
- Complexity and effort estimates are based on actual code patterns, not guesses

### Medium — ANY of the following:
- Source code was provided but the affected area is unclear or spans multiple modules
- No external enrichment data was available but the issue is well-described
- Some assumptions were made about the scope or technical approach
- The issue quality score was in the NEEDS WORK range (40-74)

### Low — ANY of the following:
- No source code was available for the detected app area
- The issue is vague and multiple interpretations are possible
- No ADO work items AND no Ideas Portal matches were found
- Assessment relies heavily on assumptions rather than evidence

## Recommended Action Logic

| Action | Condition |
|--------|-----------|
| **Implement** | Priority ≥ 6 AND Confidence is High or Medium |
| **Defer** | Priority 3-5 OR Effort is L/XL |
| **Investigate** | Confidence is Low |
| **Reject** | Value is Low AND Effort ≥ M |

## Enrichment Sources

The triage agent gathers context from these sources before making its Phase 2 assessment:

### 1. Repository Source Code
- Reads AL files from the detected app area directory
- Scores files by keyword relevance to the issue
- Provides up to ~30KB of the most relevant code as context
- Used for: complexity assessment, identifying specific objects to change, risk evaluation

### 2. Dynamics 365 Ideas Portal
- Fetches from `experience.dynamics.com/_odata/ideas`
- Filters for Business Central forum ideas
- Matches ideas against extracted keywords (with fuzzy matching and BC synonyms)
- Used for: gauging community demand, checking if feature is already requested

### 3. Azure DevOps Work Items
- Queries the Dynamics SMB ADO project via WIQL
- Searches both titles and descriptions for top 5 keywords
- Used for: checking if issue is already tracked internally, identifying related work

### 4. Duplicate Detection
- Compares against recent open issues using Jaccard similarity on keyword sets
- Flags issues with ≥35% keyword overlap
- Used for: preventing duplicate work, linking related issues

## BC-Specific Risk Awareness

When assessing risk for BC issues, these technical factors matter:

- **Posting routine changes** are always high-risk (affect ledger integrity)
- **Dimension-related changes** often have wide impact across all document types
- **Event signature changes** are breaking changes (API contract violation)
- **FlowField CalcFormula changes** can have performance implications
- **Table schema changes** require upgrade codeunits (adds significant effort)
- **Test coverage** matters most for posting routines and financial calculations
