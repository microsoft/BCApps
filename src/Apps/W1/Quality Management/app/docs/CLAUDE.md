# Quality Management - Docs Index

Project-wide documentation for the Quality Management app.

## Files in This Directory

| File | Contents |
|---|---|
| `architecture.md` | System architecture, layer breakdown, design patterns, component relationships |
| `data-model.md` | All tables, table extensions, enums, and their relationships |
| `conventions.md` | AL naming conventions, namespace mapping, code patterns to follow |
| `features.md` | Product features overview — what users can do and which objects implement each feature |
| `testing.md` | Testing setup, test project structure, how to run tests, patterns for new tests |

## Component Documentation

Each major source module has its own `docs/` folder:

| Module | Docs location | What it covers |
|---|---|---|
| Inspection Document | `src/Document/docs/` | Header/Line tables, creation codeunit, status lifecycle |
| Configuration | `src/Configuration/docs/` | Templates, generation rules, source config, result conditions |
| Integration | `src/Integration/docs/` | BC module hooks (Purchasing, Manufacturing, Assembly, Warehouse, Transfers) |
| Dispositions | `src/Dispositions/docs/` | Post-inspection inventory actions, interface pattern |

## Quick Answers

**Where is the inspection creation entry point?**
`src/Document/QltyInspectionCreate.Codeunit.al` — `CreateInspectionWithVariant()`

**Where are generation rules evaluated?**
`src/Configuration/GenerationRule/QltyInspecGenRuleMgmt.Codeunit.al`

**Where is the app setup (number series, defaults)?**
`src/Setup/QltyManagementSetup.Table.al` + `QltyManagementSetup.Page.al`

**How do I add a new integration trigger?**
See `src/Integration/docs/architecture.md`

**How do I add a new disposition action?**
See `src/Dispositions/docs/architecture.md`
