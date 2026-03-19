# Phase 1: Quality Assessment Knowledge

Use this knowledge to answer questions about how issues are quality-scored, what the verdict thresholds mean, and how to improve an issue's score.

## Scoring Rubric

Issues are scored across 5 dimensions, each 0-20 points (total 0-100).

### 1. Clarity (0-20)
How clearly is the problem or request stated?
- **0-4**: Vague, ambiguous, or incomprehensible
- **5-9**: General idea is present but important details are unclear
- **10-14**: Problem is understandable but could be more precise
- **15-17**: Clear problem statement with good detail
- **18-20**: Crystal clear, unambiguous problem description

### 2. Reproducibility (0-20)
Can someone act on this issue? Scored differently by issue type:

**For bugs:**
- **0-4**: No reproduction steps whatsoever
- **5-9**: Vague description of what happens but no actionable steps to reproduce
- **10-14**: Some steps exist but are incomplete (missing preconditions, expected vs. actual, or environment)
- **15-17**: Good step-by-step reproduction with minor gaps
- **18-20**: Complete reproduction steps including preconditions, exact steps, expected result, and actual result

**For feature requests / enhancements:**
- **0-4**: No acceptance criteria, no examples, no description of desired behavior
- **5-9**: Vague description of desired outcome but no concrete criteria
- **10-14**: Some acceptance criteria or examples exist but are incomplete
- **15-17**: Good acceptance criteria or user stories with minor gaps
- **18-20**: Detailed acceptance criteria, examples, or mockups that fully define expected behavior

**For questions:**
- Score based on how well the question is formulated and whether enough context is given for someone to answer it. A well-formed question with specific context should score 15+.

### 3. Context (0-20)
Is there environment, version, impact, or background information?
- **0-4**: No context at all
- **5-9**: Minimal context (e.g., just mentions BC but no version)
- **10-14**: Some context provided (e.g., version OR environment, but not both)
- **15-17**: Good context including version, environment, and some impact info
- **18-20**: Complete context with version, environment, impact assessment, and affected users

### 4. Specificity (0-20)
Is the scope well-defined? Does the issue focus on one thing?
- **0-4**: Overly broad, covers multiple unrelated things, or too vague to scope
- **5-9**: Somewhat broad but a general area is identifiable
- **10-14**: Reasonable scope but boundaries could be clearer
- **15-17**: Well-scoped with clear boundaries
- **18-20**: Precisely scoped, focused on one specific problem or feature

### 5. Actionability (0-20)
Can a developer start working on this without significant back-and-forth?
- **0-4**: Cannot start work — critical information is missing
- **5-9**: Would need multiple rounds of clarification before starting
- **10-14**: Could start with some assumptions, but key decisions are unclear
- **15-17**: Mostly ready, minor clarifications might be needed
- **18-20**: Ready for immediate development with no ambiguity

## Verdict Thresholds

| Total Score | Verdict | What happens |
|-------------|---------|-------------|
| 75-100 | **READY** | Full triage (Phase 2) runs |
| 40-74 | **NEEDS WORK** | Needs-info comment posted, Phase 2 still runs |
| 0-39 | **INSUFFICIENT** | Needs-info comment posted, Phase 2 skipped |

## Missing Information Guidelines

For issues scoring below 75, the agent lists specific missing items. Good missing-info items are:
- **Specific**: "Business Central version number" not "more details"
- **Actionable**: "Steps to reproduce the sync failure" not "please elaborate"
- **Measurable**: "Expected number of products after sync" not "clarify expectations"

**Bad examples:**
- "More information needed"
- "Please add more details"

**Good examples:**
- "Missing: BC version number, steps to reproduce the sync failure, expected product count after sync"
- "Acceptance criteria needed: what should the UI look like after the change?"

## How to Improve an Issue's Score

When users ask how to improve their issue, recommend these specific additions:

### To improve Clarity (+)
- Add a one-sentence problem statement at the top
- Separate the problem description from the solution proposal
- Use concrete nouns instead of pronouns ("the Sales Order page" not "it")

### To improve Reproducibility (+)
- **Bugs**: Add numbered steps (1. Go to... 2. Click... 3. Enter...), expected result, actual result
- **Features**: Add acceptance criteria as a checklist, or provide a user story format

### To improve Context (+)
- Add BC version (e.g., "BC 24.1")
- Specify environment (SaaS/On-Prem, sandbox/production)
- Describe impact (how many users affected, business process blocked)

### To improve Specificity (+)
- Split multi-topic issues into separate issues
- Define clear boundaries ("only the Sales Order page, not Sales Quote")
- Focus on one behavior change per issue

### To improve Actionability (+)
- Include relevant AL object names if known (e.g., "Table 36 Sales Header")
- Reference specific fields or actions
- Describe the expected development approach if you have one
