---
name: feature-workflow
description: End-to-end Feature-to-Stories workflow - evaluate Feature completeness, design parallelizable User Stories, create and improve them in ADO with task decomposition
allowed-tools: Read, Write, Edit, Bash(*), Grep, Glob
argument-hint: "[evaluate|design|create] Feature-ID (e.g., 12345 or evaluate 12345)"
---

# Feature-to-Stories Workflow Agent

End-to-end workflow that takes an ADO Feature work item from evaluation through User Story creation with full task decomposition.

## Usage

```
/feature-workflow [Feature-ID]                  # Full 3-phase workflow
/feature-workflow evaluate [Feature-ID]         # Phase 1 only: evaluate & improve Feature
/feature-workflow design [Feature-ID]           # Phase 2 only: design User Stories
/feature-workflow create [Feature-ID]           # Phase 3 only: create & improve stories
```

---

## Phase 0: Initialization

Run at the start of every invocation regardless of which phase is requested.

### Step 0.1: Detect Mode

This skill supports three modes based on available tools:

1. **Check for MCP Tools** - Try to detect if ADO MCP tools are available
2. **Check for Azure CLI** - Run `az --version` to see if Azure CLI is installed
3. **Determine Mode**:
   - **MCP Mode** (Best): Full automation with MCP tools
   - **CLI Mode** (Good): Use `az boards` commands via Bash
   - **Manual Mode** (Basic): User provides content, agent analyzes

Detect mode **once** here and reuse across all phases.

### Step 0.2: Parse Arguments

Determine which phase to start from:
- No subcommand or just Feature-ID: start Phase 1 (full workflow)
- `evaluate`: Phase 1 only
- `design`: Phase 2 (check Feature readiness first)
- `create`: Phase 3 (check if story definitions exist)

### Step 0.3: Validate Feature

Fetch or request basic Feature info (title, state) to confirm it exists.

**Starting from Phase 2 without Phase 1:** Fetch the Feature and assess readiness. If Feature score appears low (missing ACs, vague description), warn user and suggest running Phase 1 first.

**Starting from Phase 3 without Phase 2:** Check if the Feature already has child User Stories. If yes, offer to improve them. If no, prompt user to provide story definitions or run Phase 2 first.

### Step 0.4: Display Workflow Roadmap

```
Feature-to-Stories Workflow for Feature #[ID] - "[Title]"
Mode: [MCP ✅ / CLI ⚙️ / Manual 📝]

Phases:
  1. Evaluate & Improve Feature  [CURRENT / DONE / PENDING]
  2. Design User Stories          [PENDING]
  3. Create & Improve Stories     [PENDING]

Starting Phase [X]...
```

---

## Phase 1: Feature Evaluation & Improvement

Evaluate the Feature work item for completeness and improve it. Embeds the core logic from `/feature-completeness`.

### Step 1.1: Gather Context

Collect Feature data based on detected mode:

#### MCP Mode
Use Azure DevOps MCP tools to fetch:

1. **Feature Details** (`mcp_ado_wit_get_work_item`):
   - Title, Description, Acceptance Criteria field
   - State, Priority, Tags, Area Path, Iteration Path
   - **CRITICAL**: Check for Acceptance Criteria in dedicated field OR clearly marked section in Description
   - If neither exists, flag as BLOCKING ISSUE

2. **Parent Context** (if Feature has a parent Epic/Initiative):
   - Fetch parent work item via relations
   - Review parent description and goals

3. **Child Work Items** (`mcp_ado_wit_get_work_item` with `expand=relations`):
   - Check for child User Stories (if any exist)
   - **CRITICAL**: Verify at least one child User Story is for automation testing (title contains "Automation Testing", "URS", or similar) - **MANDATORY**
   - If automation test User Story doesn't exist, flag as BLOCKING ISSUE

4. **Related Work Items**:
   - Dependencies (predecessor/successor links)
   - **CRITICAL**: Test Cases linked (check for "Microsoft.VSTS.Common.TestedBy" link type)
   - Must have at least 1 linked Test Case (even if draft)

5. **Linked Documents**: Parse description for wiki/SharePoint links

6. **Azure DevOps Wiki Pages** (if referenced):
   - Use `mcp_ado_wiki_get_page` or `mcp_ado_search_wiki` for specs
   - Incorporate wiki content for richer context

7. **Comments** (`mcp_ado_wit_list_work_item_comments`): Review recent discussions

#### CLI Mode
```bash
az boards work-item show --id [FEATURE-ID] --org [ORG-URL] --output json
az boards work-item relation show --id [FEATURE-ID] --org [ORG-URL]
```
Parse JSON output for Feature details, relations, and child items.

#### Manual Mode
Ask user to provide:
```
Please provide the following for Feature #[ID]:
1. Title and Description (copy from ADO)
2. Acceptance Criteria (dedicated field or in description)
3. State, Priority, Tags
4. Parent Epic/Initiative (if any)
5. Child User Stories (titles and IDs)
6. Related/Linked work items (dependencies, test cases)
7. Any wiki pages or documents linked
8. Recent comments (if relevant)
```

### Step 1.2: Analyze Completeness

Score the Feature across 5 dimensions (0-20 each, 0-100 total):

| Dimension | What to Evaluate | Scoring |
|-----------|-----------------|---------|
| **1. User Value Clarity** | Problem statement, user impact, success metrics, priority justification | 0-5: No value / 6-10: Vague / 11-15: Clear but no metrics / 16-20: Excellent |
| **2. Scope Definition** | Boundaries, requirements, constraints, NFRs | 0-5: Undefined / 6-10: Basic / 11-15: Clear with gaps / 16-20: Comprehensive |
| **3. Acceptance Criteria** | Testability, completeness, format, edge cases | 0-5: **None - BLOCKING** / 6-10: Not testable / 11-15: Good with gaps / 16-20: Excellent |
| **4. Story Readiness** | Decomposability, estimability, automation story, test cases | 0-5: Insufficient / 6-10: **Missing mandatory items** / 11-15: Good / 16-20: Excellent |
| **5. Dependencies & Context** | Parent alignment, dependencies, tech context, risks | 0-5: None / 6-10: Minimal / 11-15: Good / 16-20: Comprehensive |

**Scoring Caps (CRITICAL):**
- No Acceptance Criteria: Dimension 3 = 0/20 (BLOCKING)
- No automation test User Story: Dimension 4 max 10/20 (BLOCKING)
- No Test Case linked: Dimension 4 max 10/20 (BLOCKING)

**Grade Scale:** A (90-100) / B (80-89) / C (70-79) / D (60-69) / F (<60)

### Step 1.3: Propose Improvements

If score < 90/100:

1. **Generate improved description** (HTML format) addressing all gaps:
   - User Story (Who/What/Why)
   - Context (background, definitions, capabilities)
   - Acceptance Criteria (testable, structured)
   - Scope (explicit in/out)
   - Success Metrics (measurable)
   - Constraints (technical, timeline)

2. **CRITICAL RULES:**
   - Use ONLY explicit facts from the work item - never extrapolate
   - NEVER duplicate linked work items (use references, not copies)
   - If child stories have good detail, extract content to enrich Feature description
   - Flag missing info rather than guessing

3. **Re-score the improved version** using the exact same 5-dimension rubric:
   - Apply same scoring caps (missing mandatory items still cap scores)
   - Calculate new total and grade
   - Show before/after comparison per dimension

4. **Present report:**
   ```
   ## Phase 1: Feature Evaluation

   ### Initial Assessment
   Score: [X]/100 ([Grade])
   [Dimension breakdown with specific feedback]

   ### Mandatory Completeness Check
   - ✅/❌ Acceptance Criteria explicitly defined
   - ✅/❌ Automation test User Story exists
   - ✅/❌ Test Case work item linked

   ### Proposed Improvements
   [Improved HTML description]

   ### Re-Scored Assessment
   Score: [Y]/100 ([Grade])

   ### Before/After Comparison
   | Dimension | Initial | Improved | Change |
   |-----------|---------|----------|--------|
   | 1. User Value | X/20 | Y/20 | +Z |
   | ... | ... | ... | ... |
   | **Total** | **X/100** | **Y/100** | **+Z** |
   ```

### Step 1.4: Execute & User Gate

**Apply improvements** (based on mode):

- **MCP Mode**: `mcp_ado_wit_update_work_item` to update Description and AC fields. `mcp_ado_wit_add_work_item_comment` to post evaluation comment.
- **CLI Mode**: Generate `az boards work-item update` commands for user to execute.
- **Manual Mode**: Provide formatted HTML content to copy/paste into ADO.

**User gate:**
```
Phase 1 Complete.
Feature #[ID] scored [Initial]/100 -> [Improved]/100 ([Grade]).
[Improvements applied / Ready to apply]

Ready for Phase 2: Story Design? Say "Go" to continue.
```

---

## Phase 2: Story Design

Analyze the improved Feature and design User Stories optimized for parallel execution.

### Step 2.1: Analyze Feature for Decomposition

Using the improved Feature from Phase 1 (or fetched Feature if starting from Phase 2):

1. **Extract requirements** from Feature description and ACs
2. **Identify functional areas** - distinct capabilities, components, or workflows
3. **Map Feature ACs** - each AC must be covered by at least one User Story
4. **Note existing children** to avoid duplication
5. **Check automation/accessibility stories** - already exist or need to be proposed

### Step 2.2: Design Story Decomposition

**Parallelizability Principles:**

- **Prefer independent vertical slices** over sequential horizontal layers
  - ✅ "Story A: CRUD for Entity X" + "Story B: CRUD for Entity Y" (parallel)
  - ❌ "Story A: All backend APIs" + "Story B: All frontend UIs" (sequential)
- **Minimize hard dependencies** - each story should deliver standalone value
- **Identify shared foundations** - if multiple stories depend on a common piece (e.g., data model, shared service), that piece becomes its own story and is the only prerequisite
- **Mark parallelization explicitly** in the story plan

**For each proposed User Story, generate:**
- **Title**: Following team convention (e.g., `[URS] [Component] - [Action]`)
- **Brief scope**: 2-3 sentences describing what this story delivers
- **Feature ACs covered**: Which specific ACs this story implements
- **Estimated effort**: Hours or story points based on complexity
- **Dependencies**: Which other proposed stories must complete first (if any)
- **Parallel group**: Which stories can be worked simultaneously
- **Area Path / Iteration Path / Tags**: Inherited from Feature

**Supporting stories** (only if not already existing):
- `[URS] Automation Testing for [Feature Name]` - if no automation story exists
- `[URS] Accessibility for [Feature Name]` - if Feature has UI components and no accessibility story exists

### Step 2.3: Present Story Plan

```markdown
## Phase 2: Story Decomposition Plan

**Feature:** #[ID] - [Title]
**Feature Score:** [X]/100 ([Grade])
**Stories Designed:** [N] implementation + [M] supporting

### AC Coverage Matrix

| Feature AC | Covered By | Status |
|-----------|------------|--------|
| [AC 1] | Story 1: [Title] | NEW |
| [AC 2] | Story 2: [Title] | NEW |
| [AC 3] | Story 1 + Story 3 | NEW |
| [AC 4] | Existing #[ID] | EXISTS |

### Parallelization View

```
Sprint/Work Allocation:

  Track A (parallel):  Story 1 ──────────────────>
  Track B (parallel):  Story 2 ──────>  Story 4 ──>
  Track C (parallel):  Story 3 ──────────>
  Sequential:          (after Stories 1+2) Story 5 ─>
  Supporting:          Automation Testing Story ──────>
```

### Proposed User Stories

#### Story 1: [URS] [Component] - [Action]
- **Maps to Feature ACs:** [AC 1, AC 3]
- **Brief Scope:** [2-3 sentences]
- **Effort:** [X] hours
- **Dependencies:** None (can start immediately)
- **Parallel Group:** A

#### Story 2: [URS] [Component] - [Action]
- **Maps to Feature ACs:** [AC 2]
- **Brief Scope:** [2-3 sentences]
- **Effort:** [X] hours
- **Dependencies:** None (can start immediately)
- **Parallel Group:** B

#### Story 3: [URS] [Component] - [Action]
- **Maps to Feature ACs:** [AC 3, AC 5]
- **Brief Scope:** [2-3 sentences]
- **Effort:** [X] hours
- **Dependencies:** Story 1 (needs [entity] created first)
- **Parallel Group:** C (can run parallel with Story 2)

### Supporting Stories

#### [URS] Automation Testing for [Feature Name]
- **Status:** [ALREADY EXISTS #[ID] / NEW - RECOMMENDED]
- **Scope:** Automated tests covering all Feature ACs

### Summary

| Metric | Value |
|--------|-------|
| Implementation Stories | [N] |
| Supporting Stories | [M] |
| Max Parallel Tracks | [X] |
| Critical Path | Story [A] -> Story [B] ([Y] hours) |
| Total Effort | [Z] hours |
```

### Step 2.4: User Gate

```
Phase 2 Complete.
[N] User Stories designed covering all [M] Feature Acceptance Criteria.
[X] stories can run in parallel across [Y] tracks.

Options:
1. Approve all - proceed to Phase 3 (create & improve stories)
2. Modify - suggest changes to the story plan
3. Approve subset - select which stories to create
4. Stop - end here (plan is in conversation history)

Say "Go" to approve all, or specify your choice.
```

---

## Phase 3: Story Creation & Improvement

Create approved User Stories in ADO and improve each one with full descriptions and Tasks. Embeds the core logic from `/user-story-improvement`.

### Step 3.1: Create User Stories in ADO

For each approved story from Phase 2:

**IMPORTANT - Field Inheritance:** Every User Story MUST inherit these fields from the parent Feature:
- **Area Path**: Copy from Feature
- **Iteration Path**: Copy from Feature
- **Tags**: Copy all tags from Feature (ensures consistent filtering and reporting)

#### MCP Mode
```
mcp_ado_wit_create_work_item:
- Type: "User Story"
- Title: [Story title]
- Description: [Brief scope from Phase 2 - will be improved in Step 3.2]
- Area Path: [Inherited from Feature]
- Iteration Path: [Inherited from Feature]
- Tags: [Inherited from Feature]
- Effort: [Estimated hours]

mcp_ado_wit_work_items_link:
- Source: [New Story ID]
- Target: [Feature ID]
- Relation: "parent"
```

Record the new work item ID for each story.

#### CLI Mode
Generate commands for each story:
```bash
# Create Story
az boards work-item create \
  --title "[STORY-TITLE]" \
  --type "User Story" \
  --description "[BRIEF-SCOPE]" \
  --area "[AREA-PATH]" \
  --iteration "[ITERATION-PATH]" \
  --fields "System.Tags=[FEATURE-TAGS]" "Microsoft.VSTS.Scheduling.Effort=[HOURS]" \
  --org [ORG-URL]

# Link to Feature (after creation, using returned ID)
az boards work-item relation add \
  --id [STORY-ID] \
  --relation-type "Parent" \
  --target-id [FEATURE-ID] \
  --org [ORG-URL]
```

Ask user to provide the created work item IDs.

#### Manual Mode
Output a table of stories with all fields for manual creation:
```
| # | Title | Description | Area Path | Iteration | Tags | Effort |
|---|-------|------------|-----------|-----------|------|--------|
| 1 | [Title] | [Scope] | [Path] | [Path] | [Tags] | [Xh] |
```
Ask user to create in ADO and provide the work item IDs.

### Step 3.2: Improve Each User Story (Iterative)

For each created story, run the full improvement logic:

**3.2.1: Gather Story Context**
- Fetch the created story (MCP/CLI/manual - details already known from Phase 2)
- Parent Feature context is already available from Phase 1
- Check sibling stories (other stories created in this workflow + existing children):
  - Note automation testing story (existing or just created)
  - Note accessibility story (if applicable)

**3.2.2: Assess Readiness**
Run checklist:
1. ✅/❌ User Story structure (As a... I want... so that...)
2. ✅/❌ Feature alignment (maps to specific Feature ACs)
3. ✅/❌ Acceptance Criteria in dedicated AC field
4. ✅/❌ Implementation context (technical approach, entities, validation)
5. ✅/❌ Task decomposability

Status: READY ✅ / NEEDS WORK ⚠️ / BLOCKED ❌

**3.2.3: Generate Improved Content**

**Description** (System.Description field - HTML):
```html
<h2>User Story</h2>
<p>As a <strong>[role]</strong>, I want [capability], so that I can <strong>[business value]</strong>.</p>

<h2>Context</h2>
<p>[Background from parent Feature]</p>
<p><strong>Feature ACs Implemented:</strong></p>
<ul><li>[Specific ACs this story addresses]</li></ul>
<p><strong>Key Entities/Components:</strong></p>
<ul><li><strong>[Entity]</strong>: [Description]</li></ul>

<h2>Implementation Notes</h2>
<ul>
  <li><strong>Technical Approach:</strong> [How to implement]</li>
  <li><strong>Validation Rules:</strong> [Business rules]</li>
  <li><strong>Error Handling:</strong> [Error scenarios]</li>
</ul>

<h2>Out of Scope</h2>
<ul><li>[What this story does NOT cover]</li></ul>
```

**Acceptance Criteria** (dedicated AC field - HTML):
```html
<h3>[Category 1]</h3>
<ul>
<li>[Testable criterion 1]</li>
<li>[Testable criterion 2]</li>
</ul>
```

**WARNING:** Do NOT duplicate ACs in the Description. ACs belong ONLY in the dedicated AC field.

**3.2.4: Propose Task Decomposition**

**Check sibling stories first:**
- If Feature-level automation testing story exists: SKIP `[Test] Automated tests` tasks
- If Feature-level accessibility story exists: SKIP `[UX] Accessibility testing` tasks

**Task naming:** `[Type] [Specific Action]`
- Types: `[Dev]`, `[Test]`, `[UX]`, `[Data]`, `[API]`, `[Review]`

**Task sizing:** 1-16h each, total approximately equals User Story effort estimate.

**Common patterns (adapt per story type):**

CRUD Stories:
- `[Data]` Create/update entity schema
- `[Dev]` Implement CRUD operations
- `[Dev]` Implement validation logic
- `[Test]` Unit tests
- `[Review]` Code review

Validation/Logic Stories:
- `[Dev]` Implement validation service
- `[Dev]` Error messaging
- `[Test]` Unit tests (valid + invalid)
- `[Review]` Code review

UI/Navigation Stories:
- `[UX]` Design mockups
- `[Dev]` Implement layout/navigation
- `[Test]` UI tests
- `[Review]` UX review

**3.2.5: Present Per-Story Recommendations**

```
## Story [N]/[Total]: #[ID] - [Title]
Status: [READY / NEEDS WORK / BLOCKED]

### Improved Description
[HTML content preview]

### Acceptance Criteria
[AC content preview]

### Proposed Tasks ([N] tasks, [X]h total)
1. [Type] [Task title] - [Xh]
2. [Type] [Task title] - [Xh]
...

Actions:
1. Update description + create Tasks
2. Update description only
3. Skip to next story
```

**3.2.6: Execute Per-Story Updates**

**IMPORTANT - Task Field Inheritance:** Every Task MUST inherit these fields from its parent User Story:
- **Area Path**: Copy from User Story (which inherited from Feature)
- **Iteration Path**: Copy from User Story (which inherited from Feature)
- **Tags**: Copy from User Story (which inherited from Feature)

This ensures the full chain: Feature → User Story → Task all share the same Area Path, Iteration Path, and Tags for consistent filtering, reporting, and board views.

Based on mode:

- **MCP Mode**: Auto-update description, AC field, create Tasks (with inherited Area Path, Iteration Path, Tags), link Tasks to story
- **CLI Mode**: Generate `az boards` commands for updates and task creation (include `--area`, `--iteration`, `--fields "System.Tags=..."` on each task)
- **Manual Mode**: Provide formatted content and task table for manual entry

Then move to next story.

### Step 3.3: Workflow Summary

After all stories are processed:

```markdown
## Feature-to-Stories Workflow Complete

**Feature:** #[ID] - [Title]
**Feature Score:** [Initial] -> [Improved] ([Grade])
**Mode:** [MCP ✅ / CLI ⚙️ / Manual 📝]

### Stories Created & Improved

| # | Story ID | Title | Status | Tasks | Hours |
|---|----------|-------|--------|-------|-------|
| 1 | #[ID] | [Title] | Improved + Tasks | [N] | [Xh] |
| 2 | #[ID] | [Title] | Improved | 0 | - |
| 3 | #[ID] | [Title] | Improved + Tasks | [N] | [Xh] |

### Parallelization Summary

| Track | Stories | Can Start |
|-------|---------|-----------|
| A | Story 1 | Immediately |
| B | Story 2, Story 4 | Immediately (Story 4 after Story 2) |
| C | Story 3 | Immediately |
| Sequential | Story 5 | After Stories 1 + 2 |

### Coverage & Totals
- Feature ACs covered: [N]/[M] (100%)
- Stories created: [N]
- Stories improved: [N]
- Tasks created: [N] total
- Total effort: [X] hours
- Max parallel tracks: [Y]
- Critical path: [Z] hours

### Remaining Actions
- [ ] [Any flagged items - missing test cases, blocked items, etc.]
```

---

## Guidelines

- **Facts only**: Base all analysis and improvements on explicitly stated information - never extrapolate
- **Never duplicate linked items**: Reference ADO links, don't copy them into descriptions
- **Parallelizability first**: Design stories for concurrent development when possible
- **Respect user gates**: Never proceed to next phase without explicit user confirmation
- **Mode consistency**: Use the mode detected in Phase 0 throughout the entire workflow
- **Existing work items**: Never auto-delete or overwrite - always ask user preference
- **Scoring caps apply**: Missing mandatory items cap scores even in improved versions
- **Be constructive**: Prioritize actionable recommendations over criticism

## Success Criteria

- ✅ Feature evaluated with before/after scores showing improvement
- ✅ All Feature ACs mapped to at least one User Story
- ✅ Stories designed for maximum parallelizability
- ✅ Each story improved with Feature context, ACs, and Tasks
- ✅ Automation/accessibility tasks not duplicated when Feature-level stories exist
- ✅ User had clear decision points at every phase transition
- ✅ Final summary shows complete coverage and parallelization view
