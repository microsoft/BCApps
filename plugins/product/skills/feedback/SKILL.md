---
name: feedback
description: Product feedback synthesizer - collects, analyzes, and prioritizes user feedback from multiple channels into actionable product insights.
allowed-tools: Read, Write, Edit, Glob, WebSearch, WebFetch
argument-hint: [feedback source or topic]
---

# Product Feedback Synthesizer

Expert in collecting, analyzing, and synthesizing user feedback from multiple channels into actionable product insights.

## When to Use

- Analyzing customer feedback or survey results
- Prioritizing feature requests
- Understanding user pain points
- User asks to "analyze feedback", "synthesize reviews", or "prioritize features"

## Core Capabilities

- **Multi-Channel Collection**: Surveys, interviews, support tickets, reviews, social media
- **Sentiment Analysis**: Emotion detection, satisfaction scoring, trend identification
- **Feedback Categorization**: Theme identification, priority classification, impact assessment
- **Prioritization Frameworks**: RICE, MoSCoW, Kano model application

## Analysis Process

### 1. Collection Strategy

| Channel Type | Sources |
|--------------|---------|
| **Proactive** | In-app surveys, email campaigns, user interviews |
| **Reactive** | Support tickets, reviews, social media mentions |
| **Passive** | User behavior analytics, session recordings |
| **Community** | Forums, Discord, Reddit, user groups |

### 2. Processing Pipeline
1. **Data Ingestion**: Collect from sources
2. **Cleaning**: Duplicate removal, standardization
3. **Sentiment Analysis**: Emotion detection and scoring
4. **Categorization**: Theme tagging, priority assignment
5. **Quality Assurance**: Accuracy validation, bias checking

### 3. Synthesis Methods
- **Thematic Analysis**: Pattern identification with statistical validation
- **Statistical Correlation**: Relationships between themes and outcomes
- **User Journey Mapping**: Feedback integration into experience flows
- **Priority Scoring**: Multi-criteria analysis using RICE framework

## Output Format

```markdown
## Feedback Analysis: [Topic/Period]

### Executive Summary
**Total Feedback Analyzed**: [X] items
**Overall Sentiment**: [Positive/Neutral/Negative] ([X]% confidence)
**Top Priority Theme**: [Theme]

### Sentiment Distribution

| Sentiment | Count | Percentage |
|-----------|-------|------------|
| Positive | X | X% |
| Neutral | X | X% |
| Negative | X | X% |

### Theme Analysis

#### Theme 1: [Theme Name]
- **Volume**: [X] mentions ([X]% of total)
- **Sentiment**: [Positive/Negative/Mixed]
- **Representative Quotes**:
  - "[Quote 1]"
  - "[Quote 2]"
- **Business Impact**: [High/Medium/Low]
- **Recommended Action**: [Action]

#### Theme 2: [Theme Name]
...

### Feature Request Prioritization

| Feature | RICE Score | Reach | Impact | Confidence | Effort |
|---------|------------|-------|--------|------------|--------|
| [Feature 1] | [Score] | [X] | [1-3] | [%] | [PM] |
| [Feature 2] | [Score] | [X] | [1-3] | [%] | [PM] |

### Pain Point Analysis

| Pain Point | Severity | Frequency | User Segment |
|------------|----------|-----------|--------------|
| [Pain point] | [1-5] | [X mentions] | [Segment] |

### Recommendations

**Quick Wins** (High impact, Low effort)
1. [Recommendation]

**Strategic Investments** (High impact, High effort)
1. [Recommendation]

**Monitor** (Emerging themes)
1. [Theme to watch]

### Key Verbatims

**Most Impactful Positive**
> "[Quote]" - [Source]

**Most Impactful Negative**
> "[Quote]" - [Source]

**Most Actionable Insight**
> "[Quote]" - [Source]
```

## Prioritization Frameworks

### RICE Score
```
Score = (Reach × Impact × Confidence) ÷ Effort

- Reach: Users impacted per quarter
- Impact: 0.25 (minimal) to 3 (massive)
- Confidence: 0-100%
- Effort: Person-months
```

### Kano Model Classification
| Type | Meaning | Action |
|------|---------|--------|
| **Must-Have** | Expected, dissatisfaction if missing | Prioritize |
| **Performance** | Linear satisfaction improvement | Invest |
| **Delighter** | Unexpected, creates excitement | Consider |
| **Indifferent** | Users don't care | Deprioritize |
| **Reverse** | Actually decreases satisfaction | Remove |

## Success Metrics

| Metric | Target |
|--------|--------|
| Processing Speed | <24 hours for critical issues |
| Theme Accuracy | 90%+ validated by stakeholders |
| Actionable Insights | 85% lead to decisions |
| Feature Prediction | 80% accuracy on success |
