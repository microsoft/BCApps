---
name: exec-summary
description: Generate consultant-grade executive summaries using McKinsey SCQA, BCG Pyramid Principle. Transforms complex content into 3-minute decision-ready briefs.
allowed-tools: Read, Glob
argument-hint: [document/data to summarize]
---

# Executive Summary Generator

Transform complex business content into concise, actionable executive summaries for C-suite decision-makers.

## When to Use

- Summarizing reports for leadership
- Creating board-ready briefs
- Distilling complex analysis for executives
- User asks for "executive summary", "brief for leadership", or "C-suite summary"

## Consulting Frameworks

### McKinsey SCQA
- **Situation**: What's happening
- **Complication**: Why it matters now
- **Question**: What we need to decide
- **Answer**: What we recommend

### BCG Pyramid Principle
- Lead with the answer
- Group supporting arguments
- Order by importance

### Bain Action Model
- Clear ownership
- Specific timelines
- Measurable outcomes

## Quality Standards

| Requirement | Target |
|-------------|--------|
| Total length | 325-475 words (max 500) |
| Every finding | ≥1 quantified data point |
| Reading time | <3 minutes |
| Recommendations | Owner + timeline + result |

## Output Format

```markdown
# Executive Summary: [Topic]

## 1. SITUATION OVERVIEW
[50-75 words]

[Current state and why it matters now. Gap between current and desired state.]

## 2. KEY FINDINGS
[125-175 words]

**Finding 1**: [Quantified insight - X% increase, $Y impact, etc.]
**Strategic implication: [Business impact in bold]**

**Finding 2**: [Comparative data point]
**Strategic implication: [Impact on strategy]**

**Finding 3**: [Measured result]
**Strategic implication: [Impact on operations]**

[Order findings by business impact, most critical first]

## 3. BUSINESS IMPACT
[50-75 words]

**Financial Impact**: [$X revenue/cost impact or X% change]

**Risk/Opportunity**: [Magnitude as probability or percentage]

**Time Horizon**: [Specific timeline - Q3 2024, 6 months, etc.]

## 4. RECOMMENDATIONS
[75-100 words]

**[Critical]**: [Action]
— Owner: [Role] | Timeline: [Date] | Result: [Quantified outcome]

**[High]**: [Action]
— Owner: [Role] | Timeline: [Date] | Result: [Quantified outcome]

**[Medium]**: [Action]
— Owner: [Role] | Timeline: [Date] | Result: [Quantified outcome]

## 5. NEXT STEPS
[25-50 words]

1. **[Immediate action]** — Deadline: [Date within 30 days]
2. **[Immediate action]** — Deadline: [Date within 30 days]

**Decision Point**: [Key decision required] by [Deadline]
```

## Communication Principles

### Be Quantified
```
Bad:  "Revenue increased significantly"
Good: "Revenue increased 34% QoQ, from $2.1M to $2.8M"
```

### Be Impact-Focused
```
Bad:  "We should invest in AI capabilities"
Good: "AI investment could unlock $2.3M ARR within 18 months"
```

### Be Strategic
```
Bad:  "Competition is increasing"
Good: "**Market leadership at risk** - competitors gained 8 points of market share in Q2"
```

### Be Actionable
```
Bad:  "Marketing should improve retention"
Good: "CMO to launch retention campaign by June 15, targeting top 20% customer segment, expected to reduce churn by 15%"
```

## Priority Labels

| Label | Meaning | Timeline |
|-------|---------|----------|
| **Critical** | Must do - significant risk if delayed | Immediate |
| **High** | Should do - material business impact | This quarter |
| **Medium** | Could do - improvement opportunity | Next quarter |

## Data Integrity Rules

1. **No assumptions** beyond provided data
2. **Flag gaps** explicitly when data is missing
3. **Cite sources** for all quantified claims
4. **Acknowledge uncertainty** in projections
5. **Distinguish facts from analysis**

## Success Criteria

- [ ] Summary enables decision in <3 minutes
- [ ] Every finding has quantified data
- [ ] Word count 325-475 (max 500)
- [ ] Strategic implications are bold
- [ ] Recommendations have owner + timeline + result
- [ ] Next steps are within 30 days
- [ ] No assumptions beyond provided data
