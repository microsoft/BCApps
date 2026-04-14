---
name: al-docs-audit
description: Read-only gap analysis of AL codebase documentation - reports coverage, missing files, and scoring without writing anything
allowed-tools: Read, Glob, Grep, Agent, Bash(git, cat, find, head, tail, wc, sort, uniq, jq, ls, grep, awk, sed)
argument-hint: "path to AL app or folder (defaults to current directory)"
---

# AL Documentation Audit

> **Usage**: Invoke to analyze documentation coverage for an AL codebase without modifying any files. Produces a gap analysis report showing what exists, what's missing, and what should be documented.

## Tool usage rules

**Prefer the built-in Read, Glob, and Grep tools** for file operations — they are faster and more reliable. Shell commands are available as a fallback when needed.

Available tools:
- **Read, Glob, Grep** -- built-in tools, prefer these for file operations
- **Agent** -- launch subagents for parallel work
- **Shell** -- `git`, `cat`, `find`, `head`, `tail`, `wc`, `sort`, `uniq`, `jq`, `ls`, `grep`, `awk`, `sed`

**Do NOT use** `python3`, `curl`, `wget`, `nc`, or any tool not listed above — they are blocked.

## Prerequisites

- [ ] Determine the **target path** -- use the argument if provided, otherwise use the current working directory
- [ ] Verify the target contains `.al` files

**This mode is READ-ONLY. It does NOT create or modify any files.**

---

## Process

**Maximize parallelism.** Step 1 launches two subagents in parallel. Step 2 scores subfolders using the structure data. Step 3 compiles the final report.

### Step 1: Parallel discovery (launch BOTH subagents at once)

Launch these **two subagents simultaneously** using the Agent tool:

#### Subagent A: App structure and AL object inventory

Use Glob and Grep to map the codebase:

1. **Check for `app.json`** -- if present, extract app name, dependencies, runtime version
2. **Count AL objects by type** -- grep first lines of all `.al` files for object type keywords
3. **Group objects by subfolder** -- count objects per directory at all depths to identify functional areas
4. **Identify all subfolders recursively at any depth** with 3+ AL objects as candidates for documentation
5. **Count total source files** per subfolder at all depths
6. **Detect events and interfaces** -- grep for `[IntegrationEvent]`, `[BusinessEvent]`, `[EventSubscriber]`, `^interface ` per subfolder

Return: app metadata, object counts by type, object counts by subfolder, event/interface presence per subfolder.

#### Subagent B: Documentation inventory

Search for all existing documentation files:

```
Glob patterns to search:
- **/CLAUDE.md
- **/README.md
- **/docs/*.md
- **/docs/**/*.md
```

For each doc file found, record:

- Path
- Size (line count)
- Whether it follows the expected pattern (CLAUDE.md not README.md, flat files in docs/)

Also check for a `.docs-updated` marker file.

Return: complete list of all documentation files with metadata.

### Step 2: Score subfolders

Using the object counts and event/interface data from Subagent A, score all subfolders using the criteria in `references/al-scoring.md`. Read that file for the full scoring table. A subfolder can have nested subfolders that each need independent scoring.

Classify each as:

- **MUST_DOCUMENT** (7+): Needs CLAUDE.md + at least one of data-model/business-logic/extensibility/patterns
- **SHOULD_DOCUMENT** (4-6): Needs CLAUDE.md
- **OPTIONAL** (1-3): Documentation not required

### Step 3: Determine expected documentation

Using results from Steps 1 and 2, build the list of expected files.

#### App level (if `app.json` exists)

| File | Required | Condition |
|------|----------|-----------|
| `/CLAUDE.md` | Yes | Always -- app orientation |
| `/docs/data-model.md` | Yes | If 3+ tables exist |
| `/docs/business-logic.md` | Yes | If 3+ codeunits exist |
| `/docs/extensibility.md` | Yes | If events or interfaces detected |
| `/docs/patterns.md` | Optional | If distinct patterns detected |

#### Subfolder level

| File | Required | Condition |
|------|----------|-----------|
| `/[subfolder]/CLAUDE.md` | Yes | If scored MUST_DOCUMENT or SHOULD_DOCUMENT |
| `/[subfolder]/docs/[additional].md` | Yes | If scored MUST_DOCUMENT (7+) |

### Step 4: Compare expected vs actual and compile report

For each expected file, determine its status:

- **EXISTS** -- file is present
- **MISSING** -- file does not exist but should
- **STALE** -- file exists but hasn't been modified relative to recent `.al` changes (check git timestamps)
- **NON-STANDARD** -- file exists but doesn't follow expected pattern (e.g., README.md instead of CLAUDE.md)

---

## Output format

Present the audit as a single markdown report:

```markdown
# AL documentation audit report

**Target**: [path]
**Date**: [current date]
**Audited by**: `/al-docs audit`

## Summary

| Metric | Value |
|--------|-------|
| App name | [from app.json or folder name] |
| Total AL objects | [count] |
| Tables/tableextensions | [count] |
| Codeunits | [count] |
| Pages/pageextensions | [count] |
| Other objects | [count] |
| Subfolders with AL objects | [count] |
| Subfolders scored MUST | [count] |
| Subfolders scored SHOULD | [count] |
| Expected doc files | [count] |
| Existing doc files | [count] |
| **Coverage** | **[percentage]%** |

## App level

| Expected file | Status | Notes |
|---------------|--------|-------|
| `/CLAUDE.md` | [status] | [details] |
| `/docs/data-model.md` | [status] | [details] |
| `/docs/business-logic.md` | [status] | [details] |
| `/docs/extensibility.md` | [status] | [details] |
| `/docs/patterns.md` | [status] | [details] |

## Subfolders requiring documentation

### MUST_DOCUMENT (score 7+)

| Subfolder | Score | AL objects | Tables | Codeunits | Has docs? | Missing |
|-----------|-------|-----------|--------|-----------|-----------|---------|
| `/src/Sales/` | 8 | 12 | 4 | 3 | Partial | data-model.md |

### SHOULD_DOCUMENT (score 4-6)

| Subfolder | Score | AL objects | Has CLAUDE.md? |
|-----------|-------|-----------|----------------|
| `/src/Reports/` | 5 | 8 | No |

## Non-standard documentation

| File | Issue | Recommendation |
|------|-------|----------------|
| `/src/Sales/README.md` | Uses README.md | Rename to `/src/Sales/CLAUDE.md` |

## AL object summary by subfolder

| Subfolder | Tables | Codeunits | Pages | Enums | Other | Total | Score |
|-----------|--------|-----------|-------|-------|-------|-------|-------|
| `/src/Sales/` | 4 | 3 | 5 | 2 | 1 | 15 | 8 |
| `/src/Setup/` | 2 | 1 | 3 | 0 | 0 | 6 | 4 |

## Recommendations

1. **Quick wins**: [list of easy fixes -- renames, moves]
2. **High impact**: [most valuable docs to create first -- highest-scored undocumented subfolders]
3. **Run `/al-docs init`**: To bootstrap all missing documentation
4. **Run `/al-docs update`**: After init, to set up the update baseline
```

---

## Critical rules

1. **READ-ONLY** -- this mode must not create, modify, or delete any files
2. **Be specific** -- include object counts, paths, and concrete reasons
3. **Score objectively** -- subfolder scoring based on measurable criteria from `.al` files
4. **Actionable output** -- every finding should have a clear recommendation
5. **Distinguish required vs optional gaps** -- MUST/SHOULD gaps require action; OPTIONAL gaps are informational
