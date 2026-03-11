---
name: docs
description: Codebase documentation generator - bootstrap, update, and audit hierarchical docs for legacy codebases. Generates CLAUDE.md, architecture.md, and other docs at project, component, and module levels.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "[init|update|audit] or codebase description"
---

# Documentation Generator

Generate, update, and audit hierarchical documentation for any codebase following the docs pattern from `docs/docs-pattern.md` and `.github/copilot/documentation-organization.md`.

## Usage

```
/docs                     # Start full bootstrap (same as /docs init)
/docs init                # Bootstrap documentation for entire codebase
/docs update              # Incrementally refresh docs based on changes
/docs audit               # Gap analysis: report coverage without writing files
/docs init "path/to/repo" # Bootstrap docs for a specific path
```

## Routing

Based on the argument provided, load and follow the appropriate stage file:

### If argument starts with "init"

Read and follow `plugins/documentation/skills/docs/docs-init.md`. Pass any remaining text as the target codebase path.

### If argument starts with "update"

Read and follow `plugins/documentation/skills/docs/docs-update.md`. Pass any remaining text as options (e.g., baseline commit, component filter).

### If argument starts with "audit"

Read and follow `plugins/documentation/skills/docs/docs-audit.md`. Pass any remaining text as the target codebase path.

### If no stage keyword (or a codebase description)

Default to **init** mode. Read and follow `plugins/documentation/skills/docs/docs-init.md`.

## Stage Files

| Stage | Skill | File |
|-------|-------|------|
| Init | `/docs init` | `plugins/documentation/skills/docs/docs-init.md` |
| Update | `/docs update` | `plugins/documentation/skills/docs/docs-update.md` |
| Audit | `/docs audit` | `plugins/documentation/skills/docs/docs-audit.md` |

## What Gets Generated

Following the docs pattern, documentation is created at three levels:

| Level | Location | Files |
|-------|----------|-------|
| Project | `/CLAUDE.md`, `/docs/` | architecture.md, setup.md, features.md, CLAUDE.md |
| Component | `/[component]/docs/` | architecture.md, implementation.md, setup.md, CLAUDE.md |
| Module | `/[path-to-module]/docs/` | CLAUDE.md, architecture.md (only where complexity warrants it) |

## Critical Rules

1. **Always read the stage file** - Do not attempt to run a stage from memory; read the full stage file for current instructions
2. **Follow documentation-organization.md** - Flat files only, CLAUDE.md not README.md, one file per category
3. **Only create files that provide value** - Not every directory needs all doc types
4. **Preserve existing content** - When updating, append/edit sections, never delete human-written content
5. **Present documentation map before writing** - User must approve what will be created (init mode)
