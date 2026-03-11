---
name: docs-update
description: Incrementally refresh codebase documentation based on what changed since docs were last generated or updated
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "[baseline commit/tag/date] or [component filter]"
---

# Documentation Update

> **Usage**: Invoke to incrementally update existing documentation. Detects what changed in the codebase, maps changes to affected docs, and performs targeted updates while preserving human-written content.

## Prerequisites

- [ ] Verify documentation already exists (if not, suggest running `/docs init` first)
- [ ] Read `.github/copilot/documentation-organization.md` from the **ai-first** repo for the flat file rules
- [ ] Determine the **baseline** for detecting changes (see Step 1)

---

## Process Overview

```
Step 1: Detect changes (git-based or full rescan)
    ↓
Step 2: Map changes to documentation
    ↓
Step 3: Targeted regeneration (parallel sub-agents)
    ↓
Step 4: Staleness report
```

---

## Step 1: Detect changes

### Determine the baseline

Use the first available method:

1. **User-provided baseline** - If the user passes a commit hash, tag, branch, or date as argument, use that
2. **Marker file** - Check for `.docs-updated` in the codebase root. If it exists, it contains the last commit hash when docs were updated. Use that as the baseline.
3. **Git log of docs** - Find the most recent commit that modified any `docs/` directory or `CLAUDE.md` file. Use the commit before that as baseline.
4. **Full rescan** - If no git history is available or none of the above work, fall back to a full rescan (re-run discovery from docs-init and diff against existing docs)

### Get changed files

For git-based detection, run:

```bash
git diff --name-only --diff-filter=ACDMR <baseline>..HEAD
```

This produces a list of Added, Copied, Deleted, Modified, and Renamed files.

Also check for new directories that may need documentation:

```bash
git diff --name-only --diff-filter=A <baseline>..HEAD | xargs -I{} dirname {} | sort -u
```

### Categorize changes

Group changed files by their documentation scope:

- **Project-level impact**: Changes to root config files, CI/CD, cross-component files
- **Component-level impact**: Changes within a specific component (backend/, frontend/, etc.)
- **Module-level impact**: Changes within a specific module deeper in the tree
- **Documentation-only changes**: Changes to existing doc files (may need cross-reference updates)
- **New directories**: May need new documentation entries

---

## Step 2: Map changes to documentation

For each group of changes, determine which doc files need updating:

### Mapping rules

| Change Type | Affected Documentation |
|-------------|----------------------|
| New dependency added (package.json, .csproj, etc.) | `/docs/setup.md`, component `setup.md` |
| New API endpoint or route | Component `architecture.md`, `implementation.md` |
| Schema/model change | Component `architecture.md` (data model section) |
| New component directory created | Needs new component-level docs (CLAUDE.md at minimum) |
| New module directory created | Evaluate if module-level docs are needed (use scoring from docs-init) |
| Architectural change (new pattern, restructure) | `architecture.md` at affected level |
| Build/config change | `setup.md` at affected level |
| Test infrastructure change | `testing.md` at affected level |
| File deleted or moved | Check for broken references in existing docs |
| README.md created or modified | Flag for migration to CLAUDE.md |

### Coverage gap check

In addition to change-driven updates, scan for **existing modules that should have documentation but don't**. Use the module scoring criteria from docs-init (file count, dependencies, complexity, business logic). Any module scoring MUST_DOCUMENT (>= 7) or SHOULD_DOCUMENT (4-6) that lacks a `docs/CLAUDE.md` must be included in the update plan as a CREATE action. MUST_DOCUMENT modules that have `docs/CLAUDE.md` but lack any additional doc file from the standard categories must also be included as a CREATE action. This ensures documentation coverage grows over time, not just for new code but for previously undocumented areas.

**File selection by category** (from docs-init):

| Category | CLAUDE.md | Additional files |
|----------|-----------|-----------------|
| MUST_DOCUMENT (>= 7) | Required | At least one additional file from the standard categories in `.github/copilot/documentation-organization.md` based on what the module contains |
| SHOULD_DOCUMENT (4-6) | Required | None -- CLAUDE.md alone is sufficient |
| OPTIONAL (1-3) | Skip | Skip |

### Produce an update plan

Before writing anything, present the update plan to the user:

```markdown
## Documentation Update Plan

### Baseline
- Comparing against: [commit/tag/date]
- Files changed: [count]
- Components affected: [list]

### Updates Planned

#### Project Level
| File | Action | Reason |
|------|--------|--------|
| `/docs/architecture.md` | UPDATE | New caching layer added |
| `/docs/setup.md` | UPDATE | Redis dependency added |

#### Component: backend
| File | Action | Reason |
|------|--------|--------|
| `/backend/docs/architecture.md` | UPDATE | New service added |
| `/backend/docs/implementation.md` | UPDATE | New API patterns |

#### New Documentation Needed
| File | Action | Reason |
|------|--------|--------|
| `/backend/src/services/cache/docs/CLAUDE.md` | CREATE | New module (8 files) |

### No Update Needed
- `/frontend/docs/` - No frontend changes detected
```

Wait for user approval before proceeding.

---

## Step 3: Targeted regeneration

Launch sub-agents only for affected areas. Each agent handles one component or scope.

### Agent Instructions

Each update agent must:

1. **Read the existing doc file** in full
2. **Read the changed source files** that affect this doc
3. **Identify what sections need updating**:
   - New sections to add (for new functionality)
   - Existing sections to revise (for changed functionality)
   - References to update (for moved/renamed files)
   - Sections to flag as potentially stale (for deleted functionality)
4. **Apply updates conservatively**:
   - **ADD** new sections for new functionality
   - **EDIT** existing sections where facts changed (update specific details, not rewrite)
   - **NEVER DELETE** sections unless the corresponding code was deleted - if unsure, add a `<!-- TODO: verify if still current -->` comment
   - **PRESERVE** formatting, voice, and any human-written narrative
5. **Add an "Updated" note** to modified sections: `*Updated: [date] - [brief reason]*`

### For new documentation files

If the update plan includes CREATE actions (new modules that need docs), the agent should:

1. Read the new module's source files
2. Generate docs using the templates from docs-init.md
3. Follow the same flat file rules

### Parallel execution

Group updates by component/scope and launch sub-agents in parallel:
- One agent per affected component
- One agent for project-level updates
- One agent per new module group needing docs

Send all Task tool calls in a single message for maximum parallelism.

---

## Step 4: Staleness report

After all updates complete, generate a report:

```markdown
## Documentation Update Complete

### Changes Applied
| File | Action | Details |
|------|--------|---------|
| `/docs/architecture.md` | UPDATED | Added caching layer section |
| `/backend/docs/architecture.md` | UPDATED | Updated service list |
| `/backend/src/services/cache/docs/CLAUDE.md` | CREATED | New module documentation |

### Potentially Stale (needs human review)
| File | Concern |
|------|---------|
| `/backend/docs/implementation.md` | Auth service was refactored but patterns section may be outdated |
| `/docs/features.md` | Feature X code was deleted but feature doc remains |

### New Modules Without Documentation
| Module | Files | Complexity | Recommendation |
|--------|-------|------------|----------------|
| `/backend/src/services/payments/` | 15 | HIGH | Run `/docs init` for this module |

### Cross-Reference Issues
| File | Issue |
|------|-------|
| `/backend/docs/CLAUDE.md` | References `/backend/src/old-path/` which was moved |

### Marker Updated
Updated `.docs-updated` with current commit hash: [hash]
```

---

## Update the marker file

After successful completion, write/update `.docs-updated` in the codebase root:

```
# Documentation last updated
commit: [current HEAD commit hash]
date: [current date]
scope: [full|component-name|module-path]
```

---

## Critical Rules

1. **Never overwrite human content** - Add and edit, never delete unless code was deleted
2. **Show the plan first** - User must approve the update plan before any writes
3. **Conservative updates** - When in doubt, flag as "potentially stale" rather than making assumptions
4. **Flat files only** - Follow documentation-organization.md rules
5. **Update the marker** - Always write `.docs-updated` after successful completion
6. **Sentence case headers** - No em dashes, blank lines before lists, language on code blocks
