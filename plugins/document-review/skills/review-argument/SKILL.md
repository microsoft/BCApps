---
name: review-argument
description: Evaluate argument structure, strength, premises, evidence, and logical fallacies in a document.
allowed-tools: Read, Glob
argument-hint: [file path or paste content]
---

# Argument Analysis

Evaluate the arguments in a document for structure, strength, and validity.

## When to Use

- Reviewing proposals, business cases, or persuasive documents
- Evaluating research papers or technical arguments
- User asks to "analyze arguments", "check logic", or "evaluate reasoning"

## Analysis Steps

### 1. Identify Main Arguments
- What claims is the author making?
- What is the central thesis?
- How are arguments structured?

### 2. Evaluate Each Argument
- **Premises**: Are they stated or implied? Valid?
- **Logic**: Does the conclusion follow from the premises?
- **Evidence**: What support is provided?
- **Strength**: Compelling, adequate, weak, or flawed?

### 3. Identify Counterarguments
- Does the author address opposing views?
- Are counterarguments fairly represented?
- How effectively are they rebutted?

### 4. Assess Logical Fallacies

Common fallacies to check:
- **Ad Hominem**: Attacking the person instead of the argument
- **Straw Man**: Misrepresenting opponent's position
- **False Dichotomy**: Presenting only two options when more exist
- **Appeal to Authority**: Using authority instead of evidence
- **Slippery Slope**: Assuming chain of events without justification
- **Circular Reasoning**: Conclusion assumed in premises
- **Red Herring**: Introducing irrelevant information

## Output Format

```markdown
## Argument Analysis

**Central Thesis**: [One sentence summary]

### Main Arguments

#### Argument 1: [Title]

- **Claim**: [What is being argued]
- **Premises**: [List supporting assumptions]
- **Evidence**: [What support is provided]
- **Strength**: [Strong/Adequate/Weak] - [Why]
- **Fallacies**: [None/List any found]

#### Argument 2: [Title]
...

### Counterarguments Addressed

| Counterargument | Author's Response | Effectiveness |
|-----------------|-------------------|---------------|
| [Objection] | [How addressed] | [Strong/Weak] |

### Logical Structure Assessment

- **Coherence**: [How well arguments connect]
- **Completeness**: [Gaps in reasoning]
- **Persuasiveness**: [Overall effectiveness]

### Summary

[Overall assessment of argument quality]

### Recommendations

1. [How to strengthen weak arguments]
2. [Missing evidence to add]
3. [Fallacies to address]
```
