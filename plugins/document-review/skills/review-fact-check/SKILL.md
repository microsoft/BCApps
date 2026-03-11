---
name: review-fact-check
description: Identify and verify factual claims in a document. Distinguishes facts from opinions and assesses credibility impact.
allowed-tools: Read, Glob, WebSearch, WebFetch
argument-hint: [file path or paste content]
---

# Fact-Check Analysis

Identify and verify all factual claims in a document.

## When to Use

- Reviewing documents with statistical claims or data
- Verifying research or analysis accuracy
- User asks to "fact-check", "verify claims", or "check accuracy"

## Analysis Steps

### 1. Identify Factual Claims
- Extract all statements presented as facts
- Distinguish facts from opinions/interpretations
- Note the source (if any) the author provides

### 2. Verify Each Claim

**Verdicts:**
| Verdict | Meaning |
|---------|---------|
| **Confirmed** | Verified by reliable sources |
| **Disputed** | Conflicting information exists |
| **Unverifiable** | Cannot find reliable sources |
| **False** | Contradicted by reliable sources |

### 3. Assess Impact
- How critical is each claim to the document's argument?
- What are the implications if a claim is false?

## Output Format

```markdown
## Fact-Check Report

**Document**: [Title]
**Claims Analyzed**: [X]
**Verified**: [X] | **Disputed**: [X] | **Unverifiable**: [X] | **False**: [X]

### Claim Analysis

#### Claim 1: "[Quote the claim]"

- **Verdict**: [Confirmed/Disputed/Unverifiable/False]
- **Source**: [Citation]
- **Notes**: [Context or nuance]
- **Impact**: [High/Medium/Low] - [Why this matters]

#### Claim 2: "[Quote the claim]"
...

### Critical Findings

[Highlight any claims that significantly affect the document's credibility]

### Summary

**Factual Accuracy Score**: [X/10]
**Credibility Impact**: [High/Medium/Low]
[Overall assessment of factual accuracy]

### Recommendations

1. [Claims that need better sourcing]
2. [Claims to remove or revise]
3. [Additional verification needed]
```

## Source Quality Tiers

| Tier | Source Types | Reliability |
|------|--------------|-------------|
| **Primary** | Original research, official data, direct measurements | Highest |
| **Secondary** | Peer-reviewed articles, authoritative references | High |
| **Tertiary** | News reports, encyclopedias, textbooks | Moderate |
| **Weak** | Blogs, opinion pieces, social media | Low |
