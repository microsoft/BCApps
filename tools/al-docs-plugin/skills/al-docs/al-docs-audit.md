---
name: al-docs-audit
description: Read-only gap analysis of AL codebase documentation - reports coverage and missing files
allowed-tools: Read, Glob, Grep, Bash(pwsh)
argument-hint: "path to AL app or folder (defaults to current directory)"
---

# AL Documentation Audit

Read-only gap analysis. Does NOT create or modify any files.

## Step 1: Generate code map

Run the code map script to get the raw data:

```bash
pwsh -File tools/al-docs-plugin/scripts/Get-ALCodeMap.ps1 -Path "<target path>"
```

This produces: app metadata, object counts per folder, and existing doc files.

## Step 2: Analyze the code map

Using the code map output, identify **functional areas** — folders organized by business domain (e.g., `src/Products/`, `src/Customers/`). Ignore type-grouping folders that just organize files by object type (e.g., `src/Products/Codeunits/` contains only codeunits — it's not a separate feature, it's part of Products).

For each functional area, aggregate the object counts from its child folders and determine if it needs documentation:

- **CLAUDE.md** at the folder root — needed if the area has meaningful complexity (multiple object types, 10+ objects)
- **docs/data-model.md** — needed if 3+ tables
- **docs/business-logic.md** — needed if 3+ codeunits
- **docs/extensibility.md** — needed if interfaces or events present

Compare against existing docs from the code map.

## Step 3: Produce the report

Output a markdown report with:

1. **Summary** — app name, total objects, coverage percentage
2. **App-level docs** — status of CLAUDE.md, data-model.md, business-logic.md, extensibility.md
3. **Functional areas** — each area with its object counts, what docs exist, what's missing
4. **Recommendations** — prioritized list of what to create first
