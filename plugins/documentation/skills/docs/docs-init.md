---
name: docs-init
description: Bootstrap documentation for an entire codebase - generates CLAUDE.md, architecture.md, and other docs at all levels
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(*)
argument-hint: "path to codebase root (defaults to current directory)"
---

# Documentation Bootstrap

> **Usage**: Invoke to generate a complete documentation hierarchy for a codebase. Performs deep codebase analysis, presents a documentation map for approval, then generates all docs using parallel sub-agents.

## Prerequisites

**MANDATORY PRE-FLIGHT - STOP and complete ALL steps before proceeding:**

- [ ] Determine the **target codebase root** - use the argument if provided, otherwise use the current working directory
- [ ] Verify the target is a valid codebase (has source files, not an empty directory)
- [ ] Enter plan mode (discovery and documentation map happen in plan mode)
- [ ] Read `.github/copilot/documentation-organization.md` from the **ai-first** repo (not the target codebase) for the rules all generated docs must follow
- [ ] Read `docs/docs-pattern.md` from the **ai-first** repo for the full pattern specification

**If any step is skipped, the output will be rejected.**

## Process Overview

```
Phase 1: Discovery (parallel sub-agents, read-only)
    ↓
Phase 2: Documentation Map (present to user for approval)
    ↓
Phase 3: Exit plan mode
    ↓
Phase 4: Generation (parallel sub-agents, write docs)
    ↓
Phase 5: Cross-referencing (final pass)
```

---

## Phase 1: Discovery

Launch **up to 3 Explore agents in parallel** using the Task tool to analyze the codebase. Each agent focuses on a different aspect. Send all Task tool calls in a single message.

### Agent 1: Structure and Stack

Prompt the agent to:

1. **Map the directory tree** (top 3 levels) to identify the project layout
2. **Identify components** - Look for top-level directories that represent distinct components:
   - Backend/API: `backend/`, `server/`, `api/`, `src/api/`, `app/`
   - Frontend/UI: `frontend/`, `client/`, `web/`, `src/app/`, `src/pages/`
   - Database: `database/`, `db/`, `migrations/`, `prisma/`, `schema/`
   - Infrastructure: `infra/`, `infrastructure/`, `deploy/`, `terraform/`, `.github/workflows/`
   - Shared/Common: `shared/`, `common/`, `lib/`, `packages/`, `core/`
   - Scripts: `scripts/`, `tools/`, `bin/`
3. **Detect tech stack** from manifest files:
   - JavaScript/TypeScript: `package.json`, `tsconfig.json`, `next.config.*`, `vite.config.*`
   - Python: `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile`
   - .NET: `*.csproj`, `*.sln`, `Directory.Build.props`, `global.json`
   - Go: `go.mod`, `go.sum`
   - Rust: `Cargo.toml`
   - Java/Kotlin: `pom.xml`, `build.gradle`, `build.gradle.kts`
   - Docker: `Dockerfile`, `docker-compose.yml`
   - Other: `Makefile`, `CMakeLists.txt`, `Gemfile`
4. **Identify entry points**: `main.*`, `index.*`, `app.*`, `Program.*`, `Startup.*`
5. **Detect project type**: monorepo, single-app, microservices, library, CLI tool
6. **Catalog existing documentation**: Find README.md, CLAUDE.md, docs/, wiki/, *.md files that already exist

### Agent 2: Architecture and Patterns

Prompt the agent to:

1. **Read key source files** (not just listings) to identify architectural patterns:
   - MVC, MVVM, Clean Architecture, Hexagonal, Event-Driven, CQRS, Microservices
   - Look at directory structure, naming conventions, file organization
2. **Identify data models and schemas**:
   - Database schemas (SQL files, ORM models, Prisma schema, migrations)
   - API contracts (OpenAPI/Swagger, GraphQL schemas, protobuf)
   - TypeScript interfaces/types, Python dataclasses, C# records
3. **Map component dependencies**:
   - How do components communicate? (REST APIs, message queues, shared libraries, imports)
   - Which components depend on which?
4. **Identify shared patterns**:
   - Error handling patterns
   - Authentication/authorization approach
   - Logging and monitoring
   - Configuration management
   - Testing patterns (unit, integration, e2e)
5. **Read existing documentation** found by Agent 1 and summarize what's already documented vs what's missing

### Agent 3: Module Inventory

Prompt the agent to:

1. **Walk the directory tree at all levels** and identify significant modules:
   - Directories with 5+ source files
   - Directories with their own configuration files
   - Directories that represent a distinct service, feature, or bounded context
2. **Score each module by documentation need** (higher = more needed):
   - File count (more files = harder to understand)
   - Dependency count (imports from/exports to other modules)
   - Nesting depth (deeper = less discoverable)
   - Complexity indicators (large files, many conditionals, error handling)
   - Business logic presence (domain-specific code vs boilerplate)
3. **Categorize modules**:
   - `MUST_DOCUMENT`: High complexity, many dependencies, business logic (score >= 7)
   - `SHOULD_DOCUMENT`: Moderate complexity, some dependencies (score 4-6)
   - `OPTIONAL`: Low complexity, few dependencies, mostly boilerplate (score 1-3)
4. **Note existing module-level docs** - README.md, inline comments, JSDoc/docstrings that could inform generated docs
5. **Identify migration opportunities** - existing docs in non-standard locations that should move to the flat-file pattern

---

## Phase 2: Documentation Map

After all discovery agents complete, synthesize their findings into a **Documentation Map** that lists every file to create or update.

**IMPORTANT**: The documentation map MUST include entries for ALL modules categorized as `MUST_DOCUMENT` (score >= 7) and `SHOULD_DOCUMENT` (score 4-6) by Agent 3. Only `OPTIONAL` modules (score 1-3) may be excluded. Do not selectively omit modules to reduce scope -- if discovery scored a module as MUST or SHOULD, it gets documented.

### File selection by category

| Category | CLAUDE.md | Additional files |
|----------|-----------|-----------------|
| MUST_DOCUMENT (>= 7) | Required | At least one additional file based on discovery findings (see below) |
| SHOULD_DOCUMENT (4-6) | Required | None -- CLAUDE.md alone is sufficient |
| OPTIONAL (1-3) | Skip | Skip |

**Additional files for MUST_DOCUMENT modules** -- select from the standard categories defined in `.github/copilot/documentation-organization.md`. Choose files based on what discovery found in the module (e.g., `architecture.md` for design decisions, `implementation.md` for integration patterns, `setup.md` for configuration, `testing.md` for test infrastructure, etc.).

MUST_DOCUMENT modules must never be documented with only a CLAUDE.md. If none of the standard categories clearly apply, default to `architecture.md`.

### Format

Present the documentation map to the user as a markdown table:

```markdown
## Documentation Map

### Discovery Summary
- **Project type**: [monorepo/single-app/microservices/etc.]
- **Tech stack**: [languages, frameworks, databases]
- **Components found**: [list]
- **Significant modules found**: [count by category]
- **Existing docs found**: [count, locations]

### Files to Generate

#### Project Level
| File | Action | Purpose |
|------|--------|---------|
| `/CLAUDE.md` | CREATE | Root project overview and orientation |
| `/docs/architecture.md` | CREATE | System-wide architecture and design decisions |
| `/docs/setup.md` | CREATE | Getting started, environment setup |
| `/docs/features.md` | CREATE | Feature inventory (if applicable) |

#### Component: [name]
| File | Action | Purpose |
|------|--------|---------|
| `/backend/docs/CLAUDE.md` | CREATE | Backend overview |
| `/backend/docs/architecture.md` | CREATE | Backend architecture, API design, data model |
| `/backend/docs/implementation.md` | CREATE | Backend patterns and guides |
| `/backend/docs/setup.md` | CREATE | Backend environment setup |

#### Module: [path] (MUST_DOCUMENT)
| File | Action | Purpose |
|------|--------|---------|
| `/backend/src/services/auth/docs/CLAUDE.md` | CREATE | Auth service overview |
| `/backend/src/services/auth/docs/architecture.md` | CREATE | Auth patterns and flow |

### Existing Docs to Migrate
| Current Location | Target Location | Action |
|------------------|-----------------|--------|
| `/backend/README.md` | `/backend/docs/CLAUDE.md` | MIGRATE content |
| `/docs/API.md` | `/backend/docs/implementation.md` | MIGRATE content |
```

### User Approval

After presenting the map, ask the user:

1. "Does this documentation map look correct? Would you like to add or remove any entries?"
2. Wait for confirmation before proceeding
3. If the user modifies the map, update it accordingly

---

## Phase 3: Exit Plan Mode

Once the documentation map is approved, exit plan mode so that files can be written.

---

## Phase 4: Generation

Generate all documentation files using **parallel sub-agents grouped by scope**. Launch all agents in a single message for maximum parallelism.

### Sub-agent Strategy

**Agent A - Project Level**: Generates `/CLAUDE.md` and all `/docs/*.md` files.

**Agents B, C, D... - Component Level** (one per component): Each generates all files for its component (`/[component]/docs/*.md`).

**Agents E, F, G... - Module Level** (one per module group): Each generates docs for a cluster of related modules. Group nearby modules to reduce agent count (e.g., one agent handles all modules under `/backend/src/services/`).

### What Each Agent Receives

Every generation agent must receive in its prompt:

1. **The documentation map entries** for its scope (which files to create)
2. **Discovery findings** relevant to its scope (from Phase 1)
3. **The documentation rules** (summarized from documentation-organization.md):
   - AI creates flat files only in docs/ (user-created subdirectories are OK and should be used when present)
   - CLAUDE.md not README.md
   - One file per category
   - Only create files that provide value
4. **The templates** (below) for each doc type
5. **Existing documentation content** to preserve or migrate
6. **Cross-reference instructions**: how to reference docs at other levels

### Templates

Each agent uses these templates, populated with real analysis from discovery.

#### CLAUDE.md (any level)

```markdown
# [Name]

[1-2 sentence description of what this is and its role in the system.]

## Quick reference

- **Tech stack**: [languages, frameworks, key libraries]
- **Entry point(s)**: [main files with relative paths]
- **Key patterns**: [architectural patterns in use]

## Structure

[Brief overview of directory layout with purpose of key directories/files]
[Use a simple list, not a full tree - highlight what matters]

## Documentation

[List only docs that exist at this level]
- [docs/architecture.md](docs/architecture.md) - Design decisions and patterns
- [docs/implementation.md](docs/implementation.md) - Implementation guides and patterns
- [docs/setup.md](docs/setup.md) - Environment setup and configuration
- [docs/testing.md](docs/testing.md) - Testing approach and guides

## Key concepts

[3-7 bullet points about the most important things to understand when working here]
- [Concept 1]: [Brief explanation]
- [Concept 2]: [Brief explanation]
```

#### architecture.md (any level)

```markdown
# [Scope] architecture

## Overview

[High-level description of the architecture at this level. What are the major pieces and how do they fit together?]

## Key design decisions

[Numbered list of significant architectural decisions with rationale]

1. **[Decision]**: [What was chosen and why]
2. **[Decision]**: [What was chosen and why]

## Component relationships

[How the parts at this level interact - data flow, dependencies, communication patterns]
[Include a simple diagram if relationships are complex]

## Data model

[If applicable - key entities, schemas, contracts, relationships]
[Reference specific schema/model files by path]

## Patterns in use

[Architectural and design patterns with brief descriptions and file path examples]

- **[Pattern name]**: [How it's used here] (see `path/to/example.file`)
```

#### implementation.md (any level)

```markdown
# [Scope] implementation guide

## Overview

[What this guide covers and who it's for]

## Key patterns

[Patterns developers should follow when working in this area]

### [Pattern 1 name]

[Description with code examples or file references]

### [Pattern 2 name]

[Description with code examples or file references]

## Integration points

[How this component/module connects to others]

## Common tasks

[Step-by-step guides for frequent development tasks in this area]
```

#### setup.md (any level)

```markdown
# [Scope] setup

## Prerequisites

[What needs to be installed/configured before starting]

## Getting started

[Step-by-step setup instructions]

## Configuration

[Environment variables, config files, and their purposes]

## Development workflow

[How to run, test, and debug locally]
```

### Generation Rules

1. **Content must be based on actual code analysis** - Never make up or assume. If discovery didn't find something, don't document it.
2. **Reference specific files** - Include paths to key files mentioned in docs (e.g., "see `src/models/User.ts` for the user schema")
3. **Keep it concise** - Each doc should be scannable. Prefer bullet lists over paragraphs.
4. **Match existing voice** - If existing docs exist, match their tone and level of detail.
5. **Only create files that provide value** - For SHOULD_DOCUMENT modules, CLAUDE.md alone is sufficient. For MUST_DOCUMENT modules, always create at least one additional file from the standard categories (see `.github/copilot/documentation-organization.md`) alongside CLAUDE.md based on what discovery found. CLAUDE.md should be a concise overview with links to the deeper files.
6. **Follow markdown rules** - No em dashes (use `--`), blank line before lists, sentence case headers, language on code blocks.

---

## Phase 5: Cross-referencing

After all generation agents complete, do a final pass:

1. **Verify CLAUDE.md references** - Each CLAUDE.md should list only docs that actually exist at its level
2. **Add cross-level references** - Project-level architecture.md should reference component docs for details; component docs should reference project docs for context
3. **Check for orphans** - No references to files that don't exist
4. **Verify flat file compliance** - AI-generated files are flat `.md` files in `docs/`, not in new subdirectories (user-created subdirectories are OK)

---

## Output

After completion, present a summary to the user:

```markdown
## Documentation Bootstrap Complete

### Files Created
- [count] files across [count] directories

### By Level
- Project: [list of files]
- Component [name]: [list of files]
- Module [path]: [list of files]

### Migrated Content
- [old location] --> [new location]

### Next Steps
- Run `/docs audit` to verify coverage
- Run `/docs update` after making code changes to keep docs current
- Use `/prd design` to leverage these docs when planning new features
```

---

## Critical Rules

1. **Plan mode for discovery** - Phases 1-2 must happen in plan mode (read-only exploration)
2. **User approves the map** - Never write docs without the user approving the documentation map
3. **Flat files only** - AI processes never create subdirectories inside `docs/` (user-created subdirectories are OK and should be used when present)
4. **CLAUDE.md not README.md** - Follow the ai-first documentation standard
5. **Preserve existing content** - If docs already exist, incorporate their content rather than overwriting
6. **Complete coverage of scored modules** - ALL modules scored MUST_DOCUMENT or SHOULD_DOCUMENT must have documentation generated. OPTIONAL modules may be skipped. MUST_DOCUMENT modules (score >= 7) MUST receive CLAUDE.md plus at least one additional file chosen based on discovery (see "File selection by category" in Phase 2). For SHOULD_DOCUMENT modules (score 4-6), a CLAUDE.md alone is sufficient.
7. **Based on real analysis** - Every statement in generated docs must trace back to actual code read during discovery
