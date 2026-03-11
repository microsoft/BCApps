# Azure DevOps Integration Rules

> **TL;DR**: ADO = Phases/Features only. TASKS.md = Individual tasks. AI auto-syncs progress.

## Quick Reference

| Action | Command/Location |
|--------|------------------|
| Create Feature | `az boards work-item create --type "Feature"` |
| Update Feature | `az boards work-item update --id [ID]` |
| Title Format | `SOA Phase X: [Phase Name]` |
| Description | Compact HTML from `phaseX-compact.html` |
| Project Config | `.github/copilot/ado-project-info.md` |

---

## Overview

**Core Principle:**
> **Azure DevOps tracks Features (Phases). TASKS.md tracks individual tasks.**

**⚠️ IMPORTANT:** For complete task workflow including documentation, timestamps, and completion rules, see `task-workflow.md`. This file contains ONLY Azure DevOps-specific integration rules.

---

## Azure DevOps Feature-Level Tracking

### What to Track in Azure DevOps

**✅ CREATE ADO Work Items (Features) For:**

- **Phases** (e.g., "Phase 2: Core Teams Tab Development")
- **Major milestones** (e.g., "Phase 4 Complete")
- **High-level blockers** (e.g., "Phase 3 blocked - licensing approval needed")

**❌ DO NOT Create ADO Work Items For:**

- Individual tasks (e.g., Task 2.3.4, Task 2.3.5)
- Daily progress updates
- Technical implementation details
- Sub-task breakdowns

---

## Creating ADO Feature Work Items

### Feature Work Item Structure

**Title Format:**
```
SOA Phase X: [Phase Name]
```

**IMPORTANT:** Always prepend "SOA " to the feature name.

**Example:** `SOA Phase 2: Core Scheduling Service Development`

---

### Description Format (Compact HTML)

**⚠️ CRITICAL:** ADO work item descriptions have length limits. Use **compact HTML format** with grouped task summaries instead of listing all individual tasks.

**Steps:**

1. **Create compact HTML description file** (e.g., `PRDs/field-service-scheduling/phaseX-compact.html`)
2. **Use single-line HTML format** (no line breaks to prevent PowerShell truncation)
3. **Link to TASKS.md** for full task details

**Template:**

```html
<h2>Overview</h2><p>[Brief description of phase goals]</p><p><strong>Note:</strong> This feature is being used for SOA Training.</p><h2>Tasks</h2><p><strong>Full Details:</strong> See PRDs/[project]/tasks.md (Phase X)</p><p><strong>Summary:</strong> 0/Y tasks complete (0%)</p><p><strong>Key Areas:</strong></p><ul><li>[Area 1] (N tasks): [Summary]</li><li>[Area 2] (N tasks): [Summary]</li><li>[Area 3] (N tasks): [Summary]</li></ul><h2>Timeline</h2><ul><li><strong>Start:</strong> Week X</li><li><strong>End:</strong> Week Y</li><li><strong>Status:</strong> New</li></ul><h2>Dependencies</h2><p>Depends on: Phase X-1</p>
```

**Real Example:**

```html
<h2>Overview</h2><p>Setup project structure, Docker Compose, Prisma ORM, authentication system, and basic frontend with Fluent UI.</p><p><strong>Note:</strong> This feature is being used for SOA Training.</p><h2>Tasks</h2><p><strong>Full Details:</strong> See PRDs/field-service-scheduling/tasks.md (Phase 1)</p><p><strong>Summary:</strong> 0/41 tasks complete (0%)</p><p><strong>Key Areas:</strong></p><ul><li>Project Setup (4 tasks): Git, npm workspaces, TypeScript, ESLint</li><li>Database Setup (6 tasks): Docker Compose, Prisma schema, migrations, seed data</li><li>Backend APIs (4 tasks): Express, middleware, Zod validation</li><li>Authentication (6 tasks): bcrypt, JWT, auth middleware, RBAC, login/logout</li><li>User Management APIs (3 tasks): CRUD endpoints</li><li>Skills Management APIs (1 task): CRUD endpoints</li><li>Frontend Foundation (7 tasks): React/Vite, Fluent UI, React Router, auth context, login page, layout</li><li>Testing (3 tasks): Jest setup, auth tests, documentation</li></ul><h2>Timeline</h2><ul><li><strong>Start:</strong> Week 1</li><li><strong>End:</strong> Week 2</li><li><strong>Status:</strong> New</li></ul><h2>Dependencies</h2><p>None (First phase)</p>
```

**Why Compact Format?**
- ✅ Avoids ADO length limits (individual task lists too long)
- ✅ Provides high-level overview for stakeholders
- ✅ Links to TASKS.md for full details
- ✅ Groups tasks by functional area
- ✅ Single-line HTML prevents PowerShell truncation issues

---

### Creating Feature via PowerShell

**Command:**

```powershell
# Read description from compact HTML file
$description = Get-Content "PRDs\[project]\phaseX-compact.html" -Raw

# Load project info from ado-project-info.md
# Use values: Area Path, Iteration, Org from .github/copilot/ado-project-info.md

# Create feature work item
az boards work-item create `
  --title "SOA Phase X: [Phase Name]" `
  --type "Feature" `
  --description $description `
  --area "OneCRM\CRM.Services.Scheduling" `
  --iteration "OneCRM\Bi-Weekly\2025\2510\2510.3" `
  --org "https://dynamicscrm.visualstudio.com"
```

**Tags to Add:**

- `phase`
- `feature`
- `soa-training`
- [relevant technology tags]

---

### Updating Feature Work Items

**When to Update:**

ADO Feature work items are updated **automatically by AI** when:

- Phase status changes (New → In Progress → Done)
- Task completion percentage changes significantly
- Phase timestamps are updated

**Manual Update (if needed):**

```powershell
# Update description
$description = Get-Content "PRDs\[project]\phaseX-compact.html" -Raw

# Use Org value from .github/copilot/ado-project-info.md
az boards work-item update `
  --id [WORK-ITEM-ID] `
  --description $description `
  --org "https://dynamicscrm.visualstudio.com"

# Update state
az boards work-item update `
  --id [WORK-ITEM-ID] `
  --state "Active" `
  --org "https://dynamicscrm.visualstudio.com"
```

**Possible States:**

- **New** - Phase not started
- **Active** - Phase in progress
- **Resolved** - Phase complete, pending verification
- **Closed** - Phase verified and closed

---

## AI Auto-Sync to ADO

### How It Works

When you complete tasks in TASKS.md, AI automatically:

1. **Detects completion** - Monitors `[x]` checkboxes in TASKS.md
2. **Counts completed tasks** - Calculates progress percentage
3. **Determines phase status** - New/Active/Resolved/Closed
4. **Updates ADO Feature** - Syncs via `az boards` CLI
5. **Confirms to user** - Shows success message

**Success Message:**
```
✅ Updated Feature (Work Item ID 155): Active (12/25 tasks complete - 48%)
```

### What Gets Synced

- **Phase Status** (New → Active → Resolved → Closed)
- **Progress Percentage** (calculated from completed tasks)
- **Task Completion Count** (X/Y tasks complete)
- **Phase Timestamps** (Started, Last Updated, Completed)

**Note:** Individual task details remain in TASKS.md only. ADO shows high-level phase progress.

---

## ADO Work Item Links in TASKS.md

### Phase Header Format

Each phase in TASKS.md should link to its ADO Feature work item:

```markdown
## PHASE 2: CORE SCHEDULING SERVICE DEVELOPMENT (Weeks 3-6)

**ADO Feature:** [SOA Work Item #155](https://dynamicscrm.visualstudio.com/OneCRM/_workitems/edit/155) - SOA Training
**Status:** In Progress  
**Progress:** 12/25 tasks complete (48%)  
**Phase Started**: 2025-09-15 09:00:00 UTC-7
**Last Updated**: 2025-10-09 14:30:00 UTC-7
**Phase Completed**: TBD
**Phase Duration**: TBD
```

**Note:** Use Organization and Project values from `.github/copilot/ado-project-info.md` for work item URLs.

**Link Format:**
```markdown
**ADO Feature:** [SOA Work Item #[ID]](https://dynamicscrm.visualstudio.com/OneCRM/_workitems/edit/[ID]) - [Title]
```

---

## Troubleshooting ADO Integration

### Common Issues

**Issue:** "az boards command not found"
**Solution:** Install Azure CLI and boards extension:
```powershell
az extension add --name azure-devops
az login
```

**Issue:** "Permission denied when updating work item"
**Solution:** Verify you have write access to OneCRM project in Azure DevOps.

**Issue:** "Description too long error"
**Solution:** Use compact HTML format with task summaries, not individual task lists.

**Issue:** "AI didn't update ADO Feature automatically"
**Solution:** Check that:
- Phase header has correct ADO Feature link
- TASKS.md was updated with `[x]` checkbox
- You have active Azure CLI session (`az login`)

---

## Best Practices

### DO:

- ✅ Create one Feature work item per Phase
- ✅ Use compact HTML descriptions with task summaries
- ✅ Link ADO Feature in TASKS.md phase header
- ✅ Let AI handle automatic synchronization
- ✅ Use consistent "SOA Phase X:" title format
- ✅ Keep ADO focused on high-level progress

### DON'T:

- ❌ Create work items for individual tasks
- ❌ Paste full task lists into ADO descriptions (too long)
- ❌ Manually update ADO when AI can do it automatically
- ❌ Skip linking ADO Feature in TASKS.md
- ❌ Use ADO for detailed technical documentation
- ❌ Forget to prepend "SOA " to feature titles

---

## ADO Work Item Quality Skills

The Claude marketplace includes specialized skills for evaluating and improving Azure DevOps work item quality.

### Available Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| **Feature Completeness** | `/feature-completeness [Feature-ID]` | 5-dimension scoring (0-100) of Feature work items with improvement recommendations |
| **User Story Improvement** | `/user-story-improvement [Story-ID]` | Enriches User Story descriptions and generates actionable child Tasks |
| **Feature Workflow** | `/feature-workflow [Feature-ID]` | End-to-end: evaluate Feature, design parallelizable stories, create and improve them |

### Feature Completeness Evaluation

**Purpose:** Evaluate a Feature work item to ensure it has sufficient detail for User Story creation.

**Usage:**
```
/feature-completeness 123456
```

**What it does:**
- Scores Feature across 5 dimensions (0-100 scale):
  - User Value Clarity (0-20)
  - Scope Definition (0-20)
  - Acceptance Criteria Quality (0-20)
  - Story Readiness (0-20)
  - Dependencies and Context (0-20)
- Validates mandatory requirements:
  - ❌ Acceptance Criteria explicitly defined
  - ❌ Automation Test User Story exists as child
  - ❌ Test Case work item linked
- Proposes improvements if score < 90/100
- Provides before/after score comparison

**When to use:**
- Before creating child User Stories for a Feature
- During sprint planning Feature reviews
- To ensure Features meet quality standards before approval

### User Story Improvement

**Purpose:** Enrich User Story descriptions with context and create actionable Tasks.

**Usage:**
```
/user-story-improvement 234567
```

**What it does:**
- Analyzes User Story and parent Feature context
- Checks for Feature-level automation/accessibility User Stories
- Generates improved description with:
  - User Story format (As a... I want... so that...)
  - Context from parent Feature
  - Implementation notes
  - Out of scope items
- Creates Acceptance Criteria for dedicated AC field
- Recommends Task breakdown (1-16h each)
- Avoids duplicate Tasks when Feature has dedicated test stories

**When to use:**
- After User Story creation but before development
- When User Story lacks detail or acceptance criteria
- To break down a User Story into specific Tasks

### Feature Workflow (End-to-End)

**Purpose:** Complete pipeline from Feature evaluation through User Story creation with task decomposition.

**Usage:**
```
/feature-workflow 123456             # Full 3-phase workflow
/feature-workflow evaluate 123456    # Phase 1 only
/feature-workflow design 123456      # Phase 2 only
/feature-workflow create 123456      # Phase 3 only
```

**What it does (3 phases):**

1. **Evaluate & Improve Feature** - Scores Feature (0-100), proposes improvements, re-scores after improvement
2. **Design User Stories** - Decomposes Feature into parallelizable stories with AC coverage matrix
3. **Create & Improve Stories** - Creates stories in ADO, enriches each with descriptions, ACs, and Tasks

**Key features:**
- Designs stories for parallel execution across multiple developer tracks
- User gates between every phase (review before proceeding)
- Can start from any phase via subcommands
- Chains `/feature-completeness` and `/user-story-improvement` logic into a single flow

**When to use:**
- Starting a new Feature from scratch
- When you want the full pipeline: evaluate -> design -> create
- When parallelizability of work items matters

### Prerequisites

**Supported Modes:**

All skills automatically detect available tools and operate in one of three modes:

| Mode | Requirements | Experience |
|------|--------------|------------|
| **MCP Mode** (Best) | Azure DevOps MCP tools configured | Full automation - fetch, analyze, update |
| **CLI Mode** (Good) | Azure CLI installed (`az boards` extension) | Semi-automated - generates CLI commands for you to run |
| **Manual Mode** (Basic) | None | Analyzes content you provide, outputs formatted results |

**Common Requirements:**
- ✅ Read/write permissions for the ADO project (for MCP/CLI modes)
- ✅ Valid work item IDs or content to analyze

### Best Practices for Quality Skills

**DO:**
- ✅ Use Feature evaluation before creating User Stories
- ✅ Review proposed improvements before applying
- ✅ Check for mandatory items (ACs, automation stories, test cases)
- ✅ Let skills detect Feature-level test coverage to avoid duplicate Tasks

**DON'T:**
- ❌ Auto-approve without reviewing generated content
- ❌ Ignore mandatory requirement warnings
- ❌ Create redundant test Tasks if Feature has dedicated test stories

**See:** `.github/prompts/ado/README.md` for detailed usage guide and examples.

---

## Reference

**Project Configuration:** See `.github/copilot/ado-project-info.md` for current project details:

- Azure DevOps Organization URL
- Project name
- Area Path
- Iteration Path
- Repository information

**CLI Documentation:** https://docs.microsoft.com/en-us/cli/azure/boards/work-item

**ADO Quality Skills:** See `.github/prompts/ado/README.md` for complete guide

---

**For complete task workflow, documentation practices, and timestamp tracking, see `task-workflow.md`.**

---

**Last Updated:** February 11, 2026 by bbarrette
