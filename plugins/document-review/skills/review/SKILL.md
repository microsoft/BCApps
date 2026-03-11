---
name: review
description: Comprehensive critical assessment of documents, arguments, and knowledge work. Evaluates question architecture, rigor, evidence quality, and innovation opportunities.
allowed-tools: Read, Glob, Grep
argument-hint: [file path or paste content]
---

# Critical Document Review

Systematic methodology for identifying weaknesses in thinking, arguments, and intellectual rigor in any knowledge work.

## When to Use

- Reviewing PRDs, design documents, or technical specs
- Evaluating research or analysis
- Assessing business proposals or strategies
- User asks to "review", "critique", or "analyze" a document

## Five Dimensions of Assessment

### 1. Question Architecture
*Does the work correctly identify and address its fundamental question?*

**Tests:**
- **Clarity**: Is the central question explicitly stated?
- **Validity**: Is this the RIGHT question to ask?
- **Scope**: Appropriately bounded - not too broad/narrow?
- **Value**: Does answering provide meaningful value?

**Common Failures:**
- Vague or shifting central questions
- Questions that assume their conclusions
- Questions that miss the actual problem
- Questions too abstract to be actionable

### 2. Decomposition Rigor
*Does the work decompose its question using sound methodology?*

**Tests:**
- **Theory**: Clear decomposition theory behind structure?
- **MECE**: Mutually Exclusive, Collectively Exhaustive?
- **Synthesis**: Can sub-answers combine to answer parent?
- **Consistency**: Similar abstraction at each level?

**Common Failures:**
- Arbitrary decomposition without theoretical basis
- Overlapping sub-questions creating redundancy
- Missing critical dimensions
- Mixed abstraction levels in same tier

### 3. Answer Completeness
*Are answers rigorous and evidence-based at all levels?*

**Evidence Tiers:**
| Tier | Type | Value |
|------|------|-------|
| Primary | Original research, official docs, direct data | High |
| Secondary | Meta-analyses, review articles, textbooks | Moderate |
| Weak | Opinion pieces, anecdotes, analogies | Low |
| Invalid | Unsourced claims, circular reasoning | None |

**Common Failures:**
- Unsupported assertions presented as facts
- Answers that dodge the actual question
- Reliance on secondary/weak sources
- Logical gaps in synthesis chains

### 4. Intellectual Rigor
*Does the work demonstrate systematic thinking?*

**Tests:**
- **First Principles**: Reasons from fundamentals or accepts conventions?
- **Alternatives**: Competing explanations considered?
- **Assumptions**: Hidden assumptions exposed?
- **Falsifiability**: Claims testable and refutable?

**Common Pitfalls:**
- Reasoning by analogy when first principles needed
- Ignoring obvious alternative explanations
- Building on unexamined assumptions
- Confirmation bias in evidence selection

### 5. Innovation Opportunity
*Does the work maximize opportunities for novel insights?*

**Tests:**
- **Inventiveness**: Questions others haven't thought to ask?
- **Cross-Domain**: Insights from multiple fields synthesized?
- **Paradigm Challenge**: Fundamental assumptions questioned?
- **Practical Application**: Theory connected to action?

**Missed Opportunities:**
- Obvious questions left unasked
- Failure to connect related domains
- Acceptance of field limitations without challenge
- Incremental thinking where breakthrough is possible

## Output Format

```markdown
## Critical Assessment: [Document Name]

### Executive Summary
**Overall Quality**: [Score /100]
**Recommendation**: [Accept / Revise / Reject]

**Primary Strengths:**
1. [Strength]
2. [Strength]

**Critical Weaknesses:**
1. [Weakness requiring attention]
2. [Weakness requiring attention]

---

### Dimension Scores

| Dimension | Score | Key Issues |
|-----------|-------|------------|
| Question Architecture | /40 | [Brief] |
| Decomposition Rigor | /16 | [Brief] |
| Answer Completeness | /100 | [Brief] |
| Intellectual Rigor | /20 | [Brief] |
| Innovation Opportunity | /25 | [Brief] |

---

### Detailed Findings

#### Question Architecture
[Analysis of central question clarity, validity, scope, value]

#### Decomposition Rigor
[MECE analysis, synthesis pathway assessment]

#### Answer Completeness
[Evidence quality, logical chain analysis]

#### Intellectual Rigor
[First principles, alternatives, assumptions]

#### Innovation Opportunities
[Missed questions, cross-domain connections, paradigm challenges]

---

### Improvement Roadmap

**Priority 1: Critical Fixes** (Must address)
- [Issue and fix]

**Priority 2: Significant Enhancements** (Should address)
- [Enhancement]

**Priority 3: Innovation Opportunities** (Could address)
- [Opportunity]

---

### Specific Recommendations
1. [Actionable recommendation]
2. [Actionable recommendation]
3. [Actionable recommendation]
```

## Quick Assessment Checklist

- [ ] Central question clearly stated
- [ ] Question is the right one to ask
- [ ] Scope is appropriate
- [ ] Decomposition follows clear theory
- [ ] No significant gaps or overlaps
- [ ] Claims supported by evidence
- [ ] Logic chain is complete
- [ ] Assumptions are examined
- [ ] Alternatives are considered
- [ ] Practical applications explored

## Assessment Principles

1. **Systematic**: Use explicit criteria, not intuition
2. **Constructive**: Pair weaknesses with improvement paths
3. **Evidence-Based**: Require evidence for criticisms
4. **Innovation-Focused**: Seek missed opportunities
5. **Objective**: Apply same standards to all ideas
