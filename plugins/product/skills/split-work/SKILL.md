---
name: split-work
description: Identify high-priority tasks with minimal overlap for N developers to work on simultaneously. Prevents merge conflicts.
allowed-tools: Read, Glob, Grep
argument-hint: [number of developers] or just invoke to be asked
---

# Split Work for Parallel Development

Identify high-priority tasks that N developers can work on simultaneously with minimal overlap and low merge conflict risk.

## When to Use

- Sprint planning for multiple developers
- Parallel work assignment
- User asks to "split work", "assign tasks", or "what can we work on in parallel"

## Process

### Step 1: Get Team Size
If N (number of developers) is not provided, ask:
"How many developers are available to work on tasks today?"

### Step 2: Review Tasks
Read the project's `tasks.md` or backlog to identify available tasks.

### Step 3: Analyze for Parallelization

For each potential task, evaluate:
- **File overlap**: Which files will be modified?
- **Component isolation**: Is the work contained to specific modules?
- **Dependency chains**: Does this task depend on another task's completion?
- **Test isolation**: Can changes be tested independently?

### Step 4: Select N Tasks

Choose N tasks that:
1. Are high-priority
2. Touch different files/components
3. Have no blocking dependencies on each other
4. Can be merged independently

## Output Format

```markdown
## Parallel Work Assignment

**Team Size**: [N] developers
**Task Source**: [tasks.md location]

### Recommended Assignments

#### Developer 1: [Task Name]
- **Task ID**: [X.Y]
- **Files affected**: [List key files]
- **Component**: [Module/area]
- **Dependencies**: None
- **Estimated effort**: [Points/hours]

#### Developer 2: [Task Name]
- **Task ID**: [X.Y]
- **Files affected**: [List key files]
- **Component**: [Module/area]
- **Dependencies**: None
- **Estimated effort**: [Points/hours]

[Continue for N developers...]

### Conflict Analysis

| Dev 1 Task | Dev 2 Task | Overlap Risk | Mitigation |
|------------|------------|--------------|------------|
| [Task A] | [Task B] | Low/Med/High | [Strategy] |

### Reasoning

**Why these tasks were selected:**
1. [Explanation for task selection and pairing]
2. [How overlap was minimized]
3. [Any considerations or caveats]

### Tasks NOT Recommended for Parallel Work

| Task | Reason |
|------|--------|
| [Task X] | Depends on Task Y completion |
| [Task Z] | Touches same files as Task A |
```

## Conflict Risk Assessment

| Risk Level | Criteria |
|------------|----------|
| **Low** | Different modules, no shared files |
| **Medium** | Same module, different files |
| **High** | Overlapping files, shared interfaces |

## Mitigation Strategies

For Medium-risk parallel work:
- Assign clear file ownership
- Coordinate on shared interfaces first
- Use feature flags for isolation
- Plan merge order in advance

For High-risk:
- Don't parallelize - work sequentially
- Or split task differently

## Best Practices

1. **Frontend/Backend split**: Natural isolation point
2. **Feature boundaries**: Each developer owns a complete feature
3. **Test in isolation**: Each change should be independently testable
4. **Merge frequently**: Don't let branches diverge too long
5. **Communicate**: Coordinate on shared dependencies early
