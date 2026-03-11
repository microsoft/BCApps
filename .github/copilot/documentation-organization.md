# Documentation organization rules

## Core rules

1. **AI creates flat files only** - AI/PRD processes create `.md` files directly in `docs/`, one per category. Users may freely add subdirectories to organize content. AI processes should respect and use existing subdirectories when present.
2. **CLAUDE.md for orientation** - Use `CLAUDE.md` (not README.md) for overview and pointers at any level.
3. **Append, don't duplicate** - When adding content, append to the appropriate existing file with a clear heading.
4. **Primary purpose wins** - Mixed-purpose content goes in the file matching its primary purpose.
5. **Full path references** - When referencing docs in code/comments, use the full path (e.g., `docs/architecture.md`).

## Standard categories

| File | Purpose |
|------|---------|
| `architecture.md` | Design decisions, schema, system design |
| `implementation.md` | Implementation plans, integration guides, migration guides |
| `setup.md` | Installation, environment setup, configuration |
| `testing.md` | Testing guides, test environment docs |
| `deployment.md` | CI/CD, hosting, production setup |
| `features.md` | Feature documentation and analysis |
| `tasks.md` | Task completion summaries |
| `troubleshooting.md` | Bug fixes, debugging notes, error resolution |
| `research.md` | Industry research, comparison studies |
| `onboarding.md` | Team onboarding materials |
| `misc.md` | Anything that doesn't fit other categories |
| `CLAUDE.md` | Overview and pointers (replaces README.md) |

Not every directory needs all files. Create only what's needed.

## Universal pattern

One example - this same pattern applies to **all components** (frontend, database, scripts, infrastructure) and at **all levels** of the hierarchy:

```
backend/docs/
├── architecture.md        # Backend MVC details, data model, API design
├── implementation.md      # Migrations, third-party integrations
├── setup.md               # Environment config, local dev setup
├── testing.md             # Backend test suite documentation
└── CLAUDE.md              # Backend overview, pointers to other files
```

## Documentation levels

Documentation can exist at **any level** where it provides value:

| Level | Location | Scope | Example |
|-------|----------|-------|---------|
| Project-wide | `/docs/` | Entire system, cross-component -HIGH LEVEL ONLY! | System architecture, project setup |
| Component | `/[component]/docs/` | Single technical component | Backend API design, frontend state management |
| Module | `/[path-to-module]/docs/` | Specific module, service, or package | Auth service patterns, calendar component internals |

### Where to place docs

- **Cross-component or system-wide?** --> `/docs/[category].md`
- **Specific to one component?** --> `/[component]/docs/[category].md`
- **Specific to a module within a component?** --> `/[path-to-module]/docs/[category].md`

### Component vs project-wide

Content about the **entire system** or **multiple components** belongs in `/docs/`. Content about a **single component's internals** belongs in that component's `docs/`.

| Documentation | Location | Why |
|---------------|----------|-----|
| System architecture overview | `/docs/architecture.md` | Cross-component |
| Backend MVC architecture | `/backend/docs/architecture.md` | Backend-specific |
| Auth service patterns | `/backend/src/services/docs/implementation.md` | Module-specific |
| Calendar feature design | `/docs/features.md` | Product feature (cross-component) |
| Calendar component internals | `/frontend/src/components/calendar/docs/CLAUDE.md` | Module-specific |

### When to create module-level docs

Create docs at the module level when:

- Complex modules need explanation beyond code comments
- Services have specific usage patterns or business logic
- Shared utilities need usage documentation
- Components have non-obvious design decisions

## CLAUDE.md usage

Any directory with code **should** have a `CLAUDE.md` when it needs explanation:

- Provide quick orientation for developers and AI agents
- Link to detailed documentation in `[current-location]/docs/` if it exists
- Include important context, constraints, and pointers
- Include quick start commands or usage examples
- Do NOT duplicate higher-level documentation

## Enforcement

1. **AI processes NEVER create** subdirectories inside `docs/` - always create flat `.md` files. Users may add subdirectories freely, and AI processes should use them when they exist.
2. **NEVER** use README.md - use CLAUDE.md instead
3. **ALWAYS** create flat `.md` files (one per category) when generating documentation
4. **DO NOT** duplicate documentation across levels - each level has its purpose
5. If you create a doc in the wrong location, immediately inform the user and move it

---

**Last Updated:** February 19, 2026 by gregrata
