---
name: summarize
description: Create concise summaries capturing main points, arguments, evidence, and conclusions. Preserves author intent without interpretation.
allowed-tools: Read, Glob
argument-hint: [file path or paste content] [brief|standard|detailed]
---

# Document Summarization

Create comprehensive yet concise summaries that capture a document's essence.

## When to Use

- Summarizing long documents, reports, or articles
- Creating executive summaries
- User asks to "summarize", "give me the key points", or "TLDR"

## Analysis Steps

### 1. Identify Core Elements
- Main purpose/thesis
- Key arguments or points
- Supporting evidence
- Conclusions drawn

### 2. Determine Hierarchy
- What's most important?
- What's supporting detail?
- What can be omitted?

### 3. Preserve Intent
- Maintain author's original meaning
- Don't inject interpretation
- Keep context intact

## Summary Length Options

| Option | Length | Content |
|--------|--------|---------|
| **Brief** | 1-2 paragraphs | Core thesis + 3 key points |
| **Standard** | 1 page | All major points with brief evidence |
| **Detailed** | 2-3 pages | Comprehensive with key quotes |

Default to **Standard** if not specified.

## Output Format

```markdown
## Summary

### One-Sentence Summary
[Single sentence capturing the document's core message]

### Key Points
1. **[Point 1]**: [Brief explanation]
2. **[Point 2]**: [Brief explanation]
3. **[Point 3]**: [Brief explanation]

### Main Arguments
- **[Argument]**: [Supporting evidence in brief]

### Conclusions
[What the author concludes or recommends]

### Context
- **Audience**: [Who this is for]
- **Purpose**: [Why it was written]
- **Scope**: [What it covers/doesn't cover]

---

**Document Stats**
- Original length: [X words/pages]
- Summary length: [X words]
- Compression ratio: [X%]
```

## Guidelines

### Do:
- Start with the most important information
- Use the author's terminology
- Preserve the logical structure
- Include key data points and evidence
- Note any limitations or caveats mentioned

### Don't:
- Add your own opinions or interpretations
- Include irrelevant details
- Change the author's conclusions
- Omit important qualifications
- Misrepresent the scope or claims

## Example Usage

**Brief summary:**
```
/summarize docs/research/market-analysis.md brief
```

**Standard summary (default):**
```
/summarize docs/features/auth/design.md
```

**Detailed summary:**
```
/summarize docs/architecture/system-overview.md detailed
```

## For Technical Documents

When summarizing technical docs, also include:
- **Technologies mentioned**: List of tools/frameworks
- **Key decisions**: Important architectural choices
- **Dependencies**: External requirements
- **Risks noted**: Any concerns raised

## For Business Documents

When summarizing business docs, also include:
- **Stakeholders**: Who is affected
- **Timeline**: Any dates or deadlines
- **Budget/Resources**: Financial implications
- **Action items**: Next steps required
