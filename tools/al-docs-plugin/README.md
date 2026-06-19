# AL Docs plugin

AL codebase documentation generator that bootstraps, updates, and audits hierarchical docs for Business Central AL apps. Produces CLAUDE.md orientation files and AL-specific docs (data-model.md, business-logic.md, patterns.md) at app and subfolder levels.

**Version:** 0.1.0

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| AL Docs | `/al-docs` | Bootstrap, update, or audit AL codebase documentation |

## Usage

```
/al-docs                        # Bootstrap docs (same as /al-docs init)
/al-docs init                   # Bootstrap documentation for AL app or folder
/al-docs init "path/to/app"     # Bootstrap docs for a specific path
/al-docs update                 # Incrementally refresh docs based on changes
/al-docs audit                  # Read-only gap analysis without writing files
```

## Modes

### 1. Init (`/al-docs init`)

Bootstraps a complete documentation hierarchy through five phases:

1. **Discovery** -- launches 3 parallel sub-agents to analyze the AL codebase:
   - Agent 1: app structure, `app.json` metadata, object inventory by type and subfolder
   - Agent 2: data model -- tables, relationships, enums, keys, conceptual model
   - Agent 3: business logic, patterns, event architecture, subfolder scoring
2. **Documentation map** -- presents every file to create for user approval
3. **Exit plan mode** -- unlocks write access
4. **Generation** -- parallel sub-agents write docs grouped by scope
5. **Cross-referencing** -- verifies links and consistency

### 2. Update (`/al-docs update`)

Incrementally refreshes docs based on git changes:

1. **Detect changes** -- determines baseline and gets changed `.al` files
2. **Map changes** -- maps AL object types to affected doc files (table changes -> data-model.md, codeunit changes -> business-logic.md, etc.)
3. **Targeted regeneration** -- presents update plan for approval, then updates affected docs only
4. **Staleness report** -- summarizes changes and flags potentially stale sections

### 3. Audit (`/al-docs audit`)

Read-only gap analysis:

- Launches 3 parallel subagents to inventory objects, existing docs, and score subfolders
- Compares expected documentation against what exists
- Reports coverage percentage, missing files, and non-standard patterns
- Provides prioritized recommendations

## Generated doc types

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Orientation: app purpose, dependencies, structure, key objects |
| `data-model.md` | What the app models, table relationships, key fields, enums |
| `business-logic.md` | Processing flows, decision points, error handling, key operations |
| `patterns.md` | Locally applied patterns (IsHandled, TryFunction, etc.) |

## Documentation levels

| Level | Location | Content |
|-------|----------|---------|
| App (has `app.json`) | `/CLAUDE.md`, `/docs/` | App-wide overview, full data model, cross-cutting logic |
| Subfolder (score 7+) | `/[subfolder]/docs/` | CLAUDE.md + at least one additional doc |
| Subfolder (score 4-6) | `/[subfolder]/docs/` | CLAUDE.md only |

## Subfolder scoring

Subfolders are scored 0-10 based on AL object count, table count, codeunit count, event presence, and extension objects:

- **MUST_DOCUMENT (7+)**: CLAUDE.md plus at least one additional file
- **SHOULD_DOCUMENT (4-6)**: CLAUDE.md only
- **OPTIONAL (1-3)**: Skipped

## Plugin structure

```
al-docs-plugin/
├── .claude-plugin/
│   └── plugin.json
├── README.md
└── skills/
    └── al-docs/
        ├── SKILL.md              # Router -- dispatches to the correct mode
        ├── al-docs-init.md       # Mode 1: full bootstrap
        ├── al-docs-update.md     # Mode 2: incremental update
        └── al-docs-audit.md      # Mode 3: read-only audit
```
