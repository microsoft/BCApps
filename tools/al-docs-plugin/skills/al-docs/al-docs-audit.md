---
name: al-docs-audit
description: Read-only gap and correctness analysis of AL codebase documentation - reports coverage, missing files, scoring, and verifies existing docs are accurate
allowed-tools: Read, Glob, Grep, Bash(*)
argument-hint: "path to AL app or folder (defaults to current directory)"
---

# AL Documentation Audit

> **Usage**: Invoke to analyze documentation coverage and correctness for an AL codebase without modifying any files. Produces a gap analysis report showing what exists, what's missing, what should be documented, and whether existing docs accurately reflect the current code.

## Prerequisites

- [ ] Determine the **target path** -- use the argument if provided, otherwise use the current working directory
- [ ] Verify the target contains `.al` files

**This mode is READ-ONLY. It does NOT create or modify any files.**

---

## Process

**Maximize parallelism.** Step 1's three subagents MUST be launched in parallel in a single message. Step 2 synthesizes structural results. Step 3 verifies correctness of existing docs. Step 4 compiles the final report.

### Step 1: Parallel discovery (launch ALL subagents at once)

Launch these **three subagents simultaneously** using the Task tool:

#### Subagent A: App structure and AL object inventory

Use Glob and Grep to map the codebase:

1. **Check for `app.json`** -- if present, extract app name, dependencies, runtime version
2. **Count AL objects by type** -- grep first lines of all `.al` files for object type keywords
3. **Group objects by subfolder** -- count objects per directory at all depths to identify functional areas
4. **Identify all subfolders recursively at any depth** with 3+ AL objects as candidates for documentation
5. **Count total source files** per subfolder at all depths

Return: app metadata, object counts by type, object counts by subfolder.

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

#### Subagent C: Module scoring and gap detection

Score all subfolders recursively at any depth (directories containing `.al` files) using the scoring criteria in `skills/al-docs/references/al-scoring.md`. Read that file for the full scoring table with detection methods. A subfolder can have nested subfolders that each need independent scoring and documentation.

Classify each as:

- **MUST_DOCUMENT** (7+): Needs CLAUDE.md + at least one of data-model/business-logic/extensibility/patterns
- **SHOULD_DOCUMENT** (4-6): Needs CLAUDE.md
- **OPTIONAL** (1-3): Documentation not required

Return: scored subfolder list with classifications and reasoning.

### Step 2: Determine expected documentation

Using results from all three subagents, build the list of expected files. This step is structural -- it determines what files should exist.

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
| `/[subfolder]/docs/CLAUDE.md` | Yes | If scored MUST_DOCUMENT or SHOULD_DOCUMENT |
| `/[subfolder]/docs/[additional].md` | Yes | If scored MUST_DOCUMENT (7+)  |

### Step 3: Correctness verification

For each existing documentation file, launch a subagent to verify its content against the current code. These subagents can run in parallel (one per doc file, or grouped by scope).

Each correctness subagent must:

1. **Read the doc file** in full
2. **Identify claims** -- extract factual statements the doc makes: table relationships, processing flows, decision logic, event descriptions, pattern examples, gotchas
3. **Read the referenced `.al` files** -- for each claim, find the AL source it describes and verify:
   - Do the described relationships still exist? (check `TableRelation` properties)
   - Do the described flows still work that way? (check codeunit logic, procedure calls)
   - Do the described events/interfaces still exist with the same signatures?
   - Do the described patterns still appear in the referenced files?
   - Are mermaid diagrams (ER diagrams, flowcharts) consistent with the current code?
4. **Classify each doc file**:
   - **ACCURATE** -- all claims verified against current code
   - **DRIFT** -- doc exists and structure is fine, but one or more claims no longer match the code. List each incorrect claim with what the code actually does.
   - **OUTDATED** -- significant portions describe behavior that no longer exists or has fundamentally changed

Return: per-file correctness status with specific findings.

### Step 4: Compare expected vs actual and compile report

Combine structural analysis (Step 2) with correctness verification (Step 3).

For each expected file, determine its status:

- **EXISTS -- ACCURATE** -- file is present and content matches the code
- **EXISTS -- DRIFT** -- file is present but contains claims that don't match the code
- **EXISTS -- OUTDATED** -- file is present but substantially wrong
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

| Expected file | Status | Correctness | Notes |
|---------------|--------|-------------|-------|
| `/CLAUDE.md` | [status] | [ACCURATE/DRIFT/OUTDATED/n/a] | [details] |
| `/docs/data-model.md` | [status] | [ACCURATE/DRIFT/OUTDATED/n/a] | [details] |
| `/docs/business-logic.md` | [status] | [ACCURATE/DRIFT/OUTDATED/n/a] | [details] |
| `/docs/extensibility.md` | [status] | [ACCURATE/DRIFT/OUTDATED/n/a] | [details] |
| `/docs/patterns.md` | [status] | [ACCURATE/DRIFT/OUTDATED/n/a] | [details] |

## Correctness findings

For each file with DRIFT or OUTDATED status, list the specific issues:

| File | Claim in doc | What the code actually does |
|------|-------------|----------------------------|
| `/docs/data-model.md` | "Product links to Item via Item No." | Links via `Item SystemId` (Guid), not Item No. |
| `/docs/business-logic.md` | "Orders are always created as sales orders" | Orders can also create sales invoices when `Auto Create Sales Invoice` is enabled |

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
| `/src/Sales/README.md` | Uses README.md | Rename to `/src/Sales/docs/CLAUDE.md` |

## AL object summary by subfolder

| Subfolder | Tables | Codeunits | Pages | Enums | Other | Total | Score |
|-----------|--------|-----------|-------|-------|-------|-------|-------|
| `/src/Sales/` | 4 | 3 | 5 | 2 | 1 | 15 | 8 |
| `/src/Setup/` | 2 | 1 | 3 | 0 | 0 | 6 | 4 |

## Recommendations

1. **Fix incorrect docs**: [list of DRIFT/OUTDATED files -- these are actively misleading]
2. **Quick wins**: [list of easy fixes -- renames, moves]
3. **High impact**: [most valuable docs to create first -- highest-scored undocumented subfolders]
4. **Run `/al-docs update`**: To fix drifted docs and create missing documentation
5. **Run `/al-docs init`**: To bootstrap documentation for areas with no docs at all
```

---

## Critical rules

1. **READ-ONLY** -- this mode must not create, modify, or delete any files
2. **Be specific** -- include object counts, paths, and concrete reasons
3. **Score objectively** -- subfolder scoring based on measurable criteria from `.al` files
4. **Verify against code** -- correctness checks must read actual AL source, not guess from file names or timestamps
5. **Actionable output** -- every finding should have a clear recommendation
6. **Incorrect docs are worse than missing docs** -- prioritize DRIFT/OUTDATED findings over MISSING findings in recommendations
7. **Distinguish required vs optional gaps** -- MUST/SHOULD gaps require action; OPTIONAL gaps are informational
