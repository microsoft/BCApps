---
name: al-docs
description: This skill should be used when the user asks to "document AL code", "generate docs for this app", "create documentation for this extension", "document this BC app", "set up docs for this AL project", "refresh my docs after code changes", "what documentation is missing", or wants to bootstrap, update, or audit documentation for a Business Central AL codebase. Generates hierarchical docs (CLAUDE.md, data-model.md, business-logic.md, extensibility.md, patterns.md) tailored to AL object types, table relationships, event architecture, and extension patterns.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "[init|update|audit] [path]"
---

# AL Documentation Generator

Generate, update, and audit hierarchical documentation for Business Central AL codebases. Produces documentation adapted to AL object types, table relationships, event-driven architecture, and extension patterns.

## Usage

```
/al-docs                        # Bootstrap docs (same as /al-docs init)
/al-docs init                   # Bootstrap documentation for AL app or folder
/al-docs init "path/to/app"     # Bootstrap docs for a specific path
/al-docs update                 # Incrementally refresh docs based on changes
/al-docs audit                  # Read-only gap analysis without writing files
```

## Routing

Based on the argument provided, load and follow the appropriate mode file. Always read the full mode file before executing -- never run from memory.

### If argument starts with "init" (or no argument)

Read and follow `skills/al-docs/al-docs-init.md` from the plugin directory. Pass any remaining text as the target path.

### If argument starts with "update"

Read and follow `skills/al-docs/al-docs-update.md` from the plugin directory. Pass any remaining text as options (baseline commit, path filter).

### If argument starts with "audit"

Read and follow `skills/al-docs/al-docs-audit.md` from the plugin directory. Pass any remaining text as the target path.

## Mode files

| Mode | Command | File |
|------|---------|------|
| Init | `/al-docs init` | `skills/al-docs/al-docs-init.md` |
| Update | `/al-docs update` | `skills/al-docs/al-docs-update.md` |
| Audit | `/al-docs audit` | `skills/al-docs/al-docs-audit.md` |

## What gets generated

Documentation is hierarchical -- more general at the app level, more specific deeper in the tree.

### Doc types

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Mental model: what this area does, how it works, and non-obvious things to know |
| `data-model.md` | How tables relate and why -- intent, design decisions, gotchas (not field lists). Always includes a mermaid ER diagram. |
| `business-logic.md` | Processing flows as narrative -- decision points, error handling. Includes mermaid flowcharts for processes with branching. |
| `extensibility.md` | Extension points, events, interfaces -- how to customize without modifying core code |
| `patterns.md` | Non-obvious coding patterns (including legacy patterns to avoid in new code) |

### Documentation levels

| Level | Location | Content |
|-------|----------|---------|
| App (has `app.json`) | `/CLAUDE.md`, `/docs/` | App-wide overview, full data model, cross-cutting logic, extensibility, and patterns |
| Subfolder at any depth (scored 7+) | `/[path]/docs/` | CLAUDE.md + at least one of data-model/business-logic/extensibility/patterns |
| Subfolder at any depth (scored 4-6) | `/[path]/docs/` | CLAUDE.md only |

### Scope detection

1. **Target has `app.json`** -- document the entire app as the project level
2. **Target is a folder without `app.json`** -- document that folder; if subfolders at any depth have enough substance, they get their own docs
3. **Recursive evaluation** -- subfolders are evaluated recursively; a subfolder's subfolder can be documented independently if it scores high enough
4. **Locality principle** -- deeper docs are more specific; higher docs are more general, pointing down to specifics

## AL object types and scoring

For the full list of AL object types, subfolder scoring criteria, and change-to-doc mapping, read `skills/al-docs/references/al-scoring.md`.

Summary of scoring classifications:

- **MUST_DOCUMENT (7+)**: CLAUDE.md + at least one of data-model/business-logic/extensibility/patterns
- **SHOULD_DOCUMENT (4-6)**: CLAUDE.md only
- **OPTIONAL (1-3)**: Skip

## Microsoft Docs MCP

During discovery, use the Microsoft Learn MCP tools (`microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search`) to research the feature area being documented. This provides context about the intended behavior, official terminology, and design rationale that may not be obvious from the source code alone.

- Search for the app's feature area (e.g., "Business Central Shopify connector", "Business Central inventory management") to understand what the feature is supposed to do
- Use this context to write better "How it works" and "Things to know" sections
- **Source code is the source of truth.** Microsoft docs may be outdated or describe planned behavior that differs from the implementation. When docs conflict with what the code actually does, trust the code. Note the discrepancy in documentation if it's meaningful (e.g., "the docs describe X, but the implementation does Y").

## Critical rules

1. **Always read the mode file** -- never attempt to run a mode from memory
2. **User approves before writing** -- present the documentation map or update plan first
3. **Based on real analysis** -- every statement must trace back to actual AL code read during discovery
4. **Preserve existing content** -- when updating, add/edit sections, never delete human-written content
5. **Locality** -- document as locally as possible, getting more general going up the tree
6. **No mechanical listings** -- never list fields, procedures, or AL objects that an LLM can read from code. Capture intent, relationships, gotchas, and design decisions.
7. **Concise over comprehensive** -- shorter docs with real knowledge beat longer docs that list everything
8. **Use Microsoft Docs MCP** (init mode) -- query Microsoft Learn during init discovery to understand feature intent, but always trust source code over docs when they conflict
9. **Formatting** -- sentence case headers, no em dashes (use `--`), blank line before lists
