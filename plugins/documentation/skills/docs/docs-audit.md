---
name: docs-audit
description: Read-only gap analysis of codebase documentation - reports coverage, missing files, and migration opportunities without writing anything
allowed-tools: Read, Glob, Grep, Bash(*)
argument-hint: "path to codebase root (defaults to current directory)"
---

# Documentation Audit

> **Usage**: Invoke to analyze documentation coverage without modifying any files. Produces a gap analysis report showing what exists, what's missing, and what should be migrated.

## Prerequisites

- [ ] Determine the **target codebase root** - use the argument if provided, otherwise use the current working directory
- [ ] Read `.github/copilot/documentation-organization.md` from the **ai-first** repo for the expected documentation standard

**This skill is READ-ONLY. It does NOT create or modify any files.**

---

## Process

**IMPORTANT: Maximize parallelism.** Steps 1-2 below MUST be launched as parallel subagents in a single message. After they complete, Step 3 synthesizes and compares results sequentially.

### Step 1: Parallel discovery (launch ALL subagents at once)

Launch these **four subagents simultaneously** using the Task tool in a single message:

#### Subagent A: Project structure and components

Use Glob and Bash to map the codebase:

1. **Identify components** - Top-level directories that represent distinct components:
   - Look for: `backend/`, `frontend/`, `server/`, `client/`, `api/`, `web/`, `database/`, `infra/`, `shared/`, `packages/`
   - Also look for: `src/` with sub-directories that act as components
2. **Identify tech stack** - Scan for manifest files (package.json, .csproj, requirements.txt, go.mod, etc.)
3. **Identify significant modules** - Directories deeper in the tree with 5+ source files or their own config
4. **Count source files per component** - Report file counts for each identified component

Return: list of components with file counts, tech stack info, list of significant modules.

#### Subagent B: Documentation inventory

Search for all documentation files:

```
Glob patterns to search:
- **/CLAUDE.md
- **/README.md
- **/docs/*.md
- **/docs/**/*.md (user-created subdirectories are OK - flag only if AI processes created them)
- **/*.md in root (misc docs)
```

For each doc file found, record:

- Path
- Last modified date (from git or filesystem)
- Size (line count)
- Whether it follows the flat file pattern

Return: complete list of all documentation files with metadata.

#### Subagent C: Module scoring

Score each significant directory (0-10) based on:

| Factor | Points | How to Detect |
|--------|--------|---------------|
| File count >= 10 | +2 | Glob for source files |
| File count >= 20 | +3 | Glob for source files |
| Has subdirectories | +1 | Directory structure |
| Has own config files | +1 | package.json, tsconfig.json, etc. at module level |
| Cross-module imports | +2 | Grep for import/require/using from other modules |
| Contains business logic | +2 | Heuristic: service/, domain/, models/ in path |
| Large files (500+ LOC) | +1 | File size check |

Classify each as:

- **MUST_DOCUMENT** (7+): Complex, central, many dependencies
- **SHOULD_DOCUMENT** (4-6): Moderate complexity
- **OPTIONAL** (1-3): Simple, few dependencies

Return: scored module list with classifications and reasoning.

**IMPORTANT**: ALL modules scored MUST_DOCUMENT (>= 7) or SHOULD_DOCUMENT (4-6) that lack a `docs/CLAUDE.md` must be reported as MISSING. MUST_DOCUMENT modules that have `docs/CLAUDE.md` but no additional doc file from the standard categories must also be reported as MISSING. These are not optional gaps -- they represent required documentation that needs to be created via `/docs init` or `/docs update`. The audit report must clearly distinguish between MUST/SHOULD gaps (which require action) and OPTIONAL gaps (which are informational only).

#### Subagent D: Migration opportunities and non-standard patterns

Search for documentation in non-standard locations:

| Pattern | Migration Target |
|---------|-----------------|
| `README.md` at any level | `docs/CLAUDE.md` at that level |
| `ARCHITECTURE.md` or `DESIGN.md` | `docs/architecture.md` |
| `CONTRIBUTING.md` | `docs/implementation.md` or `docs/onboarding.md` |
| `SETUP.md` or `INSTALL.md` | `docs/setup.md` |
| `API.md` or `ENDPOINTS.md` | Component `docs/implementation.md` |
| Subdirectories inside `docs/` | Flatten into `docs/[category].md` |
| `.github/memory-bank/*.md` | Distribute to appropriate `docs/` level |

Also check for stale docs referencing deleted files or broken paths.

Return: list of migration opportunities, non-standard files, and broken references.

### Step 2: Determine expected documentation (after subagents complete)

Using the results from all four subagents, build the list of expected documentation files:

#### Project level (always expected)

| File | Required | Condition |
|------|----------|-----------|
| `/CLAUDE.md` | Yes | Always - root project orientation |
| `/docs/architecture.md` | Yes | If 2+ components exist |
| `/docs/setup.md` | Yes | If build/config files exist |
| `/docs/features.md` | Optional | If distinct features are identifiable |

#### Component level (per component)

| File | Required | Condition |
|------|----------|-----------|
| `/[component]/docs/CLAUDE.md` | Yes | Always for identified components |
| `/[component]/docs/architecture.md` | Yes | If component has 10+ source files |
| `/[component]/docs/implementation.md` | Optional | If component has distinct patterns |
| `/[component]/docs/setup.md` | Optional | If component has its own config/setup |
| `/[component]/docs/testing.md` | Optional | If component has test files |

#### Module level (per significant module)

| File | Required | Condition |
|------|----------|-----------|
| `/[module]/docs/CLAUDE.md` | Yes | If module is scored MUST_DOCUMENT or SHOULD_DOCUMENT |
| `/[module]/docs/[additional].md` | Yes | If module is scored MUST_DOCUMENT (>= 7) -- at least one file from the standard categories in `.github/copilot/documentation-organization.md` based on module contents |

### Step 3: Compare expected vs actual and compile report

For each expected file, determine its status:

- **EXISTS** - File is present
- **MISSING** - File does not exist but should
- **STALE** - File exists but hasn't been modified in a long time relative to source changes
- **NON-STANDARD** - File exists but doesn't follow the expected pattern (e.g., README.md instead of CLAUDE.md)

Merge migration opportunities from Subagent D into the final report.

---

## Output Format

Present the audit as a single markdown report:

```markdown
# Documentation Audit Report

**Target**: [codebase root path]
**Date**: [current date]
**Audited by**: `/docs audit`

## Summary

| Metric | Value |
|--------|-------|
| Components found | [count] |
| Significant modules found | [count] (MUST: [n], SHOULD: [n], OPTIONAL: [n]) |
| Expected doc files | [count] |
| Existing doc files | [count] |
| **Coverage** | **[percentage]%** |
| Files to migrate | [count] |
| Non-standard files | [count] |

## Project Level

| Expected File | Status | Notes |
|---------------|--------|-------|
| `/CLAUDE.md` | [status] | [details] |
| `/docs/architecture.md` | [status] | [details] |
| `/docs/setup.md` | [status] | [details] |
| `/docs/features.md` | [status] | [details] |

## Component: [name] ([file count] source files)

| Expected File | Status | Notes |
|---------------|--------|-------|
| `/[component]/docs/CLAUDE.md` | [status] | [details] |
| `/[component]/docs/architecture.md` | [status] | [details] |
| `/[component]/docs/implementation.md` | [status] | [details] |

[Repeat for each component]

## Modules Requiring Documentation

### MUST_DOCUMENT (score 7+)
| Module Path | Score | Files | Reason |
|-------------|-------|-------|--------|
| `/backend/src/services/auth/` | 8 | 12 | Business logic, cross-module imports, large files |

### SHOULD_DOCUMENT (score 4-6)
| Module Path | Score | Files | Reason |
|-------------|-------|-------|--------|
| `/frontend/src/components/dashboard/` | 5 | 8 | Many subcomponents, complex state |

## Migration Opportunities

| Current Location | Recommended Target | Content Summary |
|------------------|--------------------|-----------------|
| `/backend/README.md` | `/backend/docs/CLAUDE.md` | Backend overview (42 lines) |
| `/docs/api/endpoints.md` | `/backend/docs/implementation.md` | API reference (156 lines) |

## Non-Standard Documentation

| File | Issue | Recommendation |
|------|-------|----------------|
| `/docs/guides/setup-guide.md` | Subdirectory in docs/ | Move to `/docs/setup.md` |
| `/frontend/README.md` | Uses README.md | Rename to `/frontend/docs/CLAUDE.md` |

## Recommendations

1. **Quick wins**: [list of easy fixes - renames, moves]
2. **High impact**: [list of most valuable docs to create first]
3. **Run `/docs init`**: To bootstrap all missing documentation automatically
4. **Run `/docs update`**: After init, to set up the update baseline
```

---

## Critical Rules

1. **READ-ONLY** - This skill must not create, modify, or delete any files
2. **Be specific** - Include file counts, paths, and concrete reasons
3. **Score objectively** - Module scoring should be based on measurable criteria, not guesswork
4. **Flag non-standard patterns** - Subdirectories in docs/, README.md usage, memory-bank presence
5. **Actionable output** - Every finding should have a clear recommendation
