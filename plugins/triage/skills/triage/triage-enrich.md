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

The triage agent gathers context from these sources in parallel before making its Phase 2 assessment:

### 1. Repository Source Code
- Reads AL files from the detected app area directory
- Scores files by word-boundary keyword relevance, checks file size before reading
- Provides up to ~15KB of the most relevant code as context
- Used for: complexity assessment, identifying specific objects to change, risk evaluation

### 2. Git History
- Analyzes last 3 months of commits in the detected app area
- Returns: most-changed files (change velocity), active contributors, keyword-matching commits
- Used for: risk calibration (volatile files), effort estimation (active vs dormant area), identifying domain experts

### 3. Microsoft Learn Documentation
- Live search of learn.microsoft.com API scoped to Business Central
- Returns real, verified documentation URLs (replaces LLM hallucination)
- Used for: grounding documentation references, identifying known limitations and configuration guides

### 4. Dynamics 365 Ideas Portal
- **Endpoint:** `experience.dynamics.com/_odata/ideas` OData API
- Scoped to BC forum (approved ideas only) via `adx_ideaforumid` filter
- **Search strategy:** OData `substringof()` on `adx_name` (title), sequential queries per keyword (`$top=10`)
- Body text (adx_copy) checked client-side during scoring only (server-side body search is too noisy)
- Synonym expansion (35 BC domain groups) + suffix-stripping stemmer for improved recall
- Jaccard similarity bonus for issue title overlap
- Results split into active vs closed; top 5 active + top 3 closed returned
- Used for: gauging community demand, checking if feature is already requested

### 5. Azure DevOps Work Items
- **Primary:** ADO Work Item Search API (`almsearch.dev.azure.com`) — full-text, relevance-ranked search
- **Fallback:** WIQL `Contains` queries on title + description (if Search API unavailable)
- Queries the Dynamics SMB ADO project (dynamicssmb2)
- Client-side Jaccard similarity scoring; minimum relevance threshold of 3
- Results split: top 5 active + top 3 closed work items
- Used for: checking if issue is already tracked internally, identifying related work

### 6. Pull Requests
- Searches GitHub PRs in the same repository via the search API
- Splits into open (work in progress) and recently merged (already addressed)
- Used for: detecting duplicate effort, identifying recent fixes or regressions

### 7. Community Forums
- Searches DynamicsUser.net via Discourse API with staggered queries and retry
- Results filtered by Jaccard similarity to issue title and view count
- Used for: gauging active discussion, finding workarounds or solutions

### 8. YouTube Videos
- Searches YouTube Data API v3 for Business Central videos
- Presence of tutorials/walkthroughs serves as a demand/interest signal
- Used for: supplementary demand assessment

### 9. Marketplace Ecosystem
- LLM-assessed ecosystem density based on training knowledge (no public API available)
- Classifies third-party app ecosystem as Rich / Moderate / Sparse / Unknown
- Provides a search URL for manual verification
- Used for: market demand signal — strong ecosystem interest indicates high-value improvements

### 10. Duplicate Detection
- Compares against recent open issues (100-issue window) using weighted Jaccard similarity
- Title-weighted 2:1 vs body, with BC domain synonym normalization
- Flags issues with ≥30% similarity
- Used for: preventing duplicate work, linking related issues

### 11. Precedent Finder
- Finds similar closed issues using the same weighted similarity algorithm
- Used for: historical context on how similar issues were resolved

### 12. Competitive Landscape
- LLM-assessed competitive positioning (no external API — uses model training knowledge)
- Classifies as Table stakes / Common / Differentiator / Unknown
- Must NOT name specific competing products — uses generic descriptors only
- Used for: strategic priority input — "table stakes" gaps increase urgency

## BC-Specific Risk Awareness

When assessing risk for BC issues, these technical factors matter:

- **Posting routine changes** are always high-risk (affect ledger integrity)
- **Dimension-related changes** often have wide impact across all document types
- **Event signature changes** are breaking changes (API contract violation)
- **FlowField CalcFormula changes** can have performance implications
- **Table schema changes** require upgrade codeunits (adds significant effort)
- **Test coverage** matters most for posting routines and financial calculations
