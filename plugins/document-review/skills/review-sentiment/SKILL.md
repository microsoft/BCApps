---
name: review-sentiment
description: Analyze document sentiment - positive, negative, neutral tones with supporting evidence from word choice and context.
allowed-tools: Read, Glob
argument-hint: [file path or paste content]
---

# Sentiment Analysis

Analyze a document's emotional tone and identify supporting evidence.

## When to Use

- Reviewing customer feedback or survey responses
- Analyzing communication tone (emails, announcements)
- Evaluating marketing copy or public statements
- User asks about "tone", "sentiment", or "emotional impact"

## Analysis Steps

### 1. Determine Overall Sentiment

**Classifications:**
- **Positive**: Optimistic, supportive, enthusiastic
- **Negative**: Critical, pessimistic, concerned
- **Neutral**: Objective, balanced, factual
- **Mixed**: Contains both positive and negative elements

**Confidence Levels:**
- **High**: Clear, consistent signals throughout
- **Medium**: Some ambiguity or mixed signals
- **Low**: Difficult to determine, highly contextual

### 2. Identify Sentiment Indicators
- Word choice and connotation
- Tone markers
- Emotional language

### 3. Provide Evidence
- Quote specific sentences/paragraphs
- Explain why each example supports your classification

### 4. Analyze Contributing Factors
- How word choice shapes sentiment
- How tone reinforces or contradicts content
- How context affects interpretation

## Output Format

```markdown
## Sentiment Analysis

**Overall Sentiment**: [Positive/Negative/Neutral/Mixed]
**Confidence**: [High/Medium/Low]

### Key Indicators

| Indicator | Example | Impact |
|-----------|---------|--------|
| [Word choice] | "[quote]" | [effect] |
| [Tone marker] | "[quote]" | [effect] |

### Supporting Evidence

1. **[Sentiment type]**: "[Quote]"
   - Why: [explanation]

2. **[Sentiment type]**: "[Quote]"
   - Why: [explanation]

### Contributing Factors

- **Word Choice**: [analysis of language used]
- **Tone**: [formal/informal, warm/cold, etc.]
- **Context**: [situational factors affecting interpretation]

### Sentiment Distribution

| Section | Sentiment | Intensity |
|---------|-----------|-----------|
| [Section 1] | [Type] | [1-5] |
| [Section 2] | [Type] | [1-5] |

### Summary

[2-3 sentence synthesis of sentiment analysis]

### Recommendations

[If applicable: how to adjust tone for intended audience/purpose]
```

## Sentiment Intensity Scale

| Level | Description | Indicators |
|-------|-------------|------------|
| 1 | Very mild | Subtle hints, implied |
| 2 | Mild | Noticeable but understated |
| 3 | Moderate | Clear and consistent |
| 4 | Strong | Emphatic, repeated |
| 5 | Very strong | Dominant, pervasive |
