---
name: review-decomposition
description: Evaluate how a complex question or problem is broken down. Tests for MECE coverage, synthesis viability, and actionability.
allowed-tools: Read, Glob
argument-hint: [file path or paste content]
---

# Question Decomposition Analysis

Analyze how a document breaks down complex questions or problems using hypothesis-driven methodology.

## When to Use

- Reviewing PRDs, research plans, or strategy documents
- Evaluating problem statements and solution approaches
- User asks to "check structure", "analyze breakdown", or "evaluate decomposition"

## Core Principle

Question decomposition is theory building. A good decomposition proposes:
1. The question's essential structure
2. How different aspects relate
3. How sub-answers combine into complete answers
4. The most effective investigation sequence

## Analysis Steps

### 1. Identify the Decomposition Theory
- What is the central question/problem?
- How has it been broken into sub-questions?
- What pattern was used (component, process, tension, stakeholder)?

### 2. Apply Validation Tests

**MECE Test (Mutually Exclusive, Collectively Exhaustive)**
- Do sub-questions overlap significantly?
- Do sub-questions cover ALL aspects?

**Synthesis Viability Test**
- Can sub-answers logically combine to answer the parent?
- Is the synthesis mechanism clear?

**Actionability Test**
- Can each sub-question be answered with available methods?
- Are questions concrete enough to investigate?

**Independence Test**
- Can sub-questions be answered independently?
- Are there circular dependencies?

### 3. Identify Common Failures

| Failure | Symptom | Fix |
|---------|---------|-----|
| Level Confusion | Mixed abstraction in same tier | Consistent abstraction tests |
| Hidden Assumptions | Works only with unstated assumptions | Make assumptions explicit |
| Solution Bias | Decomposition assumes a particular answer | Allow multiple valid answers |
| Incomplete Coverage | Important aspects emerge late | Use multiple patterns |

## Output Format

```markdown
## Decomposition Analysis

**Central Question**: [The main question being decomposed]
**Decomposition Pattern**: [Component/Process/Tension/Stakeholder]

### Structure Map

```
[Central Question]
├── Sub-Question 1
│   ├── Sub-Sub 1.1
│   └── Sub-Sub 1.2
├── Sub-Question 2
└── Sub-Question 3
```

### Validation Test Results

| Test | Pass/Fail | Notes |
|------|-----------|-------|
| MECE - Mutual Exclusivity | ✓/✗ | [Issues] |
| MECE - Collective Exhaustion | ✓/✗ | [Gaps found] |
| Synthesis Viability | ✓/✗ | [Can answers combine?] |
| Actionability | ✓/✗ | [Can each be answered?] |
| Independence | ✓/✗ | [Dependencies found] |

### Detailed Findings

#### Overlaps Found
- [Sub-question X] and [Sub-question Y] both address...

#### Gaps Identified
- Missing: [What's not covered]

#### Synthesis Issues
- [How answers fail to combine]

#### Dependency Problems
- [Circular or blocking dependencies]

### Alternative Decomposition

If the current decomposition fails tests, suggest alternatives:

**Alternative Approach: [Pattern Name]**
```
[Central Question]
├── [Better Sub-Question 1]
├── [Better Sub-Question 2]
└── [Better Sub-Question 3]
```

### Summary

**Decomposition Quality**: [Excellent/Good/Needs Work/Poor]
**Critical Issue**: [Most important problem to fix]
**Key Recommendation**: [Primary improvement]
```

## Decomposition Patterns

### Component Analysis
"Understand by examining constituent parts"
- Best for: Systems, processes, concepts with clear parts

### Process Analysis
"Understand by mapping steps/workflow"
- Best for: Procedures, methodologies, sequences

### Tension Resolution
"Understand by resolving inherent conflicts"
- Best for: Trade-offs, competing priorities, paradoxes

### Stakeholder Perspectives
"Understand by addressing different viewpoints"
- Best for: Multi-audience documents, policies, strategies
