# Documentation plugin

Codebase documentation generator that bootstraps, updates, and audits hierarchical docs for any codebase. Follows the flat-file documentation pattern defined in `docs/docs-pattern.md` and `.github/copilot/documentation-organization.md`, producing CLAUDE.md orientation files and category-specific docs at project, component, and module levels.

**Version:** 1.2.0

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| Docs | `/docs` | Bootstrap, update, or audit codebase documentation |

The `/docs` skill has three modes, each invokable independently.

## Usage

```
/docs                        # Bootstrap docs (same as /docs init)
/docs init                   # Bootstrap documentation for entire codebase
/docs init "path/to/repo"    # Bootstrap docs for a specific path
/docs update                 # Incrementally refresh docs based on changes
/docs audit                  # Read-only gap analysis without writing files
```

## Modes

### 1. Init (`/docs init`)

**File:** `skills/docs/docs-init.md`

Bootstraps a complete documentation hierarchy for a codebase through five phases.

**Phases:**

1. **Discovery** -- launches up to 3 parallel sub-agents to analyze the codebase:
   - Agent 1: structure, components, tech stack, entry points, project type
   - Agent 2: architecture, data models, dependencies, shared patterns
   - Agent 3: module inventory with documentation-need scoring (MUST/SHOULD/OPTIONAL)
2. **Documentation map** -- synthesizes discovery into a table of every file to create or migrate, then presents it for user approval
3. **Exit plan mode** -- unlocks write access after the map is approved
4. **Generation** -- launches parallel sub-agents grouped by scope (project, component, module) to write all docs
5. **Cross-referencing** -- verifies CLAUDE.md links, adds cross-level references, checks for orphans

**Generated file types:**

| File | Purpose |
|------|---------|
| CLAUDE.md | Orientation and quick reference (replaces README.md) |
| architecture.md | Design decisions, component relationships, data model, patterns |
| implementation.md | Key patterns, integration points, common tasks |
| setup.md | Prerequisites, getting started, configuration, dev workflow |
| testing.md | Testing approach and guides |

**Documentation levels:**

| Level | Location | Files |
|-------|----------|-------|
| Project | `/CLAUDE.md`, `/docs/` | architecture.md, setup.md, features.md, CLAUDE.md |
| Component | `/[component]/docs/` | architecture.md, implementation.md, setup.md, CLAUDE.md |
| Module | `/[path-to-module]/docs/` | CLAUDE.md, plus additional files for high-complexity modules |

**Module scoring:**

Modules are scored 0-10 based on file count, subdirectories, config files, cross-module imports, business logic presence, and large files:

- **MUST_DOCUMENT (7+):** CLAUDE.md plus at least one additional file
- **SHOULD_DOCUMENT (4-6):** CLAUDE.md only
- **OPTIONAL (1-3):** Skipped

---

### 2. Update (`/docs update`)

**File:** `skills/docs/docs-update.md`

Incrementally refreshes existing documentation based on what changed since the last update.

**Steps:**

1. **Detect changes** -- determines a baseline (user-provided commit, `.docs-updated` marker, or git log) and runs `git diff` to get changed files
2. **Map changes to documentation** -- categorizes changes by scope and determines which doc files need updating:
   - New dependencies - setup.md
   - New API endpoints - architecture.md, implementation.md
   - Schema/model changes - architecture.md
   - New directories - evaluate for new docs
   - Deleted/moved files - check for broken references
   - Also performs a coverage gap check for undocumented modules
3. **Targeted regeneration** -- presents an update plan for approval, then launches parallel sub-agents for affected areas only
4. **Staleness report** -- summarizes changes applied, flags potentially stale docs, lists cross-reference issues

**Update rules:**

- **Add** new sections for new functionality
- **Edit** existing sections where facts changed
- **Never delete** sections unless corresponding code was deleted
- **Preserve** formatting, voice, and human-written narrative
- **Flag as stale** when unsure rather than making assumptions
- Writes a `.docs-updated` marker file after successful completion

---

### 3. Audit (`/docs audit`)

**File:** `skills/docs/docs-audit.md`

Read-only gap analysis that reports documentation coverage without writing any files.

**What it does:**

- Launches 4 parallel subagents to analyze structure, inventory existing docs, score modules, and find migration opportunities
- Compares expected documentation (based on codebase structure and module scoring) against what actually exists
- Categorizes each expected file as EXISTS, MISSING, STALE, or NON-STANDARD

**Report includes:**

- Coverage percentage across all levels
- Project-level, component-level, and module-level file status tables
- Modules requiring documentation (scored MUST and SHOULD)
- Migration opportunities (e.g., README.md to CLAUDE.md, files in non-standard locations)
- Non-standard documentation patterns
- Prioritized recommendations (quick wins, high impact, next steps)

**This skill is strictly read-only** -- it does not create or modify any files.

## File locations

| Artifact | Path |
|----------|------|
| Project orientation | `/CLAUDE.md` |
| Project-level docs | `/docs/*.md` |
| Component docs | `/[component]/docs/*.md` |
| Module docs | `/[path-to-module]/docs/*.md` |
| Update marker | `/.docs-updated` |

## Plugin structure

```
documentation/
├── .claude-plugin/
│   └── plugin.json
├── README.md
└── skills/
    └── docs/
        ├── SKILL.md          # Router - dispatches to the correct mode
        ├── docs-init.md      # Mode 1: full bootstrap
        ├── docs-update.md    # Mode 2: incremental update
        └── docs-audit.md     # Mode 3: read-only audit
```

## Key rules

1. **Always read the mode file** -- do not run a mode from memory
2. **Follow documentation-organization.md** -- flat files only, CLAUDE.md not README.md, one file per category
3. **User approves before writing** -- present the documentation map (init) or update plan (update) for approval first
4. **Preserve existing content** -- when updating, add and edit sections; never delete human-written content
5. **Only create files that provide value** -- not every directory needs all doc types
6. **Based on real analysis** -- every statement in generated docs must trace back to actual code read during discovery
