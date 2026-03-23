---
name: al-docs-update
description: Incrementally refresh AL codebase documentation based on what changed since docs were last generated or updated
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "[baseline commit/tag/date] or [path filter]"
---

# AL Documentation Update

> **Usage**: Invoke to incrementally update existing documentation for an AL codebase. Detects what changed, maps changes to affected docs, and performs targeted updates while preserving human-written content.

## Prerequisites

- [ ] Verify documentation already exists (if not, suggest running `/al-docs init` first)
- [ ] Determine the **target path** -- use the argument if a path is provided, otherwise use the current working directory
- [ ] Verify the target contains `.al` files

---

## Process overview

```
Step 1: Detect changes (git-based or full rescan)
    |
Step 2: Map changes to documentation
    |
Step 3: Targeted regeneration (parallel sub-agents)
    |
Step 4: Staleness report
```

---

## Step 1: Detect changes

### Determine the baseline

Use the first available method:

1. **User-provided baseline** -- if the user passes a commit hash, tag, branch, or date as argument, use that
2. **Marker file** -- check for `.docs-updated` in the target root. If it exists, it contains the last commit hash when docs were updated
3. **Git log of docs** -- find the most recent commit that modified any `docs/` directory or `CLAUDE.md` file. Use the commit before that as baseline
4. **Full rescan** -- if no git history is available, fall back to a full rescan (re-run discovery from al-docs-init and diff against existing docs)

### Get changed files

For git-based detection:

```bash
git diff --name-only --diff-filter=ACDMR <baseline>..HEAD -- '*.al'
```

This produces a list of added, modified, deleted, and renamed `.al` files.

Also check for new directories:

```bash
git diff --name-only --diff-filter=A <baseline>..HEAD -- '*.al' | xargs -I{} dirname {} | sort -u
```

### Categorize changes by AL object type

For each changed `.al` file, read the first line to determine the object type, then map it to the affected doc file using the change-to-doc mapping in `skills/al-docs/references/al-scoring.md`.

### Group by scope

Group changed files by their documentation scope:

- **App-level impact**: Changes to `app.json`, cross-cutting codeunits, or objects in the app root
- **Subfolder-level impact**: Changes within a specific subfolder (e.g., `src/Sales/`)
- **New subfolders**: Directories with new `.al` files that didn't exist before
- **Deleted objects**: `.al` files that were removed

---

## Step 2: Map changes to documentation

### Mapping rules

| Change type | Affected documentation |
|-------------|----------------------|
| New table or table extension added | `data-model.md` at affected level |
| Table fields changed (added/removed/modified) | `data-model.md` -- update table section |
| New `TableRelation` added to a field | `data-model.md` -- update relationships |
| New enum added | `data-model.md` -- add to enums section |
| New codeunit added | `business-logic.md` at affected level |
| Codeunit procedures changed | `business-logic.md` -- update codeunit section |
| New event publisher added | `extensibility.md` -- update extension points |
| New event subscriber added | `extensibility.md` -- update extension points |
| New interface added | `extensibility.md` -- document customization surface |
| New pattern introduced | `patterns.md` |
| New subfolder with AL objects | Evaluate for new docs (use scoring) |
| `app.json` changed (dependencies, version) | App-level `CLAUDE.md` |
| AL object deleted | Check for stale references in existing docs |
| AL object renamed/moved | Update references in existing docs |

### Coverage gap check

In addition to change-driven updates, scan recursively for **existing subfolders at any depth that should have documentation but don't**. Use the scoring criteria in `skills/al-docs/references/al-scoring.md`. Any subfolder scoring MUST_DOCUMENT (7+) or SHOULD_DOCUMENT (4-6) that lacks `docs/CLAUDE.md` must be included in the update plan as a CREATE action.

### Produce an update plan

Present the update plan to the user before writing anything:

```markdown
## AL documentation update plan

### Baseline
- Comparing against: [commit/tag/date]
- AL files changed: [count]
- Subfolders affected: [list]

### Updates planned

#### App level
| File | Action | Reason |
|------|--------|--------|
| `/docs/data-model.md` | UPDATE | 2 new tables added, 1 table extended |
| `/docs/business-logic.md` | UPDATE | New posting codeunit added |

#### Subfolder: [path] (MUST_DOCUMENT)
| File | Action | Purpose |
|------|--------|---------|
| `/[path]/docs/CLAUDE.md` | CREATE | Subfolder overview and key objects |
| `/[path]/docs/[additional].md` | CREATE | See selection criteria below |

MUST_DOCUMENT subfolders always get a CLAUDE.md. Additionally, select
supplementary docs where there is genuine knowledge to capture, or a specific design that needs to be captured in documentation. The test for each:

| Supplementary doc | Add when a developer would otherwise have to **discover by reading the code** that... |
|-------------------|---|
| `data-model.md` | A non trivial data model exists, indirect linking patterns, non-obvious field purposes, or design tradeoffs a newcomer would miss |
| `business-logic.md` | Processing flows have hidden decision points, non-obvious error handling, or sequencing that only makes sense with context |
| `extensibility.md` | The subfolder has intentionally designed extensibility -- interfaces, strategy patterns, or event pairs that form a deliberate customization surface. |
| `patterns.md` | The subfolder uses patterns that differ from the app-level norms or has legacy approaches a developer might accidentally copy |

If the knowledge fits in a few bullets in CLAUDE.md's "Things to know"
section, it doesn't need its own file. A supplementary doc earns its
existence by capturing enough intent and gotchas that CLAUDE.md alone
would be insufficient.

#### New documentation needed
| File | Action | Reason |
|------|--------|--------|
| `/[path]/docs/CLAUDE.md` | CREATE | New subfolder with 8 AL objects (score: 6) |

### No update needed
- `/[path]/docs/` -- no changes detected in this area
```

Wait for user approval before proceeding.

---

## Step 3: Targeted regeneration

Launch sub-agents only for affected areas. Each agent handles one scope.

### Agent instructions

Each update agent must:

1. **Read the existing doc file** in full
2. **Read the changed `.al` files** that affect this doc
3. **Identify what sections need updating**:
   - New sections to add (for new AL objects)
   - Existing sections to revise (for changed objects)
   - References to update (for moved/renamed objects)
   - Sections to flag as potentially stale (for deleted objects)
4. **Apply updates conservatively**:
   - **ADD** new sections for new tables, codeunits, patterns, etc.
   - **EDIT** existing sections where facts changed (update specific details, not rewrite)
   - **NEVER DELETE** sections unless the corresponding AL object was deleted -- if unsure, add a `<!-- TODO: verify if still current -->` comment
   - **PRESERVE** formatting, voice, and any human-written narrative
5. **Update mermaid diagrams** when entity relationships or process flows change:
   - **data-model.md**: Add new entities to the `erDiagram`, update relationship lines if cardinalities changed, remove entities for deleted tables. If no diagram exists yet, create one.
   - **business-logic.md**: Update `flowchart` diagrams if process steps or decision points changed. Add new diagrams for newly documented processes that have meaningful branching.
6. **Add an "Updated" note** to modified sections: `*Updated: [date] -- [brief reason]*`

### For new documentation files

If the update plan includes CREATE actions (new subfolders that need docs):

1. Read the new subfolder's `.al` files
2. Generate docs using the templates from al-docs-init.md
3. Follow the same locality principle

### Parallel execution

Group updates by scope and launch sub-agents in parallel:
- One agent per affected subfolder
- One agent for app-level updates
- One agent per new subfolder group needing docs

Send all Agent tool calls in a single message.

---

## Step 4: Staleness report

After all updates complete, generate a report:

```markdown
## AL documentation update complete

### Changes applied
| File | Action | Details |
|------|--------|---------|
| `/docs/data-model.md` | UPDATED | Added Customer Ledger Entry table section |
| `/docs/business-logic.md` | UPDATED | Added posting codeunit documentation |
| `/src/Sales/docs/CLAUDE.md` | CREATED | New subfolder documentation |

### Potentially stale (needs human review)
| File | Concern |
|------|---------|
| `/docs/business-logic.md` | Codeunit "Sales-Post" was refactored -- flow description may be outdated |
| `/docs/patterns.md` | TryFunction removed from Codeunit X but pattern section still references it |

### New subfolders without documentation
| Subfolder | AL objects | Score | Recommendation |
|-----------|-----------|-------|----------------|
| `/src/Payments/` | 15 | 8 | Run `/al-docs init "src/Payments"` |

### Cross-reference issues
| File | Issue |
|------|-------|
| `/docs/data-model.md` | References `Sales Header` table which was renamed |

### Marker updated
Updated `.docs-updated` with current commit hash: [hash]
```

---

## Update the marker file

After successful completion, write/update `.docs-updated` in the target root:

```
# Documentation last updated
commit: [current HEAD commit hash]
date: [current date]
scope: [full|subfolder-path]
```

---

## Critical rules

1. **Never overwrite human content** -- add and edit, never delete unless AL object was deleted
2. **Show the plan first** -- user must approve the update plan before any writes
3. **Conservative updates** -- when in doubt, flag as "potentially stale" rather than assuming
4. **AL-aware mapping** -- map changed `.al` files to the correct doc type based on object type
5. **Update the marker** -- always write `.docs-updated` after successful completion
6. **Sentence case headers** -- no em dashes (use `--`), blank line before lists
