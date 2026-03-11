# Task Workflow - MANDATORY

## 🔧 Check Project Configuration First

**Read `.github/copilot/project-config.md`** to determine enabled features:

- **Azure DevOps Integration**: If ❌ OFF, skip all ADO references below
- **Memory Bank**: If ❌ OFF, skip memory bank updates
- **GitHub Projects**: If ❌ OFF, skip GitHub issue sync

## 👤 Developer Identity

**For "Last Updated by" and task completion attribution:**

1. **Check `.developer` file** in repo root (should be in .gitignore)
   - If exists, use `NAME=` value for attribution
2. **Fallback**: Use Windows username from file paths (e.g., `gregrata`)

**Example `.developer` file:**

```
NAME=Greg Ratajik
EMAIL=Greg.Ratajik@microsoft.com
```

---

## ⚠️ BEFORE Starting Any Task

### 1. Read ALL Core Documentation (MANDATORY - Always Start Here)

**Primary Documents (Read First):**

- **TASKS.md** - Find your task, review acceptance criteria and dependencies
- **design.md** (or prd.md) - Understand overall architecture, requirements, and design decisions
- **If ADO = ✅ ON**: Check Phase header for ADO Feature work item link

**Supporting Documentation (Read What Exists):**

- **Use `file_search`** to discover ALL relevant docs in `/docs` directory
- **Pattern: `docs/**/*.md`** - Find all markdown documentation
- **Common doc locations:**
  - `docs/tasks/TASK-*-COMPLETION*.md` - Previous completion summaries
  - `docs/architecture.md` - Architecture details and decisions
  - `docs/*.md` - Feature-specific documentation
  - `docs/setup.md` - Setup and configuration guides

**Why Read Everything:**

- Restores full implementation context from previous work
- Prevents reimplementing patterns that already exist
- Discovers constraints, gotchas, and decisions made
- Ensures consistency with existing architecture
- Avoids breaking related functionality

### 2. Identify Task Category and Related Work

- **Task numbering** reveals category (e.g., Task 2.4.2 → Camera/Media category)
- **Use `file_search`** to find related completion docs: `docs/tasks/TASK-2.4.*-COMPLETION*.md`
- **Read ALL matching docs** - Each contains crucial context
- **Cross-reference** architecture docs that relate to this task category

### 3. Understand Full Context

- Identify which Phase the task belongs to (Task X.Y.Z → Phase X)
- Review all dependencies and prerequisite tasks
- Check acceptance criteria for completeness
- Verify no blockers exist
- Understand how this task fits into overall product

### 4. Start Work

- With complete context loaded, begin implementation
- No ADO work item creation needed for individual tasks (if ADO = ✅ ON, Feature-level only)
- Focus on implementation following established patterns
- Document decisions as you go

---

## ⚠️ AFTER Completing Any Task

**USE THIS CHECKLIST - ALL STEPS ARE MANDATORY:**

### 1. Update Core Documentation

- [ ] **Update TASKS.md**
  - Mark task as `[x]` with completion checkbox
  - Add completion timestamp (format: `Completed: YYYY-MM-DD HH:MM:SS UTC±X`)
  - Calculate and record duration
  - Add inline completion notes summarizing key decisions

```markdown
- [x] **2.4.2** Implement video capture
  - **Started**: 2025-10-09 14:30:00 UTC-7
  - **Completed**: 2025-10-09 18:45:00 UTC-7
  - **Duration**: 4h 15m
  - Implementation notes...
```

- [ ] **Update design.md (or prd.md)**
  - Document any design decisions made during implementation
  - Update architecture diagrams or descriptions if changed
  - Add new components, patterns, or integrations
  - Document deviations from original design with rationale
  - Update "Last Updated" timestamp with developer name (from `.developer` or Windows username)

### 2. Create or Update Supporting Documentation

**Create New Documentation When:**

- ✅ Significant work completed (major feature, complex implementation)
- ✅ Important decisions made that affect future work
- ✅ New patterns or approaches established
- ✅ Non-obvious solutions to problems discovered
- ✅ Integration points or dependencies created

**Document Location and Naming:**

- `docs/tasks/TASK-X.Y.Z-TASK-NAME-COMPLETION-SUMMARY.md` - Task completion summaries
- `docs/architecture.md` - Architecture details
- `docs/features.md` - Feature-specific guides (append with clear heading)
- `docs/setup.md` - Setup instructions (append with clear heading per component)

**What to Include in Completion Summaries:**

```markdown
# Task X.Y.Z - [Task Title] - Completion Summary

**Completed:** YYYY-MM-DD HH:MM
**Completed By:** [Developer name from .developer or Windows username]
**Duration:** X hours
**Related Tasks:** X.Y.A, X.Y.B (if applicable)

## What Was Implemented
- Detailed description of what was built
- Key features and functionality added

## Design Decisions
- Important decisions made and rationale
- Alternatives considered and why rejected
- Trade-offs accepted

## Implementation Details
- Patterns used
- Key files modified or created
- Integration points
- Dependencies added

## Testing & Validation
- How feature was tested
- Test cases covered
- Known limitations

## Future Considerations
- What should be done differently next time
- Potential improvements for V2
- Technical debt introduced (if any)
```

**Update Existing Documentation When:**

- ✅ Architecture docs need new information
- ✅ Setup guides need additional steps
- ✅ Feature guides need updates for new functionality
- ✅ Cross-references need to be maintained

### 3. Verify Documentation Completeness

- [ ] **Run `file_search` for docs** - Verify all related docs are updated
- [ ] **Check cross-references** - Ensure links between docs are valid
- [ ] **Verify consistency** - Design decisions match between TASKS.md, design.md, and completion docs

### 4. ADO Sync (If ADO = ✅ ON)

**What Happens Automatically (NO ACTION REQUIRED):**

- ✅ AI detects task completion in TASKS.md
- ✅ AI counts completed tasks in the Phase
- ✅ AI determines if Phase status changed
- ✅ AI updates ADO Feature work item via `az boards` CLI
- ✅ You see confirmation: "✅ Updated Feature (Work Item ID): [status] (Y/Z tasks complete)"

**If ADO = ❌ OFF**: Skip this step entirely.

---

## 🚫 NEVER / ✅ ALWAYS

### 🚫 NEVER Do This:

- ❌ Start work without reading ALL existing documentation first
- ❌ Start work without checking project-config.md
- ❌ Complete work without updating TASKS.md
- ❌ Complete work without updating design.md/prd.md
- ❌ Skip creating completion docs for significant work
- ❌ Create duplicate documentation (check what exists first with `file_search`)
- ❌ Ignore existing patterns documented in previous completion summaries

**If ADO = ✅ ON:**

- ❌ Create ADO work items for individual tasks (use Feature-level only)
- ❌ Manually update ADO Project (AI handles this)

### ✅ ALWAYS Do This:

- ✅ **FIRST:** Check project-config.md for enabled features
- ✅ **SECOND:** Use `file_search` to discover ALL relevant docs in `/docs` directory
- ✅ **THIRD:** Read TASKS.md, design.md/prd.md, and all discovered documentation
- ✅ **FOURTH:** Review related completion docs and architecture docs for context
- ✅ Update TASKS.md with `[x]` checkbox, timestamp, duration, and notes
- ✅ Update design.md/prd.md with any architecture/design changes
- ✅ Create or update completion summaries for significant work
- ✅ Document new patterns, decisions, and gotchas discovered
- ✅ Maintain cross-references between related documentation
- ✅ Let AI handle ADO Feature work item synchronization (if ADO = ✅ ON)

---

## 📚 Documentation Discovery Pattern

**Before Starting ANY Task:**

```
1. file_search: "docs/**/*.md"
   → Discover all documentation that exists

2. file_search: "docs/tasks/TASK-[X.Y]*.md"
   → Find related completion docs for this task category

3. file_search: "docs/architecture.md"
   → Check for architecture documentation

4. Read ALL discovered docs to build complete context

5. Begin work with full understanding of:
   - What's been done before
   - Patterns established
   - Decisions made
   - Constraints in place
```

**After Completing ANY Task:**

```
1. Update TASKS.md (mark complete, add timestamp/notes)

2. Update design.md/prd.md (if design/architecture changed)

3. Create new docs OR update existing docs:
   - Check if completion doc already exists
   - Update if exists, create if significant new work
   - Maintain consistency across all docs

4. Verify all cross-references are valid

5. AI automatically syncs ADO Feature work item (if ADO = ✅ ON)
```

---

## ⏰ Automatic Timestamp Tracking (MANDATORY)

**Purpose:** Track when work starts, updates, and completes for project timeline visibility and audit trails.

### Timestamp Format

- Use ISO 8601 format with timezone: `YYYY-MM-DD HH:MM:SS UTC±X`
- Example: `2025-10-09 14:30:00 UTC-7`
- Always use the current date/time when creating timestamps

### Phase Headers

```markdown
## PHASE 2: CORE SCHEDULING SERVICE DEVELOPMENT

**ADO Feature:** [Work Item #155](https://dev.azure.com/...) (if ADO = ✅ ON)
**Status:** In Progress | Done
**Progress:** 12/25 tasks complete (48%)
**Phase Started**: 2025-09-15 09:00:00 UTC-7
**Last Updated**: 2025-10-09 14:30:00 UTC-7
**Phase Completed**: TBD | 2025-10-22 17:00:00 UTC-7
**Phase Duration**: TBD | 5w 3d 8h
```

### Task States

```markdown
[ ]  Not started
[>]  In progress (add Started timestamp)
[x]  Complete (add Completed timestamp and Duration)
```

### AI Automation Rules for Timestamps

1. **When starting a Phase:**
   - Detect when the FIRST task in a phase changes from `[ ]` to `[>]` or `[x]`
   - Automatically add "Phase Started" timestamp to phase header
   - Update "Last Updated" timestamp in phase header
   - Update phase "Status" to "In Progress"

2. **When updating a Phase:**
   - After ANY task completion or status change within the phase
   - Update "Last Updated" timestamp in phase header
   - Recalculate and update "Progress" percentage
   - Update progress counts (X/Y tasks complete)

3. **When completing a Phase:**
   - Detect when ALL tasks in a phase are marked `[x]`
   - Add "Phase Completed" timestamp to phase header
   - Calculate total phase duration from "Phase Started" to "Phase Completed"
   - Add "Phase Duration" field with calculated duration
   - Format duration as: `Xw Yd Zh` for phases (e.g., "5w 3d 8h" or "2d 14h")
   - Update "Last Updated" timestamp
   - Update phase "Status" to "Done"

4. **When starting a task:**
   - Detect when a task changes from `[ ]` to `[>]`
   - Automatically add "Started" timestamp to task
   - Calculate timezone from system
   - Update parent phase "Last Updated" timestamp

5. **When updating work in progress:**
   - Detect modifications to an in-progress task `[>]`
   - Update "Last Updated" timestamp in task
   - Preserve "Started" timestamp
   - Update parent phase "Last Updated" timestamp

6. **When completing a task:**
   - Detect when a task changes to `[x]`
   - Add "Completed" timestamp to task
   - Calculate duration from "Started" time
   - Format duration as: `Xh Ym` or `Xd Yh Zm` for longer tasks
   - Preserve "Started" and "Last Updated" timestamps
   - Update parent phase "Last Updated" and progress

7. **When updating design.md:**
   - After making any changes to a major section
   - Update or add "Last Updated" timestamp at section start
   - If section is new, add "Created" timestamp as well

8. **For completion summaries:**
   - Always include all four timestamps: Start Date, End Date, Duration, Last Updated
   - Use the task's "Started" and "Completed" times from TASKS.md

### Benefits

- ✅ Automatic timeline tracking for project management
- ✅ Audit trail for all work performed
- ✅ Duration calculation for effort estimation improvement
- ✅ Clear visibility into when work was last touched
- ✅ Historical context for documentation changes

### Never Do

- ❌ Manually calculate durations (let AI do this)
- ❌ Skip timestamps on task completion
- ❌ Use inconsistent timestamp formats
- ❌ Remove existing timestamps when updating

---

**If you violate these rules, STOP immediately and inform the user.**

---

**Last Updated:** December 3, 2025 by gregrata

