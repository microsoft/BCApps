---
name: prd-tasks
description: Generate implementation task lists from design documents with parallelization annotations
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "path to design.md"
---

# Rule: Generating a Task List from a Design Document

> **Usage**: Point to a design.md file, generate parent tasks with documentation refs, then sub-tasks with parallelization annotations.

## Prerequisites

**MANDATORY - STOP**: You MUST enter plan mode before doing ANY task generation work. Do NOT skip this step even if you already have context from a prior phase (e.g., flowing from design into tasks). Call the EnterPlanMode tool NOW, before proceeding. Use plan mode to: re-read the design document, explore the codebase for existing patterns, and structure the task list with parallel groups. Exit plan mode only when the full task list is ready to be written. **If you generate tasks without entering plan mode first, the output will be rejected.**

**FIRST**: Read `.github/copilot/project-config.md` for feature toggles:

- **Azure DevOps Integration**: If OFF, skip all ADO Feature links and SOA prefixes
- **Memory Bank**: If OFF, skip memory bank updates
- **GitHub Projects**: If OFF, skip GitHub issue creation

**SECOND**: Always load and follow rules in `.github/copilot/task-workflow.md`.

## Goal

Create a detailed, step-by-step task list in Markdown format based on an existing design document. The task list should guide a junior developer through implementation.

**IMPORTANT**: All generated tasks MUST follow the rules defined in `.github/copilot/task-workflow.md`, including:

- File location conventions (`/docs/features/[feature-name]/tasks.md` and `design.md`)
- Timestamp tracking format (Phase Started, Last Updated, Phase Completed, Phase Duration)
- Task status markers (`[ ]` not started, `[>]` in progress, `[x]` completed)
- Documentation update requirements (both tasks.md and design.md must be updated)
- **If ADO = ON**: Azure DevOps Feature-level tracking (phases tracked in ADO, individual tasks in tasks.md)

**DOCUMENTATION HIERARCHY**: Documentation can exist at any depth in the repository, not just predefined levels. Every `docs/` directory at any path uses the same flat file pattern defined in `.github/copilot/documentation-organization.md`. Common levels include:

- **Project-Wide** (`/docs/`) - System architecture, features, cross-component concerns
- **Technical Component** (`/backend/docs/`, `/frontend/docs/`) - Component-specific architecture and implementation
- **Module/Package** (`/[any-path]/docs/`) - Module-specific documentation co-located with code
- **Deep Modules** (`/[component]/src/[module]/docs/`) - Specific service, utility, or feature module docs

The hierarchy is n-deep. For any task, documentation discovery starts at the directory closest to the code being modified and walks up through every parent directory to the project root, collecting relevant docs at each level. See `.github/copilot/documentation-organization.md` for complete rules.

## Output

- **Format:** Markdown (`.md`)
- **Location:** `/docs/features/[feature-name]/`
- **Filename:** `tasks.md`

## Process

1. **Receive Design Document Reference:** The user provides a path to a design document (e.g., `/docs/features/[feature-name]/design.md`). If not provided, use Glob to find design.md files and ask which one to use.
2. **Analyze Design Document:** Read and analyze the functional requirements, user stories, and other sections of the specified design document.
3. **Generate Parent Tasks:** Based on the design document analysis, generate the main, high-level tasks required to implement the feature. Use your judgement on how many high-level tasks to use.
4. **Identify Relevant Documentation:** For each parent task, determine which directories/files the task will create or modify, then walk the directory tree from the closest `docs/` to the project root, collecting documentation at every level. Use Glob to discover docs:
   - Start at the **nearest docs/** to the code being touched (e.g., `app/client/src/components/calendar/docs/`)
   - Walk **up** through each parent: `app/client/src/components/docs/`, `app/client/src/docs/`, `app/client/docs/`, `app/docs/`, `docs/`
   - At each level, check for any of the standard category files defined in `.github/copilot/documentation-organization.md` (`architecture.md`, `implementation.md`, `setup.md`, `testing.md`, `deployment.md`, `features.md`, `tasks.md`, `troubleshooting.md`, `research.md`, `onboarding.md`, `misc.md`, `CLAUDE.md`) and include any that are relevant to the task
   - Also include the **feature design document** and any **completion summaries** from related prior work
   - **Do NOT include source code files** (`.ts`, `.tsx`, `.py`, etc.) in Relevant Documentation. Code references go stale as earlier tasks create and modify files. The AI discovers current code at implementation time via Glob/Grep. If a task modifies a specific pre-existing file, call it out in the sub-task description instead
   - List all discovered files under a `**Relevant Documentation:**` section **for EVERY parent task (X.0) in the phase - not just the first one**. Each parent task may touch different files and directories, so documentation discovery must be repeated per task.
   - Order from most specific (closest to code) to most general (project root)
   - Follow the hierarchy rules in `.github/copilot/documentation-organization.md`
5. **Generate Sub-Tasks:** Break down each parent task into smaller, actionable sub-tasks necessary to complete the parent task. Ensure sub-tasks logically follow from the parent task and cover the implementation details implied by the design document.
6. **Add Component Documentation Tasks:** For each phase that creates or modifies code in a technical component (backend, frontend, database, etc.), add a sub-task to create or update the corresponding `[component]/docs/` flat files following `.github/copilot/documentation-organization.md`. Place this sub-task after the implementation work but before the completion summary.
7. **Annotate Parallel Groups:** Review all sub-tasks and group those that can execute concurrently under `**Parallel Group**` markers. See the **Sub-Agent Parallelization** section below.
8. **Save Task List:** Save the generated document in the same `/docs/features/[feature-name]/` directory as the design document with the filename `tasks.md`.

## Output format

```markdown
## Tasks

### Phase 1: [Phase Name]

**ADO Feature**: [SOA Phase 1: Phase Name - #WORKITEM_ID](https://dev.azure.com/...)  <!-- Only if ADO = ON -->
**Status**: Not Started
**Progress**: 0/X tasks complete (0%)
**Phase Started**: TBD
**Last Updated**: TBD        <!-- Only if ADO = ON -->
**Phase Completed**: TBD
**Phase Duration**: TBD      <!-- Only if ADO = ON -->

- [ ] 1.0 Parent Task Title
  - **Relevant Documentation:**
    - `app/client/src/components/docs/implementation.md` - Existing component patterns and usage
    - `app/client/docs/architecture.md` - Client component hierarchy, routing, state management
    - `app/client/docs/implementation.md` - Existing components, API client patterns
    - `docs/features/[feature-name]/design.md` - Feature requirements and design decisions
    - `docs/architecture.md` - System-wide architecture overview
  - [ ] 1.1 [Setup sub-task - must complete before parallel group]
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - **Parallel Group A** (after 1.1 completes):
    - [ ] 1.2 [Independent sub-task]
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
    - [ ] 1.3 [Independent sub-task]
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
  - [ ] 1.4 [Integration sub-task - after Parallel Group A completes]
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 1.5 Create/update component documentation
    - Create/update `[component]/docs/architecture.md` - design decisions, data model, patterns used
    - Create/update `[component]/docs/implementation.md` - key files created, usage examples, API details
    - Create/update `[component]/docs/setup.md` - how to install, configure, and run this component
    - Create/update `[component]/docs/CLAUDE.md` - overview and pointers to other doc files
    - **Do NOT use README.md** - use CLAUDE.md for orientation and pointers
    - Follow flat file pattern per `.github/copilot/documentation-organization.md`
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 1.6 Create phase completion summary
    - Create `docs/tasks/TASK-1.0-PHASE-NAME-COMPLETION-SUMMARY.md`
    - Include: what was implemented, design decisions, key files created, testing done
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD

- [ ] 2.0 Second Parent Task Title (example - showing that EVERY parent task gets its own Relevant Documentation section)
  - **Relevant Documentation:**
    - `app/server/src/services/docs/implementation.md` - Service patterns and usage (closest to code being modified)
    - `app/server/docs/architecture.md` - Server architecture patterns
    - `docs/features/[feature-name]/design.md` - Feature requirements and design decisions
    - `docs/architecture.md` - System-wide architecture overview
  - [ ] 2.1 [First sub-task]
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 2.2 [Second sub-task]
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 2.3 Create/update component documentation
    - Create/update `[component]/docs/architecture.md`
    - Create/update `[component]/docs/implementation.md`
    - Follow flat file pattern per `.github/copilot/documentation-organization.md`
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 2.4 Create phase completion summary
    - Create `docs/tasks/TASK-2.0-PHASE-NAME-COMPLETION-SUMMARY.md`
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
```

**Key Requirements** (per task-workflow.md and project-config.md):

- Phase metadata: Status, Progress, Phase Started, Phase Completed
- Task status markers: `[ ]` (not started), `[>]` (in progress), `[x]` (completed)
- Timestamp format: `YYYY-MM-DD HH:MM:SS UTC+-X`
- Each sub-task includes Started, Completed, Duration fields (TBD initially)
- Relevant Documentation section under each parent task
- Component documentation tasks per `.github/copilot/documentation-organization.md`
- Completion summaries go in `docs/tasks/TASK-X.Y.Z-TASK-NAME-COMPLETION-SUMMARY.md`
- **If ADO = ON**: Include ADO Feature link with SOA prefix, Last Updated, Phase Duration

## Sub-agent parallelization

When generating sub-tasks, actively look for opportunities to execute work in parallel using sub-agents. This dramatically reduces implementation time.

### How to annotate parallelization

Group parallelizable sub-tasks with a `**Parallel Group**` marker. Sub-tasks within the same parallel group can be delegated to sub-agents and executed simultaneously. Sub-tasks outside a parallel group must run sequentially.

### Rules for parallelization

1. **Identify the dependency chain first** - Map which sub-tasks produce outputs that others consume
2. **Group independent tasks** - Any tasks that only depend on the same prior task (not on each other) can be grouped
3. **Be conservative** - When in doubt about a dependency, keep tasks sequential
4. **Shared setup goes first** - Tasks like "define interfaces" or "create project structure" must complete before parallel groups that depend on them
5. **Integration goes last** - Tasks that combine outputs of parallel work must follow their parallel group
6. **Aim for maximum parallelism** - Prefer smaller, focused sub-tasks that are independently executable over large monolithic ones

## Validation checklist

**Before saving tasks.md, verify ALL of the following:**

- [ ] **Parallel groups annotated** - Did you identify and annotate which sub-tasks can run concurrently? Every task list MUST have `**Parallel Group**` markers where independent work exists. If the entire task list is truly sequential, add a note explaining why.
- [ ] **Dependencies are explicit** - Does each parallel group state what must complete before it starts (e.g., "after 1.1 completes")?
- [ ] **Integration tasks follow parallel groups** - Are wiring, testing, and validation tasks placed AFTER their parallel groups?
- [ ] **Phase metadata present** - Does each phase have Status, Progress, Phase Started, Phase Completed fields?
- [ ] **Sub-task timestamps** - Does every sub-task have Started, Completed, Duration fields (TBD initially)?
- [ ] **Relevant documentation on EVERY parent task** - Does **every** `X.0` parent task have its own `**Relevant Documentation:**` section? A common mistake is adding it only to the first parent task in a phase. Verify each parent task has the section independently populated, since different tasks touch different files.
- [ ] **Relevant documentation listed with full depth** - Does every parent task's `**Relevant Documentation:**` section include `.md` docs discovered by walking from the nearest `docs/` directory up to the project root? Listings that only show `design.md` are incomplete -- verify that component-level and module-level docs were discovered and listed. Do NOT include source code files (`.ts`, `.tsx`, `.py`, etc.) -- only `.md` documentation.
- [ ] **Junior-developer friendly** - Are sub-tasks specific enough for a junior developer to execute without guessing?
- [ ] **Component docs tasks included** - Does every phase that creates code include a sub-task for creating/updating `[component]/docs/` flat files per documentation-organization.md (architecture.md, implementation.md, setup.md, testing.md, CLAUDE.md)?
- [ ] **Component docs use flat file paths** - Do component doc tasks specify `[component]/docs/[category].md` paths? Tasks that say "add to README" or create new subdirectory paths like `[component]/docs/architecture/` violate `documentation-organization.md` and MUST be rewritten to use flat files. (Existing user-created subdirectories are OK to reference.)
- [ ] **Completion doc tasks included** - Does every phase end with a "Create phase completion summary" sub-task pointing to `docs/tasks/TASK-X.0-PHASE-NAME-COMPLETION-SUMMARY.md`?

**If any item fails, fix it before saving.**

## Next step

Once the task list is complete, use `/prd implement` (or read `plugins/workflow/skills/prd/prd-implement.md`) to execute tasks one sub-task at a time.
