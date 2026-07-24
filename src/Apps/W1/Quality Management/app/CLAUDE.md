# Quality Management App - AI Context

## Overview

Microsoft Business Central extension (v29.0.0.0) that integrates quality inspection routines, test plans, and quality specifications into production, inventory, and purchasing workflows.

- **Publisher:** Microsoft
- **App ID:** bc7b3891-f61b-4883-bbb3-384cdef88bec
- **Object ID Range:** 20400-20600
- **Namespace root:** `Microsoft.QualityManagement.*`
- **No external dependencies** (platform + application base only)

## Quick Navigation

| What you need | Where to look |
|---|---|
| Architecture overview | `docs/architecture.md` |
| Data model (tables) | `docs/data-model.md` |
| AL coding conventions | `docs/conventions.md` |
| Product features | `docs/features.md` |
| Testing strategy | `docs/testing.md` |
| Inspection document logic | `src/Document/docs/` |
| Templates & generation rules | `src/Configuration/docs/` |
| BC module integration | `src/Integration/docs/` |
| Disposition actions | `src/Dispositions/docs/` |

## Source Structure

```
src/
├── AccessControl/       # Permission management codeunit
├── API/                 # REST API pages for inspection creation/query
├── Configuration/       # Templates, generation rules, results, source config
│   ├── GenerationRule/  # When to trigger inspections (rules + scheduling)
│   ├── Result/          # Result conditions and evaluation logic
│   ├── SourceConfiguration/ # Table-to-inspection field mapping
│   └── Template/        # Inspection templates and test definitions
├── Dispositions/        # Post-inspection actions (transfer, put-away, adjust, etc.)
├── Document/            # Core inspection document (header + lines)
├── Installation/        # Install codeunit and upgrade logic
├── Integration/         # Hooks into Assembly, Manufacturing, Purchasing, Transfers, Warehouse
├── Permissions/         # Permission sets
├── Reports/             # Certificate of Analysis, Non-Conformance, General Purpose
├── RoleCenters/         # Quality Manager role center and cues
├── Setup/               # QltyManagementSetup + guided/manual setup pages
├── Utilities/           # Parsing, expressions, notifications, helpers
└── Workflow/            # Approval workflow setup and responses
```

## Core Workflow

```
Generation Rule (trigger condition)
    → matches source record
    → QltyInspectionCreate codeunit
    → Inspection Header + Lines (from Template)
    → Inspector fills in results
    → Finish inspection
    → Disposition action (optional post-processing)
```

## Context Loading Instructions

When working in a specific area, read the corresponding component docs **before** making changes:

| Working in... | Read first |
|---|---|
| `src/Document/` | `src/Document/docs/CLAUDE.md` + `src/Document/docs/architecture.md` |
| `src/Configuration/` | `src/Configuration/docs/CLAUDE.md` + `src/Configuration/docs/architecture.md` |
| `src/Integration/` | `src/Integration/docs/CLAUDE.md` |
| `src/Dispositions/` | `src/Dispositions/docs/CLAUDE.md` |
| Any area | `docs/architecture.md` + `docs/conventions.md` |

Always read `docs/data-model.md` when modifying or adding tables.

## Development Environment

- **CountryCode:** W1 (world-wide)
- **Symbol packages:** `Run/W1/AllExtensions/`
- **Build & publish:** See `Eng/Docs/al-workflow.md`
- **Run tests:** `Eng/Core/Scripts/RunALTestFromEnlistment.ps1`
- **Test app:** `src/Apps/W1/Quality Management/test/`
- **Test library:** `src/Apps/W1/Quality Management/Test Library/`
