---
name: user-story-improvement
description: Improve Azure DevOps User Story work items by enriching descriptions with Feature context, creating testable acceptance criteria, and generating actionable child Tasks with proper sizing and test coverage
allowed-tools: Read, Write, Edit, Bash(*), Grep, Glob
argument-hint: User Story work item ID (e.g., 98765)
---

# User Story Improvement Agent

Improve Azure DevOps User Story work items by enriching descriptions and creating actionable child Tasks.

## Core Workflow

### Step 0: Detect Available Tools and Set Mode

This skill supports three modes based on available tools:

1. **Check for MCP Tools** - Try to detect if ADO MCP tools are available
2. **Check for Azure CLI** - Run `az --version` to see if Azure CLI is installed
3. **Determine Mode**:
   - **MCP Mode** (Best): Full automation with MCP tools
   - **CLI Mode** (Good): Use `az boards` commands via Bash
   - **Manual Mode** (Basic): User provides content, agent analyzes

**Inform user of detected mode:**
- MCP Mode: "Using ADO MCP tools for full automation ✅"
- CLI Mode: "Using Azure CLI for semi-automated workflow ⚙️ (requires `az login` and `az boards` extension)"
- Manual Mode: "Using manual mode 📝 - Please provide the User Story work item content"

### Step 1: Gather Context

**Mode-specific data gathering:**

#### MCP Mode (Full Automation)
**Fetch User Story** (`mcp_ado_wit_get_work_item`):
- Title, Description, State, Effort estimate
- **Acceptance Criteria field** (check for dedicated field like "Microsoft.VSTS.Common.AcceptanceCriteria")
- Existing child Tasks (via relations)

**Fetch Parent Feature** (via parent relation):
- User Story, Context, **Acceptance Criteria** (map which ACs this User Story implements)
- Scope, Constraints, Testing Requirements
- **Sibling User Stories** (other children of same Feature):
  * Check for dedicated automation testing User Story (titles containing "Automation", "Test Automation", "Automated Testcases", etc.)
  * Check for dedicated accessibility User Story (titles containing "Accessibility", "A11y", "Accessibility Insights", etc.)
  * Note work item IDs for reference in Task creation logic

**Title Analysis** - Parse title to understand scope:
- `[Component] Action` → e.g., "[URS] Scope Management CRUD"
- Extract entities, actions, capabilities mentioned
- Determine focus area within parent Feature

**Wiki Context** (if referenced):
- Use `mcp_ado_wiki_get_page` or `mcp_ado_search_wiki` for technical specs

#### CLI Mode (Semi-Automated)
Use Azure CLI commands to gather information:

1. **Fetch User Story**:
   ```bash
   az boards work-item show --id [STORY-ID] --org [ORG-URL] --output json
   ```

2. **Get parent Feature and relations**:
   ```bash
   az boards work-item relation show --id [STORY-ID] --org [ORG-URL]
   ```

3. **Fetch sibling User Stories** (same parent Feature):
   ```bash
   az boards work-item relation show --id [FEATURE-ID] --org [ORG-URL]
   ```

Parse JSON output to extract User Story details, parent Feature context, and sibling stories.

**Note:** Wiki page retrieval not available via CLI.

#### Manual Mode (User-Provided Content)
Ask user to provide User Story information:

**Prompt user:**
```
Please provide the following information about User Story #[ID]:

1. Title and Description
2. Acceptance Criteria (if exists in dedicated field)
3. Effort estimate, State, Priority
4. Existing child Tasks (if any) - titles and states
5. Parent Feature #ID, title, and key acceptance criteria
6. Sibling User Stories (especially automation/accessibility stories)
7. Any relevant wiki links or documentation

You can paste raw text, JSON, or HTML from ADO.
```

Parse the provided content and extract relevant information.

### Step 2: Assess Readiness

Run checklist (✅/❌):

1. **User Story Structure**: Clear format (As a [role], I want [capability], so that [benefit])?
2. **Feature Alignment**: References which Feature ACs it implements?
3. **Acceptance Criteria**: Present in dedicated AC field, testable, covers all scenarios?
4. **Implementation Context**: Technical approach, entities, validation rules mentioned?
5. **Task Decomposition**: Clear how to break into Tasks? Tasks already exist?
6. **Field Inheritance**: Area Path, Iteration Path, and Tags match parent Feature?

**Status Determination:**
- **READY ✅**: All critical items present
- **NEEDS WORK ⚠️**: Missing 1-2 critical items
- **BLOCKED ❌**: Missing 3+ critical items or fundamental issues

### Step 3: Generate Improved Content

**Description Structure** (System.Description field):

```html
<h2>User Story</h2>
<p>As a <strong>[role]</strong>, I want [capability], so that I can <strong>[business value]</strong>.</p>

<h2>Context</h2>
<p>[Background from parent Feature]</p>
<p><strong>Feature Acceptance Criteria Implemented:</strong></p>
<ul>
  <li>[Specific Feature ACs this User Story addresses]</li>
</ul>
<p><strong>Key Entities/Components:</strong></p>
<ul>
  <li><strong>[Entity]</strong>: [Description]</li>
</ul>

<h2>Implementation Notes</h2>
<ul>
  <li><strong>Technical Approach:</strong> [How to implement]</li>
  <li><strong>Validation Rules:</strong> [Business rules to enforce]</li>
  <li><strong>Error Handling:</strong> [Error scenarios]</li>
</ul>

<h2>Out of Scope</h2>
<ul>
  <li>[What this User Story does NOT cover]</li>
</ul>
```

**Acceptance Criteria** (Dedicated AC field - e.g., "Microsoft.VSTS.Common.AcceptanceCriteria"):

**IMPORTANT:** Format as **HTML** for better readability in Azure DevOps:

```html
<h3>[Category 1]</h3>
<ul>
<li>[Specific testable criterion 1]</li>
<li>[Specific testable criterion 2]</li>
</ul>

<h3>[Category 2]</h3>
<ul>
<li>[Specific testable criterion 1]</li>
<li>[Specific testable criterion 2]</li>
</ul>

OR use Given/When/Then format:

<h3>Scenario 1: [Scenario name]</h3>
<ul>
<li><strong>Given</strong> [precondition]</li>
<li><strong>When</strong> [action]</li>
<li><strong>Then</strong> [expected result]</li>
</ul>
```

**WARNING:** Do NOT duplicate Acceptance Criteria in the Description field. ACs belong ONLY in the dedicated AC field.

**Important:**
- Description contains context, implementation notes, and out-of-scope
- Acceptance Criteria field contains testable criteria only
- Do NOT duplicate ACs in description - they belong in the dedicated field

### Step 4: Task Decomposition Strategy

**When to Create Tasks:**
- ✅ **ALWAYS**: No Tasks exist + User Story has effort estimate + Not Done/Closed
- ⚠️ **EVALUATE**: Tasks exist → Ask user (Keep/Replace/Supplement)
- ❌ **SKIP**: Done/Closed state, no estimate, or user requests description-only

**Feature-Level Automation and Accessibility Check:**

Before creating Tasks for automation testing or accessibility:

1. **Check Parent Feature for Dedicated User Stories:**
   - Look for sibling User Stories (same parent Feature) with titles containing:
     * **Automation Testing**: "Automation Testing", "Automated Testcases", "Test Automation", "[URS] Create Automated", etc.
     * **Accessibility**: "Accessibility", "A11y", "Run Accessibility Insights", "WCAG", etc.

2. **Task Creation Logic:**
   - ✅ **CREATE Tasks** for automation/accessibility if:
     * NO dedicated automation testing User Story exists at Feature level, OR
     * NO dedicated accessibility User Story exists at Feature level
     * Creates Tasks as a safety net for this specific User Story's scope
   - ❌ **SKIP Tasks** for automation/accessibility if:
     * Dedicated User Story exists (e.g., "#5803491 - [URS] Create Automated Testcases for Read Only Goals")
     * Note in Task proposal: "Automation testing handled by User Story #[ID]" or "Accessibility handled by User Story #[ID]"
     * Reduces duplication since Feature-level stories cover all child User Stories

3. **Examples:**
   - **Feature #5761585** has User Story #5803491 "[URS] Create Automated Testcases for Read Only Goals"
     → SKIP `[Test] Automation tests` Task for child User Stories
   - **Feature #5761585** has User Story #5816111 "[URS] Run Accessibility Insights for OOB Scheduling Goals"
     → SKIP `[UX] Accessibility testing` Task for child User Stories
   - **Feature #XXXXX** has NO automation User Story
     → CREATE `[Test] Automated tests` Task for each child User Story to be safe

**Task Naming:** `[Type] [Specific Action on Entity]`
- Types: `[Dev]`, `[Test]`, `[UX]`, `[Data]`, `[API]`, `[Review]`

**Common Patterns** (adapt, don't blindly apply all):

**CRUD User Stories:**
- `[Data]` Create/update entity schema (if new)
- `[Dev]` Implement Create/Edit/Delete operations (match User Story scope)
- `[Dev]` Implement validation logic
- `[Test]` Unit tests for operations covered
- `[Test]` Automated UI tests (ONLY if no Feature-level automation User Story)
- `[UX]` Form accessibility (if new UI - ONLY if no Feature-level accessibility User Story)
- `[Review]` Code review

**Validation/Logic User Stories:**
- `[Dev]` Implement validation service
- `[Dev]` Add specific validation rules
- `[Dev]` Error messaging
- `[Test]` Unit tests (valid + invalid inputs)
- `[Test]` Automated tests (ONLY if no Feature-level automation User Story)
- `[Review]` Code review

**UI/Navigation User Stories:**
- `[UX]` Design mockups (if new UI)
- `[Dev]` Implement layout/navigation
- `[Dev]` Accessibility (WCAG - ONLY if no Feature-level accessibility User Story)
- `[Test]` UI + accessibility tests (ONLY if no Feature-level automation/accessibility User Stories)
- `[Review]` UX review

**Task Sizing:**
- 1-16 hours per Task
- Total Task hours ≈ User Story estimate
- Small US (5-8h): 3-5 Tasks | Medium (13-20h): 5-8 Tasks | Large (30-40h): 8-10 Tasks

**Key Principles:**
1. Only create Tasks for actual work needed (not things that exist)
2. Match User Story scope (don't add out-of-scope operations)
3. Check Feature for dedicated automation/accessibility User Stories before creating duplicate Tasks
4. Always include testing but only for functionality being implemented
5. Be specific - reference actual entities/components

### Step 5: Present Recommendations

Format:

```markdown
## User Story Improvement Analysis

**Current State:** [READY ✅ / NEEDS WORK ⚠️ / BLOCKED ❌]
**User Story:** #[ID] - [Title]

### Field Inheritance Check

| Field | Feature Value | User Story Value | Status |
|-------|--------------|-----------------|--------|
| Area Path | [Feature Area Path] | [Story Area Path] | [✅ Match / ❌ Mismatch] |
| Iteration Path | [Feature Iteration Path] | [Story Iteration Path] | [✅ Match / ⚠️ Different (may be intentional)] |
| Tags | [Feature Tags] | [Story Tags] | [✅ All inherited / ❌ Missing: tag1, tag2] |

**Action:** [No changes needed / Will update Area Path, Tags to match Feature]

**Note:** Iteration Path differences may be intentional (story in different sprint than Feature). Area Path and Tags should always match.

### Feature-Level Test Coverage

**Automation Testing:** [✅ Covered by User Story #[ID] - [Title] / ❌ Not covered - will create Tasks]
**Accessibility Testing:** [✅ Covered by User Story #[ID] - [Title] / ❌ Not covered - will create Tasks]

**Note:** When Feature has dedicated automation/accessibility User Stories, individual User Story Tasks for these areas are not needed (handled at Feature level).

### Readiness Assessment

✅ **Strengths:** [What's good]
❌ **Critical Gaps:** [What blocks development]
⚠️ **Improvements:** [Nice-to-haves]

### Task Creation Recommendation

**Status:** [RECOMMENDED ✅ / OPTIONAL ⚠️ / NOT RECOMMENDED ❌]

**Reason:** [Why/why not create Tasks]

**If Tasks Exist ([N] Tasks):**
- Current: [Task titles]
- Quality: [Good / Needs improvement / Mismatched]
- Recommendation: [Keep / Replace / Supplement]

### Improvements Made

**Description:** Added Feature AC mapping, entities, implementation notes, out-of-scope
**Acceptance Criteria:** Added testable criteria to dedicated AC field (not in description)
**Tasks:** [N] Tasks ([Xh] total) - [categories covered]

**Task Breakdown:**
1. `[Type]` [Task title] - [Xh]
2. ...

**After Improvements:** READY ✅

### Actions Available

1. Update Description
2. Fix Field Inheritance (if mismatched with parent Feature)
3. Create Tasks ([N] proposed)
4. All of the above
5. Review Only
6. Improve Existing Tasks (if applicable)
```

### Step 6: Execute Actions

Execute based on detected mode:

#### MCP Mode (Full Automation)

**Fix Field Inheritance (if mismatched):**
```
mcp_ado_wit_update_work_item with:
- System.AreaPath: [Feature Area Path] (if different from User Story)
- System.Tags: [Feature Tags merged with Story Tags] (add missing Feature tags)
- System.IterationPath: [Feature Iteration Path] (only if user confirms - may be intentionally different)
```

**Update Description:**
```
mcp_ado_wit_update_work_item with:
- System.Description field (HTML format with context, implementation notes, out-of-scope)
- Microsoft.VSTS.Common.AcceptanceCriteria field (plain text or structured format with testable criteria)
```

**Create Tasks:**

**IMPORTANT - Field Inheritance:** Every Task MUST inherit these fields from its parent User Story:
- **Area Path**: Copy from User Story
- **Iteration Path**: Copy from User Story
- **Tags**: Copy all tags from User Story

1. Check for existing Tasks first
2. If replacing: Only replace New/Active Tasks (keep Done/Closed)
3. For each new Task:
   - `mcp_ado_wit_create_work_item` with Title, Description, AreaPath, IterationPath, Tags, RemainingWork, Priority
   - `mcp_ado_wit_work_items_link` (Task → User Story, type: "parent")
   - Link dependencies if needed (predecessor/successor)

**Post Comment:** `mcp_ado_wit_add_work_item_comment` with summary

#### CLI Mode (Semi-Automated)

Generate Azure CLI commands for user to execute:

**Fix Field Inheritance (if mismatched):**
```bash
# Update Area Path and Tags to match parent Feature (only if mismatched)
az boards work-item update \
  --id [STORY-ID] \
  --area "[FEATURE-AREA-PATH]" \
  --fields "System.Tags=[FEATURE-TAGS-MERGED-WITH-STORY-TAGS]" \
  --org [ORG-URL]
```

**Update Description:**
```bash
az boards work-item update \
  --id [STORY-ID] \
  --description "[IMPROVED-HTML-DESCRIPTION]" \
  --fields "Microsoft.VSTS.Common.AcceptanceCriteria=[ACs]" \
  --org [ORG-URL]
```

**Create Tasks:**
```bash
# For each Task (inherit Area Path, Iteration Path, Tags from User Story)
az boards work-item create \
  --title "[TASK-TITLE]" \
  --type "Task" \
  --description "[TASK-DESCRIPTION]" \
  --area "[STORY-AREA-PATH]" \
  --iteration "[STORY-ITERATION-PATH]" \
  --fields "System.Tags=[STORY-TAGS]" "System.RemainingWork=[HOURS]" \
  --org [ORG-URL]

# Link Task to User Story
az boards work-item relation add \
  --id [TASK-ID] \
  --relation-type "Parent" \
  --target-id [STORY-ID] \
  --org [ORG-URL]
```

#### Manual Mode

Provide formatted content for user to paste into ADO:

1. **Fix Field Inheritance** (if mismatched) - Instruct user to update User Story fields:
   - Set Area Path to match parent Feature: `[Feature Area Path]`
   - Add missing tags from parent Feature: `[missing tags]`
   - Optionally align Iteration Path (note if intentionally different)
2. **Improved Description (HTML)** - Copy and paste into Description field
3. **Acceptance Criteria** - Copy and paste into AC field
4. **Task List** - Provide table of Tasks with titles, descriptions, and estimates for manual creation
5. **Instructions** - Step-by-step guide for creating Tasks in ADO UI

## Best Practices

1. **Feature Alignment**: Always map to parent Feature ACs
2. **Field Inheritance**: Ensure User Story inherits Area Path and Tags from parent Feature. Flag and fix mismatches
3. **Title Analysis**: Use title to understand specific scope within Feature
4. **Task Quality**: Specific, actionable, 1-16h each, includes testing
5. **Avoid Duplication**: Don't repeat Feature description, focus on User Story scope
6. **Check Sibling User Stories**: Before creating automation/accessibility Tasks, check if Feature has dedicated User Stories for these (reduces duplication)
7. **Existing Tasks**: Never auto-delete, always ask user preference
8. **Estimate Validation**: Flag if Task hours don't match User Story estimate
8. **State Awareness**: Don't suggest large changes for Active/Done User Stories

## Example Scenarios

### Scenario 1: No Tasks Exist
**Title:** `[URS] Scope Management - Create and Edit`
**Context:** Feature AC requires "create/edit Scope with FetchXML validation"
**Tasks Created (6 tasks, 20h):**
1. `[Data]` Create Scope entity schema - 3h
2. `[Dev]` Implement Create Scope form - 5h
3. `[Dev]` Implement Edit Scope form - 4h
4. `[Dev]` FetchXML validation - 3h
5. `[Test]` Unit tests for Scope CRUD - 3h
6. `[Review]` Code review - 2h

### Scenario 2: Tasks Exist (Low Quality)
**Current:** 3 Tasks: "Validate FetchXML" (8h), "Show errors" (2h, Done), "Add tests" (5h)
**Assessment:** Task 1 too broad, Task 3 too vague, Task 2 Done (keep)
**Recommendation:** Keep Done Task, replace 2 active Tasks with 5 specific Tasks

### Scenario 3: User Story BLOCKED
**Gaps:** No Feature AC mapping, vague ACs, no implementation notes
**Action:** Improve description first, skip Task creation until READY

## Common Pitfalls

❌ Creating Tasks for operations not in User Story scope
❌ Tasks too large (>16h)
❌ Missing test Tasks
❌ Vague Task descriptions
❌ No Task dependencies when needed
❌ Duplicate Feature description in User Story
❌ Missing error handling Tasks
❌ No accessibility Tasks for UI work
❌ Estimate mismatch (Task hours ≠ User Story hours)
❌ Auto-deleting existing Tasks without asking
