---
name: decompose
description: Break complex questions or problems into testable sub-questions using hypothesis-driven methodology. Applies MECE and synthesis testing.
allowed-tools: Read, Glob
argument-hint: [complex question or problem to decompose]
---

# Hypothesis-Driven Question Decomposition

Break complex questions into testable sub-questions using scientific methodology.

## When to Use

- Tackling complex, ambiguous problems
- Planning research or investigation
- Breaking down large initiatives
- User asks to "decompose", "break down", or "analyze this problem"

## Core Principle

Question decomposition is theory building. You're proposing a hypothesis about:
1. The question's essential structure
2. How different aspects relate
3. How sub-answers combine into a complete answer
4. The most effective investigation sequence

## Decomposition Process

### Step 1: Generate Initial Theory

Develop a hypothesis about the question's structure:

```markdown
**Central Question**: [The question to decompose]

**Initial Decomposition Theory**:
"This question likely decomposes along these axes:
1. [First dimension]
2. [Second dimension]
3. [Third dimension]"
```

### Step 2: Apply Decomposition Patterns

| Pattern | Theory | Best For |
|---------|--------|----------|
| **Component** | Understand by examining parts | Systems, concepts |
| **Process** | Understand by mapping sequence | Workflows, methods |
| **Tension** | Understand by resolving conflicts | Trade-offs, paradoxes |
| **Stakeholder** | Understand by addressing viewpoints | Multi-audience problems |

### Step 3: Test the Hypothesis

| Test | Question | Failure Response |
|------|----------|------------------|
| **MECE** | Mutually Exclusive, Collectively Exhaustive? | Merge overlaps, add gaps |
| **Synthesis** | Can sub-answers combine to answer parent? | Restructure for clean paths |
| **Actionability** | Can each sub-question be answered? | Further decompose |
| **Independence** | Can sub-questions be answered independently? | Break circular dependencies |

### Step 4: Iterate

As you investigate, discover:
- Missing questions (gaps in original theory)
- Wrong abstractions (questions that don't fit reality)
- Hidden dependencies (connections you missed)
- Emergent patterns (better organization)

## Question Type Templates

### "How" Questions (Process/Method)
1. What is the current state/problem?
2. What is the desired state/solution?
3. What steps connect current to desired?
4. What principles guide the transition?
5. How do we validate success?

### "What" Questions (Definition/Classification)
1. What are the essential characteristics?
2. What are the boundaries/non-examples?
3. What categories or types exist?
4. What relationships connect to other concepts?
5. What implications follow?

### "Why" Questions (Causal/Justification)
1. What is the phenomenon requiring explanation?
2. What are the proposed causal factors?
3. What evidence supports each factor?
4. How do factors interact?
5. What alternative explanations exist?

## Output Format

```markdown
## Decomposition Analysis

### Central Question
[The question being decomposed]

### Decomposition Theory
"This question decomposes along [pattern] because..."

### Question Hierarchy

```
[Central Question]
├── Sub-Question 1: [Question]
│   ├── 1.1: [Sub-sub question]
│   └── 1.2: [Sub-sub question]
├── Sub-Question 2: [Question]
│   └── 2.1: [Sub-sub question]
└── Sub-Question 3: [Question]
```

### Validation Tests

| Test | Result | Notes |
|------|--------|-------|
| MECE - Mutual Exclusivity | ✓/✗ | [Any overlaps] |
| MECE - Collective Exhaustion | ✓/✗ | [Any gaps] |
| Synthesis Viability | ✓/✗ | [Can answers combine?] |
| Actionability | ✓/✗ | [Can each be answered?] |
| Independence | ✓/✗ | [Dependencies?] |

### Synthesis Path
[How sub-answers will combine to answer the parent question]

### Investigation Sequence
1. Start with: [Which sub-question first and why]
2. Then: [Next sub-question]
3. Finally: [Last sub-question]
```

## Common Failures

| Failure | Symptom | Fix |
|---------|---------|-----|
| Level Confusion | Mixed abstraction in same tier | Consistent abstraction tests |
| Hidden Assumptions | Works only with unstated assumptions | Make assumptions explicit |
| Solution Bias | Decomposition assumes specific answer | Allow multiple valid answers |
| Incomplete Coverage | Important aspects emerge late | Use multiple patterns |

## Success Criteria

Good decompositions are:
1. **Testable**: You can verify if it works
2. **Revisable**: Structure can evolve
3. **Clear**: Logic is transparent
4. **Complete**: All aspects addressed
5. **Efficient**: Minimal redundancy
