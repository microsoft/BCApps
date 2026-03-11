---
name: review-structure
description: Evaluate document structure, organization, information flow, and whether organization serves the document's purpose.
allowed-tools: Read, Glob
argument-hint: [file path or paste content]
---

# Structure and Organization Analysis

Analyze how a document is structured and whether the organization serves its purpose.

## When to Use

- Reviewing document drafts before publishing
- Evaluating technical documentation or guides
- Improving readability and navigation
- User asks about "structure", "organization", or "flow"

## Analysis Steps

### 1. Map the Structure
- Identify major sections
- Note hierarchy (headings, subheadings)
- Document the flow of information

### 2. Evaluate Components

| Component | Questions |
|-----------|-----------|
| **Introduction** | Does it set up the content effectively? |
| **Body** | Is information logically organized? |
| **Conclusion** | Does it synthesize and close appropriately? |
| **Transitions** | Are connections between sections clear? |

### 3. Assess Effectiveness
- Does structure serve the document's purpose?
- Is information easy to find?
- Does organization enhance or hinder comprehension?

### 4. Identify Issues
- Structural gaps or redundancies
- Misplaced content
- Missing sections

## Output Format

```markdown
## Structure Analysis

### Document Map

```
[Title]
├── [Section 1]
│   ├── [Subsection 1.1]
│   └── [Subsection 1.2]
├── [Section 2]
│   ├── [Subsection 2.1]
│   └── [Subsection 2.2]
└── [Section 3]
    └── [Subsection 3.1]
```

### Component Evaluation

| Component | Present | Effectiveness | Notes |
|-----------|---------|---------------|-------|
| Introduction | Yes/No | Strong/Adequate/Weak | [Notes] |
| Clear sections | Yes/No | Strong/Adequate/Weak | [Notes] |
| Logical flow | Yes/No | Strong/Adequate/Weak | [Notes] |
| Transitions | Yes/No | Strong/Adequate/Weak | [Notes] |
| Conclusion | Yes/No | Strong/Adequate/Weak | [Notes] |

### Information Flow

- **Sequence**: [How information progresses]
- **Dependencies**: [What relies on what]
- **Gaps**: [Missing connections]

### Structural Issues

1. **[Issue]**: [Location] - [Recommendation]
2. **[Issue]**: [Location] - [Recommendation]

### Suggested Restructure

If significant changes needed:
```
[Proposed New Structure]
├── [Reorganized Section 1]
├── [New Section]
└── [Reorganized Section 2]
```

### Summary

**Overall Organization**: [Excellent/Good/Adequate/Poor]
**Key Strength**: [What works best]
**Key Improvement**: [Most impactful change]
```

## Common Structure Patterns

### Problem-Solution
1. Problem description
2. Causes/analysis
3. Solution proposal
4. Implementation
5. Expected outcomes

### Chronological
1. Background/history
2. Current state
3. Future direction
4. Action items

### Comparative
1. Introduction to comparison
2. Option A details
3. Option B details
4. Analysis/recommendation

### Hierarchical (General to Specific)
1. Overview/summary
2. Major concepts
3. Details/specifics
4. Examples/applications

## Red Flags to Watch For

- **Buried Lead**: Important info hidden deep in document
- **Orphan Content**: Sections that don't connect to others
- **Redundancy**: Same information repeated unnecessarily
- **Missing Context**: Jumping into details without setup
- **Weak Transitions**: Abrupt topic changes
- **Inconsistent Depth**: Some sections much deeper than others
