---
name: prd
description: Complete PRD workflow - create design documents, generate implementation tasks, and execute them step-by-step. Use for planning and implementing new features.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "[design|tasks|implement] or feature description"
---

# PRD Workflow

Complete product requirements workflow: Design -> Tasks -> Implementation.

## Usage

```
/prd                          # Start full workflow from design phase
/prd design                   # Create/refine design document only
/prd tasks                    # Generate tasks from existing design.md
/prd implement                # Execute ALL tasks from tasks.md
/prd implement Phase 2        # Execute only Phase 2
/prd implement 2.3            # Start from sub-task 2.3
/prd "feature name"           # Start full workflow for specific feature
```

## Routing

Based on the argument provided, load and follow the appropriate stage file:

### If argument starts with "design"

Read and follow `plugins/workflow/skills/prd/prd-design.md`. Pass any remaining text as the feature description.

### If argument starts with "tasks"

Read and follow `plugins/workflow/skills/prd/prd-tasks.md`. Pass any remaining text as the path to design.md.

### If argument starts with "implement"

Read and follow `plugins/workflow/skills/prd/prd-implement.md`. Pass any remaining text as the **scope**:

- No additional text = run all phases
- A phase name/number (e.g., `Phase 2`, `3`) = run only that phase
- A sub-task number (e.g., `2.3`) = start from that specific sub-task

### If no stage keyword (or a feature description)

Start the **full workflow** by reading and following each stage in sequence:

1. **Design** - Read and follow `plugins/workflow/skills/prd/prd-design.md`
   - Complete the design document before proceeding
2. **Tasks** - Read and follow `plugins/workflow/skills/prd/prd-tasks.md`
   - Generate task list from the design document
3. **Implement** - Read and follow `plugins/workflow/skills/prd/prd-implement.md`
   - Execute tasks continuously with sub-agent parallelization

## Stage Files

| Stage | Skill | File |
|-------|-------|------|
| Design | `/prd design` | `plugins/workflow/skills/prd/prd-design.md` |
| Tasks | `/prd tasks` | `plugins/workflow/skills/prd/prd-tasks.md` |
| Implement | `/prd implement` | `plugins/workflow/skills/prd/prd-implement.md` |

## File Locations

| File | Location |
|------|----------|
| Design doc | `/docs/features/[feature-name]/design.md` |
| Task list | `/docs/features/[feature-name]/tasks.md` |
| Completion summaries | `/docs/tasks/TASK-X.Y.Z-...-COMPLETION-SUMMARY.md` |

## Critical Rules

1. **Always read the stage file** - Do not attempt to run a stage from memory; read the full stage file for current instructions
2. **Enter plan mode for design and tasks phases** - Enter plan mode before starting either `prd-design.md` or `prd-tasks.md`. Plan mode ensures thorough codebase exploration using read-only tools before writing. Exit plan mode once the output is ready.
   - This applies even when flowing between phases in the same session. Having context loaded from a prior phase is NOT a reason to skip plan mode for tasks.
3. **Design before tasks** - Never generate tasks without a design document
4. **Tasks before implementation** - Never implement without a task list
5. **Annotate parallel groups in tasks** - Every task list must identify which sub-tasks can run concurrently. Group independent sub-tasks under `**Parallel Group X**` markers. If no parallelization is possible, explicitly state why.
6. **Target audience is a junior developer** - Be explicit in all outputs
