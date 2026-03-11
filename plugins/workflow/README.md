# Workflow plugin

Complete product requirements workflow from design through implementation. This plugin provides a single, multi-stage skill (`/prd`) that guides you through creating a design document, generating an implementation task list, and executing tasks step-by-step -- including parallel execution via sub-agents.

**Version:** 1.6.0

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| PRD | `/prd` | Full workflow: design, tasks, and implementation |

The `/prd` skill has three stages, each invokable independently or run as a sequence.

## Usage

```
/prd                        # Run full workflow (design -> tasks -> implement)
/prd design                 # Create/refine design document only
/prd tasks                  # Generate tasks from existing design.md
/prd implement              # Execute tasks from tasks.md
/prd "feature description"  # Start full workflow for a named feature
```

## Stages

### 1. Design (`/prd design`)

**File:** `skills/prd/prd-design.md`

Creates a product requirements document (PRD) through guided research and clarifying questions.

**What it does:**

- Performs deep codebase research in parallel (architecture, tech stack, patterns, domain model, integration points)
- Produces a visible "Codebase findings" summary before asking any questions
- Asks targeted clarifying questions informed by actual code -- not generic templates
- Drafts the design document in plan mode, then writes it after approval

**Design document sections:**

1. Introduction/overview
2. Goals
3. User stories
4. Functional requirements (numbered)
5. Non-goals (out of scope)
6. Design considerations
7. Technical considerations
8. Success metrics
9. Open questions

**Output:** `/docs/features/[feature-name]/design.md`

**Target audience:** Junior developers -- requirements are explicit, unambiguous, and avoid jargon.

---

### 2. Tasks (`/prd tasks`)

**File:** `skills/prd/prd-tasks.md`

Generates a structured implementation task list from an existing design document.

**What it does:**

- Reads and analyzes the design document
- Creates parent tasks with high-level objectives
- Breaks each parent into actionable sub-tasks
- Scans for and links relevant documentation at every level (project-wide, component, module)
- Annotates parallel groups so independent sub-tasks can run concurrently
- Adds component documentation tasks per the flat-file documentation pattern
- Adds phase completion summary tasks

**Task list structure:**

- **Phases** with status, progress percentage, and timestamps
- **Parent tasks** with relevant documentation references
- **Sub-tasks** with Started/Completed/Duration fields
- **Parallel Group markers** identifying which sub-tasks can execute simultaneously
- **Status markers:** `[ ]` not started, `[>]` in progress, `[x]` completed

**Parallelization rules:**

- Map dependency chains first
- Group independent tasks that share the same prerequisite
- Shared setup (interfaces, project structure) runs before parallel groups
- Integration and testing tasks run after parallel groups complete
- When in doubt, keep tasks sequential

**Output:** `/docs/features/[feature-name]/tasks.md`

---

### 3. Implement (`/prd implement`)

**File:** `skills/prd/prd-implement.md`

Executes tasks from the task list continuously, using sub-agents for parallel groups.

**What it does:**

- Reads tasks.md, design.md, and related completion docs before starting
- Asks for implementation directory preferences up front
- Runs through tasks in order without pausing for approval
- Launches sub-agents in parallel for tasks marked with Parallel Group markers
- Updates tasks.md after each sub-task (status, timestamps, notes)
- Updates design.md when architecture decisions change during implementation
- Creates/updates component documentation following the flat-file pattern
- Writes completion summaries for significant work

**Parallel group execution flow:**

1. Complete all prerequisite (sequential) tasks before the group
2. Launch one sub-agent per task in the group simultaneously
3. Wait for all sub-agents, then review and reconcile outputs
4. Resume sequential flow with the next task

**Completion protocol:**

- Mark sub-task `[x]` with Completed timestamp and Duration
- When all sub-tasks under a parent are `[x]`, mark the parent complete
- Update phase progress count
- Create completion summaries at `docs/tasks/TASK-X.Y.Z-...-COMPLETION-SUMMARY.md`

## File locations

| Artifact | Path |
|----------|------|
| Design document | `/docs/features/[feature-name]/design.md` |
| Task list | `/docs/features/[feature-name]/tasks.md` |
| Completion summaries | `/docs/tasks/TASK-X.Y.Z-...-COMPLETION-SUMMARY.md` |

## Plugin structure

```
workflow/
├── .claude-plugin/
│   └── plugin.json
├── README.md
└── skills/
    └── prd/
        ├── SKILL.md            # Router - dispatches to the correct stage
        ├── prd-design.md       # Stage 1: design document generation
        ├── prd-tasks.md        # Stage 2: task list generation
        └── prd-implement.md    # Stage 3: task execution
```

## Key rules

1. **Always read the stage file** -- do not run a stage from memory
2. **Enter plan mode for design and tasks** -- ensures thorough exploration before writing
3. **Design before tasks** -- never generate tasks without a design document
4. **Tasks before implementation** -- never implement without a task list
5. **Annotate parallel groups** -- every task list must identify concurrent sub-tasks
6. **Target a junior developer** -- all outputs should be explicit and unambiguous
